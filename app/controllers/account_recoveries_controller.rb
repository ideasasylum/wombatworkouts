class AccountRecoveriesController < ApplicationController
  skip_before_action :require_authentication, raise: false

  # Step 1: Request recovery - user enters email
  def new
  end

  # Step 2: Send recovery code via email
  def create
    user = User.find_by(email: params[:email])

    if user
      # Create recovery code
      account_recovery = user.account_recoveries.create!

      # Send email with code
      AccountRecoveryMailer.recovery_code(account_recovery).deliver_later
    end

    # Don't reveal if email exists or not (security best practice)
    flash[:notice] = "If an account exists with that email, you'll receive a recovery code shortly."
    redirect_to verify_account_recovery_path
  end

  # Step 3: Verify code - user enters 6-digit code
  def verify
    @code = params[:code]
  end

  # Step 4: Confirm code and redirect to passkey registration
  def confirm
    code = params[:code]
    @account_recovery = AccountRecovery.active.find_by(code: code)

    if @account_recovery.nil?
      flash[:alert] = "Invalid or expired recovery code. Please try again."
      redirect_to verify_account_recovery_path
      return
    end

    # Store recovery ID in session for next step
    session[:recovery_id] = @account_recovery.id
    redirect_to register_account_recovery_path
  end

  # Step 5: Register new passkey
  def register
    recovery_id = session[:recovery_id]

    unless recovery_id
      flash[:alert] = "Session expired. Please start over."
      redirect_to new_account_recovery_path
      return
    end

    @account_recovery = AccountRecovery.find_by(id: recovery_id)

    unless @account_recovery&.active?
      flash[:alert] = "Recovery code expired. Please request a new one."
      redirect_to new_account_recovery_path
      return
    end

    @user = @account_recovery.user

    # Handle WebAuthn credential creation
    if params[:credential_response]
      begin
        webauthn_credential = WebAuthn::Credential.from_create(JSON.parse(params[:credential_response]))

        # Verify the credential
        webauthn_credential.verify(session[:creation_challenge])

        # Create new credential for user
        @user.credentials.create!(
          external_id: webauthn_credential.id,
          public_key: webauthn_credential.public_key,
          sign_count: webauthn_credential.sign_count
        )

        # Mark recovery as used
        @account_recovery.mark_as_used!

        # Clear session
        session.delete(:recovery_id)
        session.delete(:creation_challenge)

        # Log in the user
        session[:current_user_id] = @user.id

        flash[:notice] = "New passkey registered successfully!"
        redirect_to dashboard_path
      rescue WebAuthn::Error => e
        flash.now[:alert] = "Failed to register passkey: #{e.message}"
        render :register, status: :unprocessable_entity
      end
    else
      # Generate challenge for WebAuthn
      options = WebAuthn::Credential.options_for_create(
        user: {
          id: @user.webauthn_id,
          name: @user.email
        },
        exclude: @user.credentials.pluck(:external_id)
      )

      session[:creation_challenge] = options.challenge
      @options_json = options.as_json
    end
  end
end
