class DevSessionsController < ApplicationController
  def new
    @emails = self.class.allowlisted_emails
  end

  def create
    email = params[:email]&.strip&.downcase

    unless self.class.allowlisted_emails.include?(email)
      redirect_to dev_signin_path, alert: "Email is not in DEV_SIGNIN_EMAILS allowlist"
      return
    end

    user = User.find_or_create_by!(email: email)
    reset_session
    session[:user_id] = user.id
    session[:dev_signed_in] = true
    request.session_options[:renew] = true

    redirect_to dashboard_path, notice: "Signed in as #{email} (DEV)"
  end

  def self.allowlisted_emails
    ENV.fetch("DEV_SIGNIN_EMAILS", "").split(",").map { |e| e.strip.downcase }.reject(&:empty?)
  end
end
