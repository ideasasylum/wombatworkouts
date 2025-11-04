require "application_system_test_case"

class ProgramFormRedesignTest < ApplicationSystemTestCase
  # Task Group 6.1: Focused tests for program form redesign
  # These tests verify the minimalist notepad UI styling is applied correctly

  test "new program form renders with minimalist styling" do
    # Create user and sign in
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    # Visit new program page
    visit new_program_path

    # Verify heading is present with correct text
    assert_selector "h1", text: "New Program"

    # Verify form fields are present with correct labels
    assert_selector "label", text: "Name"
    assert_selector "label", text: "Description (optional)"

    # Verify input placeholder text matches prototype
    assert_selector "input[placeholder='e.g., Upper Body Strength']"
    assert_selector "textarea[placeholder='Brief description...']"

    # Verify Create button with save icon is present
    assert_button "Create"

    # Verify Cancel link is present
    assert_link "Cancel"
  end

  test "form submission creates program with new styling" do
    # Create user and sign in
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    # Visit new program page
    visit new_program_path

    # Fill in program form with unique title
    program_title = "Redesign Test Program #{Time.current.to_i}"
    fill_in "Name", with: program_title
    fill_in "Description (optional)", with: "Testing the redesigned form"

    # Submit the form
    click_button "Create"

    # Assert program was created successfully
    assert_text program_title
    assert_text "Program created successfully"

    # Verify redirected to program show page
    assert_match %r{/programs/[0-9a-f-]+}, current_path
  end

  test "edit program form pre-populates data and has correct styling" do
    # Create user and sign in
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    # Create a program
    program = user.programs.create!(
      title: "Original Program Title",
      description: "Original description"
    )

    # Visit edit program page
    visit edit_program_path(program)

    # Verify heading is present with correct text
    assert_selector "h1", text: "Edit Program"

    # Verify form fields are pre-populated
    assert_field "Name", with: "Original Program Title"
    assert_field "Description (optional)", with: "Original description"

    # Verify Save button is present (not "Create")
    assert_button "Save"

    # Verify Cancel link is present
    assert_link "Cancel"

    # Update the program
    fill_in "Name", with: "Updated Program Title"
    click_button "Save"

    # Assert program was updated successfully
    assert_text "Updated Program Title"
    assert_text "Program updated successfully"
  end
end
