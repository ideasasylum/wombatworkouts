require "test_helper"

class NotificationSystemIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @program = @user.programs.create!(title: "Test Program")
    @subscription = @user.push_subscriptions.create!(
      endpoint: "https://fcm.googleapis.com/fcm/send/test123",
      p256dh_key: "test_p256dh_key",
      auth_key: "test_auth_key"
    )

    # Stub WebPush at the module level to avoid actual HTTP calls
    @original_payload_send = WebPush.method(:payload_send)
    WebPush.define_singleton_method(:payload_send) { |**args| nil }
  end

  teardown do
    # Restore original method
    WebPush.define_singleton_method(:payload_send, @original_payload_send)
  end

  # Test 1: End-to-end workflow - Create reminder, job runs, notification sent
  test "end-to-end workflow: create reminder, check job runs, notification job enqueued" do
    sign_in_as(@user)

    # Step 1: Create a reminder
    current_day = Time.current.strftime("%A").downcase
    post reminders_path, params: {
      reminder: {
        program_id: @program.id,
        days_of_week: [current_day],
        time: 30.minutes.ago.strftime("%H:%M"),
        timezone: "UTC"
      }
    }

    reminder = Reminder.last
    assert_not_nil reminder

    # Step 2: Run ReminderCheckJob
    assert_enqueued_with(job: SendPushNotificationJob, args: [reminder.id]) do
      ReminderCheckJob.perform_now
    end

    # Step 3: Run SendPushNotificationJob
    SendPushNotificationJob.perform_now(reminder.id)

    # Step 4: Verify reminder was marked as sent
    reminder.reload
    assert_not_nil reminder.last_sent_at
  end

  # Test 2: Invalid subscription error handled gracefully without crashing job
  test "invalid push subscription error handled gracefully" do
    # Create reminder for current day
    current_day = Time.current.strftime("%A").downcase
    reminder = @user.reminders.create!(
      program: @program,
      days_of_week: [current_day],
      time: 30.minutes.ago,
      timezone: "UTC"
    )

    # Override stub to raise InvalidSubscription error
    WebPush.define_singleton_method(:payload_send) do |**args|
      raise WebPush::InvalidSubscription.new("Endpoint not valid", "invalid endpoint")
    end

    # Send notification - should not raise error
    assert_nothing_raised do
      SendPushNotificationJob.perform_now(reminder.id)
    end

    # Reminder should still be marked as sent despite subscription error
    reminder.reload
    assert_not_nil reminder.last_sent_at
  ensure
    # Restore the default stub for other tests
    WebPush.define_singleton_method(:payload_send) { |**args| nil }
  end

  # Test 3: Timezone conversion accuracy
  test "notifications respect user timezone for scheduled time" do
    # Create reminder in New York timezone for 9:00 AM
    ny_time = Time.current.in_time_zone("America/New_York")
    current_day = ny_time.strftime("%A").downcase

    # Set time to 30 minutes ago in New York time
    scheduled_time = (ny_time - 30.minutes).strftime("%H:%M")

    reminder = @user.reminders.create!(
      program: @program,
      days_of_week: [current_day],
      time: scheduled_time,
      timezone: "America/New_York"
    )

    # Run ReminderCheckJob
    assert_enqueued_with(job: SendPushNotificationJob, args: [reminder.id]) do
      ReminderCheckJob.perform_now
    end
  end

  # Test 4: Reminder not sent if scheduled time hasn't arrived in user's timezone
  test "notification not sent if scheduled time is in future for user timezone" do
    # Create reminder in Pacific timezone for future time
    pacific_time = Time.current.in_time_zone("America/Los_Angeles")
    current_day = pacific_time.strftime("%A").downcase

    # Set time to 1 hour in the future
    scheduled_time = (pacific_time + 1.hour).strftime("%H:%M")

    @user.reminders.create!(
      program: @program,
      days_of_week: [current_day],
      time: scheduled_time,
      timezone: "America/Los_Angeles"
    )

    # Run ReminderCheckJob
    assert_no_enqueued_jobs do
      ReminderCheckJob.perform_now
    end
  end

  # Test 5: Multiple subscriptions all receive notification
  test "notification sent to all user subscriptions" do
    # Create second subscription
    @user.push_subscriptions.create!(
      endpoint: "https://fcm.googleapis.com/fcm/send/test456",
      p256dh_key: "test_p256dh_key_2",
      auth_key: "test_auth_key_2"
    )

    # Track how many times WebPush is called
    call_count = 0
    WebPush.define_singleton_method(:payload_send) do |**args|
      call_count += 1
      nil
    end

    # Create and send reminder
    current_day = Time.current.strftime("%A").downcase
    reminder = @user.reminders.create!(
      program: @program,
      days_of_week: [current_day],
      time: 1.hour.ago,
      timezone: "UTC"
    )

    SendPushNotificationJob.perform_now(reminder.id)

    # Verify both subscriptions received notification
    assert_equal 2, call_count
  end

  # Test 6: Notification payload includes correct program URL
  test "notification payload includes correct program URL and title" do
    current_day = Time.current.strftime("%A").downcase
    reminder = @user.reminders.create!(
      program: @program,
      days_of_week: [current_day],
      time: 1.hour.ago,
      timezone: "UTC"
    )

    # Capture the payload sent to WebPush
    captured_payload = nil
    WebPush.define_singleton_method(:payload_send) do |**args|
      captured_payload = JSON.parse(args[:message])
      nil
    end

    SendPushNotificationJob.perform_now(reminder.id)

    # Verify payload structure
    assert_not_nil captured_payload
    assert_equal "Workout Reminder", captured_payload["title"]
    assert_includes captured_payload["body"], @program.title
    # Program IDs are UUIDs, so just check it contains /programs/
    assert_includes captured_payload["url"], "/programs/"
  end

  # Test 7: User can only access their own reminders via API
  test "user cannot access another user's reminders" do
    sign_in_as(@user)

    # Create reminder for another user
    other_user = users(:two)
    other_program = other_user.programs.create!(title: "Other Program")
    other_reminder = other_user.reminders.create!(
      program: other_program,
      days_of_week: ["monday"],
      time: "09:00",
      timezone: "America/New_York"
    )

    # Try to update other user's reminder
    patch reminder_path(other_reminder), params: {
      reminder: {enabled: false}
    }

    # Should be redirected with alert
    assert_redirected_to reminders_path
    follow_redirect!
    assert_equal "Reminder not found", flash[:alert]

    # Reminder should not be updated
    other_reminder.reload
    assert other_reminder.enabled
  end

  # Test 8: VAPID private key not exposed in HTML responses
  test "VAPID private key not exposed to client" do
    sign_in_as(@user)
    get reminders_path

    assert_response :success
    # Only check if ENV variable is set
    if ENV["VAPID_PRIVATE_KEY"].present?
      assert_not_includes response.body, ENV["VAPID_PRIVATE_KEY"]
    end
  end

  # Test 9: User cannot create reminder for program they don't own
  test "user cannot create reminder for program they do not own" do
    sign_in_as(@user)

    other_user = users(:two)
    other_program = other_user.programs.create!(title: "Other Program")

    assert_no_difference("Reminder.count") do
      post reminders_path, params: {
        reminder: {
          program_id: other_program.id,
          days_of_week: ["monday"],
          time: "09:00",
          timezone: "America/New_York"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # Test 10: Reminder not sent twice on same day
  test "reminder not sent twice on same day even if job runs multiple times" do
    current_day = Time.current.strftime("%A").downcase
    @user.reminders.create!(
      program: @program,
      days_of_week: [current_day],
      time: 1.hour.ago,
      timezone: "UTC",
      last_sent_at: Time.current  # Already sent today
    )

    # Run ReminderCheckJob
    assert_no_enqueued_jobs do
      ReminderCheckJob.perform_now
    end
  end
end
