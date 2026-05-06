require "test_helper"

class AccountRecoveryFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "can request recovery code for existing email" do
    assert_enqueued_emails 1 do
      post create_account_recovery_path, params: {email: @user.email}
    end

    assert_redirected_to verify_account_recovery_path
    assert_equal "If an account exists with that email, you'll receive a recovery code shortly.", flash[:notice]

    # Verify recovery code was created
    recovery = @user.account_recoveries.last
    assert_not_nil recovery
    assert recovery.active?
  end

  test "does not reveal if email does not exist" do
    assert_no_enqueued_emails do
      post create_account_recovery_path, params: {email: "nonexistent@example.com"}
    end

    assert_redirected_to verify_account_recovery_path
    assert_equal "If an account exists with that email, you'll receive a recovery code shortly.", flash[:notice]
  end

  test "can verify valid recovery code" do
    recovery = @user.account_recoveries.create!

    post confirm_account_recovery_path, params: {code: recovery.code}

    assert_redirected_to register_account_recovery_path
  end

  test "cannot verify invalid recovery code" do
    post confirm_account_recovery_path, params: {code: "999999"}

    assert_redirected_to verify_account_recovery_path
    assert_equal "Invalid or expired recovery code. Please try again.", flash[:alert]
    assert_nil session[:recovery_id]
  end

  test "cannot verify expired recovery code" do
    recovery = @user.account_recoveries.create!(expires_at: 1.hour.ago)

    post confirm_account_recovery_path, params: {code: recovery.code}

    assert_redirected_to verify_account_recovery_path
    assert_equal "Invalid or expired recovery code. Please try again.", flash[:alert]
  end

  test "cannot verify used recovery code" do
    recovery = @user.account_recoveries.create!
    recovery.mark_as_used!

    post confirm_account_recovery_path, params: {code: recovery.code}

    assert_redirected_to verify_account_recovery_path
    assert_equal "Invalid or expired recovery code. Please try again.", flash[:alert]
  end

  test "register page requires recovery session" do
    get register_account_recovery_path

    assert_redirected_to new_account_recovery_path
    assert_equal "Session expired. Please start over.", flash[:alert]
  end

  test "register page displays with valid recovery session" do
    recovery = @user.account_recoveries.create!

    # Navigate through confirm to set session
    post confirm_account_recovery_path, params: {code: recovery.code}

    # Confirm redirects to register
    assert_redirected_to register_account_recovery_path
    follow_redirect!

    assert_response :success
    assert_select "h1", "Register New Passkey"
  end

  test "register page redirects if recovery expired after session established" do
    recovery = @user.account_recoveries.create!

    # Navigate through confirm to set session
    post confirm_account_recovery_path, params: {code: recovery.code}

    # Confirm redirects to register
    assert_redirected_to register_account_recovery_path

    # Manually expire the recovery
    recovery.update!(expires_at: 1.hour.ago)

    # Try to access register page again
    get register_account_recovery_path

    assert_redirected_to new_account_recovery_path
    assert_equal "Recovery code expired. Please request a new one.", flash[:alert]
  end
end
