module Oauth
  # Serves the OAuth discovery documents that claude.ai's remote MCP connector
  # fetches before starting an authorization flow.
  #
  #   - /.well-known/oauth-protected-resource    (RFC 9728)
  #   - /.well-known/oauth-authorization-server  (RFC 8414)
  #
  # Both are computed from the request's host so dev (local.wombatworkouts.com:PORT)
  # and prod (www.wombatworkouts.com) work without environment-specific config.
  class MetadataController < ActionController::API
    def protected_resource
      cache_publicly!
      render json: {
        resource: mcp_url,
        authorization_servers: [issuer],
        scopes_supported: ["mcp"],
        bearer_methods_supported: ["header"]
      }
    end

    def authorization_server
      cache_publicly!
      render json: {
        issuer: issuer,
        authorization_endpoint: "#{issuer}/oauth/authorize",
        token_endpoint: "#{issuer}/oauth/token",
        registration_endpoint: "#{issuer}/oauth/register",
        revocation_endpoint: "#{issuer}/oauth/revoke",
        scopes_supported: ["mcp"],
        response_types_supported: ["code"],
        grant_types_supported: ["authorization_code", "refresh_token"],
        code_challenge_methods_supported: ["S256"],
        token_endpoint_auth_methods_supported: ["none"]
      }
    end

    private

    def issuer
      request.base_url
    end

    def mcp_url
      "#{issuer}/mcp"
    end

    def cache_publicly!
      response.headers["Cache-Control"] = "public, max-age=3600"
    end
  end
end
