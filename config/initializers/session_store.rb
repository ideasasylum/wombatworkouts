# Configure database-backed sessions with 30-day expiration
Rails.application.config.session_store :active_record_store,
  key: "_wombatworkouts_session",
  secure: Rails.env.production?, # Secure cookies in production (HTTPS only)
  httponly: true,                # Prevent XSS attacks by making cookie inaccessible to JavaScript
  same_site: :lax,               # CSRF protection while allowing navigation from external sites
  expire_after: 30.days          # Sessions expire after 30 days of inactivity
