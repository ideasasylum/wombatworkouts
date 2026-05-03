require "test_helper"

module Oauth
  class MetadataControllerTest < ActionDispatch::IntegrationTest
    test "protected resource metadata returns RFC 9728 fields keyed off request host" do
      get "/.well-known/oauth-protected-resource"
      assert_response :ok
      body = JSON.parse(response.body)

      assert_equal "#{request.base_url}/mcp", body["resource"]
      assert_equal [request.base_url], body["authorization_servers"]
      assert_equal ["mcp"], body["scopes_supported"]
      assert_equal ["header"], body["bearer_methods_supported"]
      cache_control = response.headers["Cache-Control"]
      assert_includes cache_control, "public"
      assert_includes cache_control, "max-age=3600"
    end

    test "authorization server metadata returns RFC 8414 fields with S256-only PKCE" do
      get "/.well-known/oauth-authorization-server"
      assert_response :ok
      body = JSON.parse(response.body)

      assert_equal request.base_url, body["issuer"]
      assert_equal "#{request.base_url}/oauth/authorize", body["authorization_endpoint"]
      assert_equal "#{request.base_url}/oauth/token", body["token_endpoint"]
      assert_equal "#{request.base_url}/oauth/register", body["registration_endpoint"]
      assert_equal "#{request.base_url}/oauth/revoke", body["revocation_endpoint"]
      assert_equal ["code"], body["response_types_supported"]
      assert_equal %w[authorization_code refresh_token], body["grant_types_supported"]
      assert_equal ["S256"], body["code_challenge_methods_supported"]
      assert_equal ["none"], body["token_endpoint_auth_methods_supported"]
    end
  end
end
