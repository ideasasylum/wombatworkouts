require "application_system_test_case"

class ProgramCreationTest < ApplicationSystemTestCase
  test "test_creating_program_on_desktop" do
    # Create user and sign in
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    # Set viewport to desktop size
    page.current_window.resize_to(1280, 720)

    # Visit programs index
    visit programs_path

    # Click "Create Program" link (shown when there are no programs)
    click_link "Create Program"

    # Fill in program form with unique title
    program_title = "Test Program #{Time.current.to_i}"
    fill_in "Name", with: program_title
    fill_in "Description", with: "Test description"

    # Submit the form using the button
    click_button "Create"

    # Assert page contains program title (this waits for the page to load)
    assert_text program_title

    # Assert success message visible
    assert_text "Program created successfully"

    # Assert redirected to program show page (URL should contain program UUID)
    # UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    assert_match %r{/programs/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}, current_path
  end

  test "test_creating_program_on_mobile" do
    # Create user and sign in
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    # Set viewport to mobile size
    page.current_window.resize_to(375, 667)

    # Visit programs index
    visit programs_path

    # Click "Create Program" link (shown when there are no programs)
    click_link "Create Program"

    # Fill in program form with unique title
    program_title = "Test Program #{Time.current.to_i}"
    fill_in "Name", with: program_title
    fill_in "Description", with: "Test description"

    # Submit the form using the button
    click_button "Create"

    # Assert page contains program title (this waits for the page to load)
    assert_text program_title

    # Assert success message visible
    assert_text "Program created successfully"

    # Assert redirected to program show page (URL should contain program UUID)
    # UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    assert_match %r{/programs/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}, current_path
  end
end
