# WebAuthn Configuration
# https://github.com/cedarcode/webauthn-ruby

WebAuthn.configure do |config|
  # Set the allowed origins based on the environment
  # In development: https://local.wombatworkouts.com:<PORT> (SSL required for WebAuthn)
  # In production: Use the actual production domain (HTTPS required)
  config.allowed_origins = if Rails.env.development?
    port = ENV.fetch("PORT", 3000)
    ["https://local.wombatworkouts.com:#{port}"]
  elsif Rails.env.test?
    ["https://local.wombatworkouts.com:3000"]
  else
    # In production, this should be set via environment variable
    # Example: https://www.wombatworkouts.com
    [ENV.fetch("WEBAUTHN_ORIGIN") { "https://www.wombatworkouts.com" }]
  end

  # Set the Relying Party name (displayed to users during WebAuthn prompts)
  config.rp_name = "Wombat Workouts"

  # Credential options configuration
  config.credential_options_timeout = 120_000 # 120 seconds for users to complete biometric auth

  # User verification requirement
  # Options: "required", "preferred", "discouraged"
  # "preferred" is recommended - uses biometrics if available, falls back if not
  # This ensures the best UX while maintaining security
  # config.verify_attestation_statement = Rails.env.production?
end
