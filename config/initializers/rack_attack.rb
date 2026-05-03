# Rack::Attack uses Rails.cache (Solid Cache in production, memory store in development).
# No Redis required.

class Rack::Attack
  # Open Dynamic Client Registration is required by claude.ai's UX, but it lets anyone
  # create an OAuth application. Throttle to keep the table from getting trash-filled.
  throttle("oauth/register/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/oauth/register" && req.post?
  end

  self.throttled_responder = lambda do |request|
    [
      429,
      {"Content-Type" => "application/json"},
      [{error: "rate_limited", error_description: "Too many requests"}.to_json]
    ]
  end
end

Rails.application.config.middleware.use Rack::Attack
