require "test_helper"

class AccountRecoveryMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
    @recovery = @user.account_recoveries.create!
  end

  test "recovery_code email" do
    email = AccountRecoveryMailer.recovery_code(@recovery)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["jamie@ideasasylum.com"], email.from
    assert_equal [@user.email], email.to
    assert_equal "Your Account Recovery Code", email.subject
    assert_match @recovery.code, email.body.encoded
    assert_match "15 minutes", email.body.encoded
  end

  test "recovery_code email contains code in both HTML and text parts" do
    email = AccountRecoveryMailer.recovery_code(@recovery)

    # Check HTML part
    html_part = email.html_part.body.to_s
    assert_match @recovery.code, html_part
    assert_match "Account Recovery Code", html_part
    assert_match "Wombat Workouts", html_part

    # Check text part
    text_part = email.text_part.body.to_s
    assert_match @recovery.code, text_part
    assert_match "Account Recovery Code", text_part
    assert_match "wombatworkouts.com", text_part
  end
end
