class AccountRecoveryMailer < ApplicationMailer
  default from: "jamie@ideasasylum.com"

  def recovery_code(account_recovery)
    @account_recovery = account_recovery
    @user = account_recovery.user
    @code = account_recovery.code

    mail(
      to: @user.email,
      subject: "Your Account Recovery Code"
    )
  end
end
