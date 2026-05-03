module McpAuthentication
  extend ActiveSupport::Concern

  private

  attr_reader :current_user

  # Accepts either a `wwp_`-prefixed Personal Access Token (used by Claude Code,
  # Claude Desktop, Cursor, etc) or a Doorkeeper OAuth access token (used by
  # claude.ai's remote-connector flow). The 401 challenge always advertises the
  # protected-resource-metadata URL so any unauthenticated client can discover OAuth.
  def authenticate_mcp!
    token = bearer_token
    return challenge!("invalid_token", "missing token") if token.blank?

    if token.start_with?(PersonalAccessToken::TOKEN_PREFIX)
      authenticate_pat(token)
    else
      authenticate_oauth(token)
    end
  end

  def authenticate_pat(token)
    pat = PersonalAccessToken.authenticate(token)
    return challenge!("invalid_token") unless pat

    @current_user = pat.user
    pat.touch_last_used!
  end

  def authenticate_oauth(token)
    access_token = Doorkeeper::AccessToken.by_token(token)
    return challenge!("invalid_token") unless access_token&.accessible?

    if access_token.resource.present? && access_token.resource != expected_resource
      return challenge!("invalid_token", "audience mismatch")
    end

    unless access_token.scopes.exists?("mcp")
      return challenge!("insufficient_scope", "scope 'mcp' required", scope: "mcp")
    end

    user = User.find_by(id: access_token.resource_owner_id)
    return challenge!("invalid_token", "resource owner not found") unless user

    @current_user = user
  end

  def bearer_token
    header = request.headers["Authorization"]
    return nil if header.blank?

    match = header.match(/\ABearer (?<token>.+)\z/)
    match && match[:token].strip
  end

  def expected_resource
    "#{request.base_url}/mcp"
  end

  def challenge!(error, description = nil, scope: nil)
    prm_url = "#{request.base_url}/.well-known/oauth-protected-resource"
    parts = [
      'Bearer realm="Wombat Workouts"',
      %(resource_metadata="#{prm_url}"),
      %(error="#{error}")
    ]
    parts << %(error_description="#{description}") if description
    parts << %(scope="#{scope}") if scope
    response.headers["WWW-Authenticate"] = parts.join(", ")
    render json: {error: error}, status: :unauthorized
  end
end
