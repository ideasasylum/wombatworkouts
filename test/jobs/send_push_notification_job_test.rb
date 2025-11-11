require "test_helper"

class SendPushNotificationJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @program = @user.programs.create!(title: "Test Program")
    @reminder = @user.reminders.create!(
      program: @program,
      days_of_week: ["monday"],
      time: Time.parse("07:00"),
      timezone: "America/New_York"
    )
    @subscription = @user.push_subscriptions.create!(
      endpoint: "https://fcm.googleapis.com/fcm/send/test",
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

  test "updates reminder last_sent_at after sending notification" do
    assert_nil @reminder.last_sent_at

    SendPushNotificationJob.perform_now(@reminder.id)

    @reminder.reload
    assert_not_nil @reminder.last_sent_at
    assert_in_delta Time.current, @reminder.last_sent_at, 5.seconds
  end

  test "job runs without error when reminder has subscriptions" do
    assert_nothing_raised do
      SendPushNotificationJob.perform_now(@reminder.id)
    end
  end

  test "job runs without error when reminder has no subscriptions" do
    @subscription.destroy

    assert_nothing_raised do
      SendPushNotificationJob.perform_now(@reminder.id)
    end
  end

  test "job handles invalid reminder gracefully" do
    assert_nothing_raised do
      SendPushNotificationJob.perform_now(999999)
    end
  end
end
