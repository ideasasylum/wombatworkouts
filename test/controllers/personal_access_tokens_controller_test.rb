require "test_helper"

class PersonalAccessTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "index requires authentication" do
    get personal_access_tokens_path
    assert_redirected_to signin_path
  end

  test "new requires authentication" do
    get new_personal_access_token_path
    assert_redirected_to signin_path
  end

  test "create requires authentication" do
    post personal_access_tokens_path, params: {personal_access_token: {name: "x"}}
    assert_redirected_to signin_path
  end

  test "destroy requires authentication" do
    token = @user.personal_access_tokens.create!(name: "x")
    delete personal_access_token_path(token)
    assert_redirected_to signin_path
  end

  test "index shows the user's active tokens" do
    sign_in_as(@user)
    @user.personal_access_tokens.create!(name: "Claude")

    get personal_access_tokens_path
    assert_response :success
    assert_select "li", text: /Claude/
  end

  test "create displays the plaintext token exactly once via flash" do
    sign_in_as(@user)
    assert_difference -> { @user.personal_access_tokens.count }, 1 do
      post personal_access_tokens_path, params: {personal_access_token: {name: "Claude"}}
    end
    follow_redirect!
    assert_response :success
    new_token = @user.personal_access_tokens.order(:created_at).last
    assert_match(/wwp_[a-f0-9]{64}/, response.body)

    # Reload the index — token should NOT appear a second time
    get personal_access_tokens_path
    assert_no_match Regexp.new(Regexp.escape(new_token.token_digest)), response.body
    assert_no_match(/wwp_[a-f0-9]{64}/, response.body)
  end

  test "create with blank name re-renders new with errors" do
    sign_in_as(@user)
    assert_no_difference -> { @user.personal_access_tokens.count } do
      post personal_access_tokens_path, params: {personal_access_token: {name: ""}}
    end
    assert_response :unprocessable_entity
  end

  test "destroy revokes the token (does not delete it)" do
    sign_in_as(@user)
    token = @user.personal_access_tokens.create!(name: "x")

    assert_no_difference -> { @user.personal_access_tokens.count } do
      delete personal_access_token_path(token)
    end
    assert token.reload.revoked?
  end

  test "destroy cannot revoke another user's token" do
    sign_in_as(@user)
    other_token = users(:two).personal_access_tokens.create!(name: "theirs")

    delete personal_access_token_path(other_token)
    assert_response :not_found
    assert_not other_token.reload.revoked?
  end
end
