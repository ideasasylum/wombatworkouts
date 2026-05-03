require "test_helper"

class ConnectedAppsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @application = Doorkeeper::Application.create!(
      name: "Claude.ai", redirect_uri: "https://example.com/cb",
      scopes: "mcp", confidential: false, created_via_dcr: true
    )
    @token = Doorkeeper::AccessToken.create!(
      application: @application, resource_owner_id: @user.id,
      scopes: "mcp", resource: "http://www.example.com/mcp", expires_in: 3600
    )
  end

  test "index requires authentication" do
    get connected_apps_path
    assert_redirected_to signin_path
  end

  test "index lists apps the user has authorized" do
    sign_in_as(@user)
    get connected_apps_path
    assert_response :ok
    assert_select "li", text: /Claude\.ai/
  end

  test "index does not show another user's apps" do
    other_app = Doorkeeper::Application.create!(
      name: "Other client", redirect_uri: "https://example.com/cb",
      scopes: "mcp", confidential: false
    )
    Doorkeeper::AccessToken.create!(
      application: other_app, resource_owner_id: @other_user.id,
      scopes: "mcp", resource: "http://www.example.com/mcp", expires_in: 3600
    )

    sign_in_as(@user)
    get connected_apps_path
    assert_response :ok
    assert_no_match(/Other client/, response.body)
  end

  test "destroy revokes the current user's tokens for the app" do
    sign_in_as(@user)
    delete connected_app_path(@application)
    assert_redirected_to connected_apps_path

    @token.reload
    assert @token.revoked?
  end

  test "destroy does not revoke another user's tokens for the same app" do
    other_token = Doorkeeper::AccessToken.create!(
      application: @application, resource_owner_id: @other_user.id,
      scopes: "mcp", resource: "http://www.example.com/mcp", expires_in: 3600
    )

    sign_in_as(@user)
    delete connected_app_path(@application)

    other_token.reload
    refute other_token.revoked?
  end
end
