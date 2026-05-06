# == Schema Information
#
# Table name: personal_access_tokens
#
#  id           :integer          not null, primary key
#  last_used_at :datetime
#  name         :string           not null
#  revoked_at   :datetime
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer          not null
#
require "test_helper"

class PersonalAccessTokenTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "generates a plaintext token on create and stores only its digest" do
    pat = @user.personal_access_tokens.create!(name: "Claude Desktop")

    assert pat.token.present?
    assert pat.token.start_with?("wwp_")
    assert_equal Digest::SHA256.hexdigest(pat.token), pat.token_digest
    assert_not_equal pat.token, pat.token_digest
  end

  test "the plaintext token is only available on the instance that created it" do
    pat = @user.personal_access_tokens.create!(name: "Claude Desktop")
    reloaded = PersonalAccessToken.find(pat.id)

    assert_nil reloaded.token
  end

  test "tokens are unique even if the same name is used" do
    a = @user.personal_access_tokens.create!(name: "dupe")
    b = @user.personal_access_tokens.create!(name: "dupe")

    assert_not_equal a.token, b.token
    assert_not_equal a.token_digest, b.token_digest
  end

  test "validates presence of name" do
    pat = @user.personal_access_tokens.build

    assert_not pat.valid?
    assert_includes pat.errors[:name], "can't be blank"
  end

  test ".authenticate returns the token record for a valid raw token" do
    pat = @user.personal_access_tokens.create!(name: "claude")

    assert_equal pat, PersonalAccessToken.authenticate(pat.token)
  end

  test ".authenticate returns nil for an unknown token" do
    assert_nil PersonalAccessToken.authenticate("wwp_unknown")
  end

  test ".authenticate returns nil for a blank token" do
    assert_nil PersonalAccessToken.authenticate(nil)
    assert_nil PersonalAccessToken.authenticate("")
  end

  test ".authenticate returns nil for a revoked token" do
    pat = @user.personal_access_tokens.create!(name: "claude")
    raw = pat.token
    pat.revoke!

    assert_nil PersonalAccessToken.authenticate(raw)
  end

  test "revoke! sets revoked_at" do
    freeze_time do
      pat = @user.personal_access_tokens.create!(name: "claude")
      pat.revoke!

      assert_equal Time.current, pat.revoked_at
      assert pat.revoked?
    end
  end

  test "revoke! is idempotent" do
    pat = @user.personal_access_tokens.create!(name: "claude")
    pat.revoke!
    first_revoked_at = pat.revoked_at

    travel 1.minute do
      pat.revoke!
      assert_equal first_revoked_at, pat.reload.revoked_at
    end
  end

  test "touch_last_used! updates last_used_at without changing updated_at" do
    pat = @user.personal_access_tokens.create!(name: "claude")
    original_updated_at = pat.updated_at

    travel 1.minute do
      pat.touch_last_used!
    end

    pat.reload
    assert_not_nil pat.last_used_at
    assert_equal original_updated_at.to_i, pat.updated_at.to_i
  end

  test "active scope excludes revoked tokens" do
    active = @user.personal_access_tokens.create!(name: "active")
    revoked = @user.personal_access_tokens.create!(name: "revoked")
    revoked.revoke!

    assert_includes PersonalAccessToken.active, active
    assert_not_includes PersonalAccessToken.active, revoked
  end

  test "destroying the user destroys their tokens" do
    @user.personal_access_tokens.create!(name: "claude")
    user_token_count = @user.personal_access_tokens.count

    assert_difference -> { PersonalAccessToken.count }, -user_token_count do
      @user.destroy
    end
  end
end
