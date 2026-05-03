# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  base_controller "ApplicationController"

  realm "Wombat Workouts"

  resource_owner_authenticator do
    if (uid = session[:user_id]) && (user = User.find_by(id: uid))
      user
    else
      session[:return_to] = request.fullpath
      redirect_to "/signin", alert: "Please sign in to continue"
      nil
    end
  end

  grant_flows %w[authorization_code]

  use_refresh_token

  force_pkce

  default_scopes :mcp

  access_token_expires_in 1.hour

  # RFC 8707: lets us pass `resource` through /authorize -> grant -> /token -> access_token
  # so the MCP endpoint can verify token audience matches the request URL.
  custom_access_token_attributes [:resource]

  # Production deploys must use https; allow plain http only when the redirect host
  # is localhost so local-dev MCP clients (mcp-inspector etc) keep working.
  force_ssl_in_redirect_uri do |uri|
    !%w[localhost 127.0.0.1 ::1].include?(uri.host)
  end
end
