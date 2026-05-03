module Oauth
  # RFC 7591 Dynamic Client Registration. Lets claude.ai (and any other MCP client
  # that supports DCR) auto-register without the user having to manually create a
  # client_id. We register only public clients (no client_secret); PKCE protects
  # the authorization code exchange, which is correct per OAuth 2.1.
  class RegistrationsController < ActionController::API
    ALLOWED_GRANT_TYPES = %w[authorization_code refresh_token].freeze
    ALLOWED_RESPONSE_TYPES = %w[code].freeze
    ALLOWED_AUTH_METHODS = %w[none].freeze

    def create
      body = parsed_body
      redirect_uris = Array(body["redirect_uris"])
      return error("invalid_redirect_uri", "redirect_uris is required") if redirect_uris.empty?

      bad_uri = redirect_uris.find { |uri| !valid_redirect_uri?(uri) }
      return error("invalid_redirect_uri", "redirect_uri #{bad_uri.inspect} is not allowed") if bad_uri

      grant_types = Array(body["grant_types"]).presence || %w[authorization_code]
      unless (grant_types - ALLOWED_GRANT_TYPES).empty?
        return error("invalid_client_metadata", "unsupported grant_types")
      end

      response_types = Array(body["response_types"]).presence || %w[code]
      unless (response_types - ALLOWED_RESPONSE_TYPES).empty?
        return error("invalid_client_metadata", "unsupported response_types")
      end

      auth_method = body["token_endpoint_auth_method"] || "none"
      unless ALLOWED_AUTH_METHODS.include?(auth_method)
        return error("invalid_client_metadata", "token_endpoint_auth_method must be 'none'")
      end

      client_name = body["client_name"].to_s.strip.presence
      app_name = client_name || "DCR Client"

      application = Doorkeeper::Application.create!(
        name: app_name.truncate(100),
        client_name: client_name,
        redirect_uri: redirect_uris.join("\n"),
        scopes: "mcp",
        confidential: false,
        created_via_dcr: true
      )

      render status: :created, json: {
        client_id: application.uid,
        client_id_issued_at: application.created_at.to_i,
        redirect_uris: redirect_uris,
        token_endpoint_auth_method: "none",
        grant_types: grant_types,
        response_types: response_types,
        client_name: client_name,
        scope: "mcp"
      }
    rescue ActiveRecord::RecordInvalid => e
      error("invalid_client_metadata", e.record.errors.full_messages.join("; "))
    end

    private

    def parsed_body
      return params.to_unsafe_h.except("controller", "action") if request.content_type.to_s.exclude?("json")
      JSON.parse(request.raw_post.presence || "{}")
    rescue JSON::ParserError
      {}
    end

    def valid_redirect_uri?(uri)
      parsed = URI.parse(uri)
      return false unless parsed.host && parsed.scheme
      return true if parsed.scheme == "https"
      return true if parsed.scheme == "http" && %w[localhost 127.0.0.1 ::1].include?(parsed.host)
      false
    rescue URI::InvalidURIError
      false
    end

    def error(code, description)
      render status: :bad_request, json: {error: code, error_description: description}
    end
  end
end
