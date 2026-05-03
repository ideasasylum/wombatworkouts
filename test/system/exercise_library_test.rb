require "application_system_test_case"

class ExerciseLibraryTest < ApplicationSystemTestCase
  test "exercises are auto-saved to library and reusable in another program" do
    user = User.create!(email: "library#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    page.current_window.resize_to(1280, 720)

    program_a = Program.create!(title: "Program A", user: user)
    visit program_path(program_a)
    click_link "Add Exercise"

    exercise_name = "Library exercise #{Time.current.to_i}"
    fill_in "Exercise Name", with: exercise_name
    fill_in "Repeat Count", with: "10"
    click_button "Add Exercise"

    assert_text exercise_name

    visit library_exercises_path
    assert_text "Exercise Library"
    assert_text exercise_name

    program_b = Program.create!(title: "Program B", user: user)
    visit program_path(program_b)
    click_link "Add Exercise"

    assert_text "Add from your library"
    click_button "Show 1 saved exercise"
    click_link exercise_name

    assert_field "Exercise Name", with: exercise_name
    fill_in "Repeat Count", with: "5"
    click_button "Add Exercise"

    assert_text exercise_name
    assert_equal 1, user.library_exercises.where(name: exercise_name).count,
      "Reusing a library exercise should not create another library entry"
  end

  test "library exercise can be edited and deleted" do
    user = User.create!(email: "library_edit#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    user.library_exercises.create!(name: "Original Name")

    visit library_exercises_path
    click_link "Original Name"

    fill_in "Exercise Name", with: "Renamed exercise"
    click_button "Update Exercise"

    assert_text "Renamed exercise"
    assert_no_text "Original Name"

    accept_confirm do
      find('button[aria-label="Delete exercise"]').click
    end

    assert_text "Your library is empty"
  end
end
