require "test_helper"

module Oauth
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    def post_register(body)
      post "/oauth/register", params: body.to_json, headers: {"Content-Type" => "application/json"}
    end

    test "valid registration creates a public application and returns 201 with client_id" do
      post_register(
        client_name: "Claude.ai Test",
        redirect_uris: ["https://claude.ai/api/mcp/auth_callback/abc"]
      )
      assert_response :created
      body = JSON.parse(response.body)
      assert body["client_id"].present?
      refute body.key?("client_secret"), "public clients must not get a secret"
      assert_equal "none", body["token_endpoint_auth_method"]
      assert_equal "Claude.ai Test", body["client_name"]

      app = Doorkeeper::Application.find_by(uid: body["client_id"])
      assert app
      refute app.confidential?
      assert app.created_via_dcr
      assert_equal "mcp", app.scopes.to_s
      assert_equal "Claude.ai Test", app.client_name
    end

    test "missing redirect_uris is rejected" do
      post_register({})
      assert_response :bad_request
      assert_equal "invalid_redirect_uri", JSON.parse(response.body)["error"]
    end

    test "non-https non-localhost redirect is rejected" do
      post_register(redirect_uris: ["http://example.com/cb"])
      assert_response :bad_request
      assert_equal "invalid_redirect_uri", JSON.parse(response.body)["error"]
    end

    test "http localhost redirect is allowed (for local dev clients)" do
      post_register(redirect_uris: ["http://localhost:1234/cb"])
      assert_response :created
    end

    test "client_secret_basic auth method is rejected" do
      post_register(
        redirect_uris: ["https://example.com/cb"],
        token_endpoint_auth_method: "client_secret_basic"
      )
      assert_response :bad_request
    end

    test "unknown grant_type is rejected" do
      post_register(
        redirect_uris: ["https://example.com/cb"],
        grant_types: ["password"]
      )
      assert_response :bad_request
    end
  end
end
