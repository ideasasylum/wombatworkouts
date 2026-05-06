require "application_system_test_case"

class ExerciseAdditionTest < ApplicationSystemTestCase
  test "test_adding_exercises_to_program_on_desktop" do
    # Create user and sign in
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    # Create program
    program = Program.create!(title: "Test Program", description: "Test description", user: user)

    # Set viewport to desktop size
    page.current_window.resize_to(1280, 720)

    # Visit program show page
    visit program_path(program)

    # Click "Add Exercise" link (in the header)
    click_link "Add Exercise"

    # Fill exercise form with unique name
    exercise1_name = "Test Exercise 1 #{Time.current.to_i}"
    fill_in "Exercise Name", with: exercise1_name
    fill_in "Sets", with: "3"
    # Note: Description field uses OverType editor, skipping for now as it's optional

    # Submit form (button text is "Add Exercise")
    click_button "Add Exercise"

    # Assert exercise appears in the list
    assert_text exercise1_name
    assert_text "3" # Repeat count should be visible

    # Add second exercise - click the link again
    click_link "Add Exercise"

    exercise2_name = "Test Exercise 2 #{Time.current.to_i}"
    fill_in "Exercise Name", with: exercise2_name
    fill_in "Sets", with: "5"

    # Submit form
    click_button "Add Exercise"

    # Assert both exercises visible
    assert_text exercise1_name
    assert_text exercise2_name

    # Verify they appear in order (both names should be present in the page)
    page_text = page.text
    assert page_text.index(exercise1_name) < page_text.index(exercise2_name),
      "Exercises should appear in the order they were added"
  end

  test "test_adding_exercises_to_program_on_mobile" do
    # Create user and sign in
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    # Create program
    program = Program.create!(title: "Test Program", description: "Test description", user: user)

    # Set viewport to mobile size
    page.current_window.resize_to(375, 667)

    # Visit program show page
    visit program_path(program)

    # Click "Add Exercise" link (in the header)
    click_link "Add Exercise"

    # Fill exercise form with unique name
    exercise1_name = "Test Exercise 1 #{Time.current.to_i}"
    fill_in "Exercise Name", with: exercise1_name
    fill_in "Sets", with: "3"

    # Submit form (button text is "Add Exercise")
    click_button "Add Exercise"

    # Assert exercise appears in the list
    assert_text exercise1_name
    assert_text "3" # Repeat count should be visible

    # Add second exercise - click the link again
    click_link "Add Exercise"

    exercise2_name = "Test Exercise 2 #{Time.current.to_i}"
    fill_in "Exercise Name", with: exercise2_name
    fill_in "Sets", with: "5"

    # Submit form
    click_button "Add Exercise"

    # Assert both exercises visible
    assert_text exercise1_name
    assert_text exercise2_name

    # Verify they appear in order (both names should be present in the page)
    page_text = page.text
    assert page_text.index(exercise1_name) < page_text.index(exercise2_name),
      "Exercises should appear in the order they were added"
  end
end
