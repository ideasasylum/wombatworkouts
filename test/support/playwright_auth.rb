#!/usr/bin/env ruby

# Playwright Authentication Helper
# Generates authenticated session for Playwright tests by creating a session in the database
# Usage: ruby test/support/playwright_auth.rb user_email@example.com

require_relative "../../config/environment"
require "json"

# Generate authenticated session for a user
# @param user_email [String] Email address of the user to authenticate
# @return [Hash] Session details including session_id, user_id, and cookie_name
def generate_auth_session(user_email:)
  # Find or create test user
  user = User.find_or_create_by!(email: user_email) do |u|
    # User model will automatically generate webauthn_id via callback
  end

  # Generate unique session_id
  session_id = SecureRandom.hex(16)

  # Session data to store
  session_data = {user_id: user.id}

  # Create session record in database (ActiveRecord session store)
  ActiveRecord::SessionStore::Session.create!(
    session_id: session_id,
    data: session_data
  )

  # Return session details as JSON
  {
    session_id: session_id,
    user_id: user.id,
    cookie_name: Rails.application.config.session_options[:key]
  }
end

# Main execution when script is run directly
if __FILE__ == $0
  # Get email from command line argument
  email = ARGV[0] || "playwright-test@example.com"

  begin
    # Generate session
    result = generate_auth_session(user_email: email)

    # Output JSON to stdout for Node.js to parse
    puts JSON.generate(result)
  rescue => e
    # Output error as JSON
    warn JSON.generate({error: e.message, backtrace: e.backtrace.first(5)})
    exit 1
  end
end
