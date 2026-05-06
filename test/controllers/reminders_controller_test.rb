require "test_helper"

class RemindersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @program = @user.programs.create!(title: "Test Program")
    @other_program = @other_user.programs.create!(title: "Other Program")
    @reminder = @user.reminders.create!(
      program: @program,
      days_of_week: ["monday", "wednesday"],
      time: Time.parse("07:00"),
      timezone: "America/New_York"
    )
  end

  test "index requires authentication" do
    get reminders_path
    assert_redirected_to signin_path
  end

  test "authenticated user can view their reminders" do
    sign_in_as(@user)
    get reminders_path
    assert_response :success
  end

  test "create requires authentication" do
    post reminders_path, params: {
      reminder: {
        program_id: @program.id,
        days_of_week: ["monday"],
        time: "07:00",
        timezone: "America/New_York"
      }
    }
    assert_redirected_to signin_path
  end

  test "authenticated user can create reminder for their own program" do
    sign_in_as(@user)
    program = @user.programs.create!(title: "New Program")

    assert_difference("Reminder.count", 1) do
      post reminders_path, params: {
        reminder: {
          program_id: program.id,
          days_of_week: ["tuesday", "thursday"],
          time: "08:00",
          timezone: "America/Los_Angeles"
        }
      }
    end

    reminder = Reminder.last
    assert_equal @user.id, reminder.user_id
    assert_equal program.id, reminder.program_id
    assert_equal ["tuesday", "thursday"], reminder.days_of_week
  end

  test "user cannot create reminder for program they do not own" do
    sign_in_as(@user)

    assert_no_difference("Reminder.count") do
      post reminders_path, params: {
        reminder: {
          program_id: @other_program.id,
          days_of_week: ["monday"],
          time: "07:00",
          timezone: "America/New_York"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "update requires authentication" do
    patch reminder_path(@reminder), params: {
      reminder: {enabled: false}
    }
    assert_redirected_to signin_path
  end

  test "user can update their own reminder" do
    sign_in_as(@user)

    patch reminder_path(@reminder), params: {
      reminder: {enabled: false}
    }

    @reminder.reload
    assert_not @reminder.enabled
  end

  test "user cannot update reminder they do not own" do
    sign_in_as(@user)
    other_reminder = @other_user.reminders.create!(
      program: @other_program,
      days_of_week: ["friday"],
      time: Time.parse("09:00"),
      timezone: "America/New_York"
    )

    patch reminder_path(other_reminder), params: {
      reminder: {enabled: false}
    }

    # Redirects to reminders_path with alert when reminder not found
    assert_redirected_to reminders_path
    follow_redirect!
    assert_equal "Reminder not found", flash[:alert]

    other_reminder.reload
    assert other_reminder.enabled
  end

  test "destroy requires authentication" do
    delete reminder_path(@reminder)
    assert_redirected_to signin_path
  end

  test "user can destroy their own reminder" do
    sign_in_as(@user)

    assert_difference("Reminder.count", -1) do
      delete reminder_path(@reminder)
    end
  end
end
