require "application_system_test_case"

class FlashMessagesTest < ApplicationSystemTestCase
  test "notice flash message displays and auto-dismisses after 3 seconds" do
    # Create user and sign in
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    # Set viewport to desktop size
    page.current_window.resize_to(1280, 720)

    # Visit programs index first
    visit programs_path

    # Click "Create Program" link
    click_link "Create Program"

    # Fill in program form
    fill_in "Name", with: "Test Program #{Time.current.to_i}"
    click_button "Create"

    # Assert flash message is visible
    assert_selector "[data-controller='flash']", text: "Program created successfully"

    # Wait for auto-dismiss (3 seconds + buffer for animation)
    sleep 3.5

    # Assert flash message is no longer visible
    assert_no_selector "[data-controller='flash']", text: "Program created successfully"
  end

  test "flash message can be manually closed with close button" do
    # Create user and sign in
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    # Set viewport to desktop size
    page.current_window.resize_to(1280, 720)

    # Visit programs index first
    visit programs_path

    # Click "Create Program" link
    click_link "Create Program"

    # Fill in program form
    fill_in "Name", with: "Test Program #{Time.current.to_i}"
    click_button "Create"

    # Assert flash message is visible
    assert_selector "[data-controller='flash']", text: "Program created successfully"

    # Click the close button
    find("[data-action='click->flash#close']").click

    # Assert flash message is removed immediately
    assert_no_selector "[data-controller='flash']", text: "Program created successfully"
  end

  test "notice flash message has green styling" do
    # Create user and sign in
    user = User.create!(email: "test#{Time.current.to_i}@example.com", webauthn_id: SecureRandom.hex(16))
    sign_in_as(user)

    # Set viewport to desktop size
    page.current_window.resize_to(1280, 720)

    # Visit programs index first
    visit programs_path

    # Click "Create Program" link
    click_link "Create Program"

    # Fill in program form
    fill_in "Name", with: "Test Program #{Time.current.to_i}"
    click_button "Create"

    # Assert flash message has the notice class for green styling
    assert_selector ".flash-notice[data-controller='flash']"
    assert_selector ".flash-notice .text-green-800"
  end
end
