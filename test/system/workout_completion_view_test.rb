require "application_system_test_case"

class WorkoutCompletionViewTest < ApplicationSystemTestCase
  # Helper to click button with retry for Turbo Stream DOM updates
  def click_button_with_retry(text, max_attempts: 3)
    attempts = 0
    begin
      attempts += 1
      find_button(text, wait: 5).click
    rescue Playwright::Error => e
      if e.message.include?("not attached to the DOM") && attempts < max_attempts
        sleep 0.1
        retry
      else
        raise
      end
    end
  end

  setup do
    @user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(@user)

    # Create program with 2 exercises
    @program = Program.create!(title: "Completion Test Program", user: @user)
    @program.exercises.create!(name: "Push-ups", repeat_count: 2, description: "Do push-ups", position: 1)
    @program.exercises.create!(name: "Squats", repeat_count: 1, description: "Do squats", position: 2)
  end

  test "completed workout displays success message and summary with proper styling" do
    # Start and complete the workout
    visit program_path(@program)
    click_link "Start Workout"
    click_button "Begin Workout"

    # Complete all exercises (3 total: 2 push-ups + 1 squat) using retry helper
    3.times { click_button_with_retry("Mark Complete") }

    # Assert completion heading is present (h1 style per spec)
    assert_text "Workout Complete!"

    # Assert completion stats display correctly
    assert_text "You completed 3 of 3 exercises"

    # Assert timestamp displays with proper format
    within("div.text-center") do
      assert_selector "svg", minimum: 1 # Calendar icon should be present
    end

    # Assert Exercise Summary section is present
    assert_text "Exercise Summary"

    # Assert exercise names are present
    assert_text "Push-ups"
    assert_text "Squats"

    # Assert completed badges (more specific selector)
    assert_selector ".inline-flex.items-center", text: "Completed", count: 3

    # Assert action buttons are present
    assert_link "Browse Programs"
    assert_link "Done"
  end

  test "completed workout view is responsive on mobile" do
    # Set mobile viewport
    page.current_window.resize_to(375, 667)

    # Start and complete the workout
    visit program_path(@program)
    click_link "Start Workout"
    click_button "Begin Workout"

    # Complete all exercises using retry helper
    3.times { click_button_with_retry("Mark Complete") }

    # Assert completion message displays on mobile
    assert_text "Workout Complete!"
    assert_text "You completed 3 of 3 exercises"

    # Assert buttons are accessible on mobile
    assert_link "Done"
  end

  test "return to programs navigation works from completion screen" do
    # Start and complete the workout
    visit program_path(@program)
    click_link "Start Workout"
    click_button "Begin Workout"

    # Complete all exercises using retry helper
    3.times { click_button_with_retry("Mark Complete") }

    # Click Done button
    click_link "Done"

    # Assert we're back at programs list
    assert_current_path programs_path
  end
end
