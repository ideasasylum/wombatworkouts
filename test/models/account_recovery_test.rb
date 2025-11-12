require "test_helper"

class AccountRecoveryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "generates 6-digit code on create" do
    recovery = @user.account_recoveries.create!

    assert_not_nil recovery.code
    assert_equal 6, recovery.code.length
    assert_match(/\A\d{6}\z/, recovery.code)
  end

  test "sets expiration to 15 minutes from now" do
    freeze_time do
      recovery = @user.account_recoveries.create!

      assert_in_delta 15.minutes.from_now, recovery.expires_at, 1.second
    end
  end

  test "validates presence of code" do
    recovery = AccountRecovery.new(user: @user, expires_at: 15.minutes.from_now)
    # Skip the before_validation callback that generates code
    recovery.define_singleton_method(:generate_code) {}
    recovery.code = nil

    assert_not recovery.valid?
    assert_includes recovery.errors[:code], "can't be blank"
  end

  test "validates uniqueness of code" do
    code = "123456"
    @user.account_recoveries.create!(code: code, expires_at: 15.minutes.from_now)

    duplicate = AccountRecovery.new(user: @user, code: code, expires_at: 15.minutes.from_now)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "active? returns true when not expired and not used" do
    recovery = @user.account_recoveries.create!

    assert recovery.active?
  end

  test "active? returns false when expired" do
    recovery = @user.account_recoveries.create!(expires_at: 1.hour.ago)

    assert_not recovery.active?
  end

  test "active? returns false when used" do
    recovery = @user.account_recoveries.create!
    recovery.mark_as_used!

    assert_not recovery.active?
  end

  test "expired? returns true when past expiration" do
    recovery = @user.account_recoveries.create!(expires_at: 1.hour.ago)

    assert recovery.expired?
  end

  test "expired? returns false when before expiration" do
    recovery = @user.account_recoveries.create!

    assert_not recovery.expired?
  end

  test "used? returns true when used_at is set" do
    recovery = @user.account_recoveries.create!
    recovery.mark_as_used!

    assert recovery.used?
  end

  test "used? returns false when used_at is nil" do
    recovery = @user.account_recoveries.create!

    assert_not recovery.used?
  end

  test "mark_as_used! sets used_at to current time" do
    freeze_time do
      recovery = @user.account_recoveries.create!
      recovery.mark_as_used!

      assert_equal Time.current, recovery.used_at
    end
  end

  test "active scope returns only active recoveries" do
    active = @user.account_recoveries.create!
    expired = @user.account_recoveries.create!(expires_at: 1.hour.ago)
    used = @user.account_recoveries.create!
    used.mark_as_used!

    active_recoveries = AccountRecovery.active

    assert_includes active_recoveries, active
    assert_not_includes active_recoveries, expired
    assert_not_includes active_recoveries, used
  end

  test "expired scope returns only expired recoveries" do
    active = @user.account_recoveries.create!
    expired = @user.account_recoveries.create!(expires_at: 1.hour.ago)

    expired_recoveries = AccountRecovery.expired

    assert_includes expired_recoveries, expired
    assert_not_includes expired_recoveries, active
  end

  test "used scope returns only used recoveries" do
    active = @user.account_recoveries.create!
    used = @user.account_recoveries.create!
    used.mark_as_used!

    used_recoveries = AccountRecovery.used

    assert_includes used_recoveries, used
    assert_not_includes used_recoveries, active
  end
end
