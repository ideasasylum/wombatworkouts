require "test_helper"

# End-to-end exercise of the OAuth 2.1 flow that claude.ai's remote MCP connector
# performs: discover metadata, register a client (DCR), redirect through /authorize
# with PKCE and the RFC 8707 resource parameter, exchange the code at /token, and
# use the resulting access token at /mcp.
class OauthAuthorizationCodeFlowTest < ActionDispatch::IntegrationTest
  MCP_RESOURCE = "http://www.example.com/mcp".freeze

  setup do
    @user = users(:one)
    @code_verifier = SecureRandom.urlsafe_base64(64).tr("=", "")
    @code_challenge = Base64.urlsafe_encode64(
      Digest::SHA256.digest(@code_verifier), padding: false
    )
  end

  test "claude.ai-style flow: discover, register, authorize, token, call MCP" do
    # 1. Discover.
    get "/.well-known/oauth-protected-resource"
    assert_response :ok
    prm = JSON.parse(response.body)
    assert_equal MCP_RESOURCE, prm["resource"]
    auth_server = prm["authorization_servers"].first

    get URI.parse(auth_server).path + "/.well-known/oauth-authorization-server"
    assert_response :ok
    asm = JSON.parse(response.body)
    assert_includes asm["code_challenge_methods_supported"], "S256"

    # 2. Dynamic Client Registration.
    redirect_uri = "https://claude.ai/api/mcp/auth_callback/test"
    post "/oauth/register",
      params: {
        client_name: "Claude.ai",
        redirect_uris: [redirect_uri]
      }.to_json,
      headers: {"Content-Type" => "application/json"}
    assert_response :created
    client_id = JSON.parse(response.body)["client_id"]

    # 3. Authorize. Sign in first so the consent screen is reachable.
    sign_in_as(@user)
    get "/oauth/authorize", params: {
      client_id: client_id,
      redirect_uri: redirect_uri,
      response_type: "code",
      state: "abc123",
      scope: "mcp",
      code_challenge: @code_challenge,
      code_challenge_method: "S256",
      resource: MCP_RESOURCE
    }
    assert_response :ok

    # 4. Approve the consent screen → POST /oauth/authorize → 302 to redirect_uri with code.
    post "/oauth/authorize", params: {
      client_id: client_id,
      redirect_uri: redirect_uri,
      response_type: "code",
      state: "abc123",
      scope: "mcp",
      code_challenge: @code_challenge,
      code_challenge_method: "S256",
      resource: MCP_RESOURCE
    }
    assert_response :found
    location = URI.parse(response.headers["Location"])
    redirect_params = Rack::Utils.parse_nested_query(location.query)
    assert_equal "abc123", redirect_params["state"]
    code = redirect_params["code"]
    assert code.present?

    grant = Doorkeeper::AccessGrant.find_by(token: code)
    assert_equal MCP_RESOURCE, grant.resource

    # 5. Exchange code for token, supplying the same code_verifier and resource.
    post "/oauth/token", params: {
      grant_type: "authorization_code",
      code: code,
      redirect_uri: redirect_uri,
      client_id: client_id,
      code_verifier: @code_verifier,
      resource: MCP_RESOURCE
    }
    assert_response :ok
    token_response = JSON.parse(response.body)
    access_token = token_response["access_token"]
    assert access_token.present?
    assert_equal "Bearer", token_response["token_type"]

    persisted = Doorkeeper::AccessToken.by_token(access_token)
    assert_equal MCP_RESOURCE, persisted.resource

    # 6. Use the token at /mcp.
    body = {jsonrpc: "2.0", id: "1", method: "tools/list", params: {}}.to_json
    post "/mcp", params: body, headers: {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"
    }
    assert_response :ok
    parsed = JSON.parse(response.body)
    refute parsed.key?("error"), "JSON-RPC error: #{parsed["error"]}"
    tool_names = parsed.dig("result", "tools").map { |t| t["name"] }
    assert_includes tool_names, "list_programs"
  end

  test "S256 is required; plain method is rejected" do
    application = Doorkeeper::Application.create!(
      name: "test", redirect_uri: "https://example.com/cb",
      scopes: "mcp", confidential: false, created_via_dcr: true
    )
    sign_in_as(@user)
    get "/oauth/authorize", params: {
      client_id: application.uid,
      redirect_uri: "https://example.com/cb",
      response_type: "code",
      state: "x",
      scope: "mcp",
      code_challenge: "abc",
      code_challenge_method: "plain",
      resource: MCP_RESOURCE
    }
    assert_response :bad_request
    assert_equal "invalid_request", JSON.parse(response.body)["error"]
  end

  test "resource parameter must equal the MCP server URL" do
    application = Doorkeeper::Application.create!(
      name: "test", redirect_uri: "https://example.com/cb",
      scopes: "mcp", confidential: false, created_via_dcr: true
    )
    sign_in_as(@user)
    get "/oauth/authorize", params: {
      client_id: application.uid,
      redirect_uri: "https://example.com/cb",
      response_type: "code",
      state: "x",
      scope: "mcp",
      code_challenge: @code_challenge,
      code_challenge_method: "S256",
      resource: "https://attacker.example/mcp"
    }
    assert_response :bad_request
    assert_equal "invalid_target", JSON.parse(response.body)["error"]
  end

  test "unauthenticated /oauth/authorize redirects to signin and preserves return_to" do
    application = Doorkeeper::Application.create!(
      name: "test", redirect_uri: "https://example.com/cb",
      scopes: "mcp", confidential: false, created_via_dcr: true
    )
    get "/oauth/authorize", params: {
      client_id: application.uid,
      redirect_uri: "https://example.com/cb",
      response_type: "code",
      state: "x",
      scope: "mcp",
      code_challenge: @code_challenge,
      code_challenge_method: "S256",
      resource: MCP_RESOURCE
    }
    assert_redirected_to signin_path
    assert_match(%r{/oauth/authorize}, session[:return_to].to_s)
  end
end
