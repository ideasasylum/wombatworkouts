module Oauth
  # Subclasses Doorkeeper's authorizations controller so we can:
  #   - render our own consent screen
  #   - require S256 PKCE (reject `plain`)
  #   - validate the RFC 8707 `resource` parameter against our MCP URL
  #
  # Doorkeeper persists `resource` onto the access grant automatically (it's listed in
  # `custom_access_token_attributes` in the initializer) and carries it onto the access
  # token when /oauth/token is called.
  class AuthorizationsController < ::Doorkeeper::AuthorizationsController
    before_action :require_pkce_s256, only: [:new, :create]
    before_action :require_valid_resource, only: [:new, :create]

    private

    def require_pkce_s256
      method = params[:code_challenge_method].to_s
      return if method == "S256"

      render json: {
        error: "invalid_request",
        error_description: "code_challenge_method must be S256"
      }, status: :bad_request
    end

    def require_valid_resource
      resource = params[:resource].to_s
      return if resource == expected_resource

      render json: {
        error: "invalid_target",
        error_description: "resource must equal #{expected_resource}"
      }, status: :bad_request
    end

    def expected_resource
      "#{request.base_url}/mcp"
    end
  end
end
