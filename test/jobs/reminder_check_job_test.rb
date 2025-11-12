require "test_helper"

class ReminderCheckJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @program = @user.programs.create!(title: "Test Program")
  end

  test "enqueues notification for enabled reminder with current day and past scheduled time" do
    # Create reminder for current day
    current_day = Time.current.strftime("%A").downcase
    reminder = @user.reminders.create!(
      program: @program,
      days_of_week: [current_day],
      time: 30.minutes.ago,  # Past the scheduled time but within 1 hour window
      timezone: "UTC",
      enabled: true
    )

    assert_enqueued_with(job: SendPushNotificationJob, args: [reminder.id]) do
      ReminderCheckJob.perform_now
    end
  end

  test "does not enqueue notification for disabled reminder" do
    current_day = Time.current.strftime("%A").downcase
    @user.reminders.create!(
      program: @program,
      days_of_week: [current_day],
      time: 30.minutes.ago,
      timezone: "UTC",
      enabled: false
    )

    assert_no_enqueued_jobs do
      ReminderCheckJob.perform_now
    end
  end

  test "does not enqueue notification for reminder already sent today" do
    current_day = Time.current.strftime("%A").downcase
    @user.reminders.create!(
      program: @program,
      days_of_week: [current_day],
      time: 30.minutes.ago,
      timezone: "UTC",
      enabled: true,
      last_sent_at: Time.current  # Already sent today
    )

    assert_no_enqueued_jobs do
      ReminderCheckJob.perform_now
    end
  end

  test "does not enqueue notification for reminder with wrong day" do
    # Get tomorrow's day
    tomorrow_day = (Time.current + 1.day).strftime("%A").downcase
    @user.reminders.create!(
      program: @program,
      days_of_week: [tomorrow_day],
      time: 30.minutes.ago,
      timezone: "UTC",
      enabled: true
    )

    assert_no_enqueued_jobs do
      ReminderCheckJob.perform_now
    end
  end
end
