require "application_system_test_case"

class RemindersTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    @program = @user.programs.create!(title: "Test Program", description: "Test description")
    sign_in_as(@user)
  end

  test "visiting reminders index page shows empty state" do
    visit reminders_path

    assert_text "Workout Reminders"
    assert_text "No reminders yet"
  end

  test "creating a reminder from the reminders page" do
    visit reminders_path

    # Fill in the reminder form
    select @program.title, from: "reminder_program_id"
    check "reminder_days_of_week_monday"
    check "reminder_days_of_week_wednesday"
    fill_in "reminder_time", with: "09:00"

    click_button "Create Reminder"

    # Should see success message and the reminder in the list
    assert_text "Reminder created successfully"
    assert_text @program.title
    assert_text "Monday, Wednesday"
    assert_text "9:00 AM"
  end

  test "toggling a reminder enabled status" do
    # Create a reminder first
    reminder = @user.reminders.create!(
      program: @program,
      days_of_week: ["monday", "wednesday"],
      time: "09:00",
      timezone: "America/New_York",
      enabled: true
    )

    visit reminders_path

    # Find the toggle label and click it
    within("div[data-controller='reminder-toggle']") do
      # Click the visible toggle switch element (the div, not the label)
      find("div.rounded-full").click
    end

    # Wait for the AJAX request to complete
    sleep 2

    # Verify the reminder was disabled in database
    reminder.reload
    assert_equal false, reminder.enabled
  end

  test "deleting a reminder" do
    # Create a reminder first
    reminder = @user.reminders.create!(
      program: @program,
      days_of_week: ["monday"],
      time: "09:00",
      timezone: "America/New_York"
    )

    visit reminders_path

    # Verify the reminder card is visible (has the timezone)
    assert_text "America/New_York"

    # Find and click the delete button (it's a button with a trash icon)
    accept_confirm do
      # Find the delete form by its action attribute
      find("form[action='#{reminder_path(reminder)}'] button").click
    end

    # Should see success message
    assert_text "Reminder deleted successfully"

    # Should see empty state now
    assert_text "No reminders yet"

    # The reminder card with timezone should be gone
    assert_no_text "America/New_York"
  end

  test "bell icon in navbar links to reminders page" do
    visit dashboard_path

    # Desktop view
    page.current_window.resize_to(1280, 720)

    # Click the bell icon (aria-label)
    find("a[aria-label='Reminders']").click

    assert_current_path reminders_path
    assert_text "Workout Reminders"
  end
end
