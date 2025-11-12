class SessionsController < ApplicationController
  # Prevent caching of authentication pages and responses
  before_action :set_no_cache_headers

  # Signup (Registration) Actions
  def new_signup
    # Render the signup form
  end

  def create_signup
    email = params[:email]&.strip&.downcase

    # Basic email validation
    unless email.present? && email.include?("@")
      render turbo_stream: turbo_stream.replace(
        "signup_flow",
        partial: "sessions/error",
        locals: {message: "Please enter a valid email address", flow_type: "signup"}
      )
      return
    end

    # Check if user already exists
    if User.exists?(email: email)
      render turbo_stream: turbo_stream.replace(
        "signup_flow",
        partial: "sessions/error",
        locals: {message: "An account with this email already exists. Please sign in instead.", flow_type: "signup"}
      )
      return
    end

    # Generate WebAuthn registration challenge
    generate_registration_challenge(email)
  end

  # Signin (Authentication) Actions
  def new_signin
    # Render the signin form
  end

  def create_signin
    email = params[:email]&.strip&.downcase

    # Basic email validation
    unless email.present? && email.include?("@")
      render turbo_stream: turbo_stream.replace(
        "signin_flow",
        partial: "sessions/error",
        locals: {message: "Please enter a valid email address", flow_type: "signin"}
      )
      return
    end

    # Check if user exists
    user = User.find_by(email: email)

    unless user
      render turbo_stream: turbo_stream.replace(
        "signin_flow",
        partial: "sessions/error",
        locals: {message: "No account found with this email. Please sign up instead.", flow_type: "signin"}
      )
      return
    end

    # Generate WebAuthn authentication challenge
    generate_authentication_challenge(user)
  end

  # Logout
  def destroy
    reset_session
    redirect_to root_path, notice: "You have been logged out"
  end

  # Session health check endpoint for PWA
  def health_check
    respond_to do |format|
      format.json do
        if logged_in?
          render json: {
            authenticated: true,
            user_id: current_user.id,
            email: current_user.email
          }
        else
          render json: {authenticated: false}, status: :unauthorized
        end
      end
    end
  end

  # Verification Actions (called by Stimulus controller via form submission)
  def handle_registration
    email = params[:email]&.strip&.downcase
    credential_response = JSON.parse(params[:credential_response])

    # Verify the credential
    webauthn_credential = WebAuthn::Credential.from_create(credential_response)

    # Verify against stored challenge
    webauthn_credential.verify(session[:webauthn_challenge])

    # Create user with the stored webauthn_id
    user = User.create!(
      email: email
    )

    # Store the credential
    user.credentials.create!(
      external_id: webauthn_credential.id,
      public_key: webauthn_credential.public_key,
      sign_count: webauthn_credential.sign_count
    )

    # Create session
    create_user_session(user)

    # Clear temporary session data
    session.delete(:webauthn_challenge)
    session.delete(:pending_email)
    session.delete(:pending_webauthn_id)
    session.delete(:flow_type)

    redirect_to session.delete(:return_to) || dashboard_path, notice: "Welcome! Your account has been created."
  rescue => e
    Rails.logger.error "Registration failed: #{e.message}"
    redirect_to signup_path, alert: "Registration failed. Please try again."
  end

  def handle_authentication
    email = params[:email]&.strip&.downcase
    credential_response = JSON.parse(params[:credential_response])

    user = User.find_by(email: email)
    raise "User not found" unless user

    # Verify the credential
    webauthn_credential = WebAuthn::Credential.from_get(credential_response)

    # Find matching credential
    credential = user.credentials.find_by(external_id: webauthn_credential.id)
    raise "Credential not found" unless credential

    # Verify against stored challenge and public key
    webauthn_credential.verify(
      session[:webauthn_challenge],
      public_key: credential.public_key,
      sign_count: credential.sign_count
    )

    # Update sign count
    credential.update!(sign_count: webauthn_credential.sign_count)

    # Create session
    create_user_session(user)

    # Clear temporary session data
    session.delete(:webauthn_challenge)
    session.delete(:pending_email)
    session.delete(:flow_type)

    redirect_to session.delete(:return_to) || dashboard_path, notice: "Welcome back!"
  rescue => e
    Rails.logger.error "Authentication failed: #{e.message}"
    redirect_to signin_path, alert: "Authentication failed. Please try again."
  end

  private

  def set_no_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end

  def generate_registration_challenge(email)
    # Generate a temporary webauthn_id for the challenge
    webauthn_id = SecureRandom.hex(16)

    # Generate WebAuthn registration options
    options = WebAuthn::Credential.options_for_create(
      user: {
        id: webauthn_id,
        name: email,
        display_name: email
      },
      exclude: []
    )

    # Store challenge and email in session for verification
    session[:webauthn_challenge] = options.challenge
    session[:pending_email] = email
    session[:pending_webauthn_id] = webauthn_id
    session[:flow_type] = "registration"

    render turbo_stream: turbo_stream.replace(
      "signup_flow",
      partial: "sessions/signup_challenge",
      locals: {
        email: email,
        options: options.as_json
      }
    )
  end

  def generate_authentication_challenge(user)
    # Get all credentials for this user
    credentials = user.credentials.pluck(:external_id)

    # Generate WebAuthn authentication options
    options = WebAuthn::Credential.options_for_get(
      allow: credentials
    )

    # Store challenge and email in session for verification
    session[:webauthn_challenge] = options.challenge
    session[:pending_email] = user.email
    session[:flow_type] = "authentication"

    render turbo_stream: turbo_stream.replace(
      "signin_flow",
      partial: "sessions/signin_challenge",
      locals: {
        email: user.email,
        options: options.as_json
      }
    )
  end

  def create_user_session(user)
    # Clear old session data
    reset_session

    # Create new session
    session[:user_id] = user.id

    # Regenerate session ID for security
    request.session_options[:renew] = true
  end
end
