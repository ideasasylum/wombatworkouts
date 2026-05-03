require "application_system_test_case"

class ExerciseTimerTest < ApplicationSystemTestCase
  test "renders countdown timer for time-based exercises" do
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    program = Program.create!(title: "Hold Program", user: user)
    program.exercises.create!(name: "Plank", repeat_count: 1, position: 1, reps: nil, duration_seconds: 45)

    visit program_path(program)
    click_link "Start Workout"
    click_button "Begin Workout"

    assert_text "Plank"
    assert_text "0:45"
    assert_button "Start"
    assert_no_button "Pause"
    assert_no_button "Reset"
    assert_no_button "Continue"

    click_button "Start"
    assert_button "Pause"
    assert_no_button "Start"
    assert_no_button "Reset"

    click_button "Pause"
    assert_button "Continue"
    assert_button "Reset"
    assert_no_button "Pause"
  end

  test "shows reps text for rep-based exercises" do
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    program = Program.create!(title: "Reps Program", user: user)
    program.exercises.create!(name: "Push-ups", repeat_count: 1, position: 1, reps: 12)

    visit program_path(program)
    click_link "Start Workout"
    click_button "Begin Workout"

    assert_text "12 reps"
    assert_no_button "Start"
  end
end
