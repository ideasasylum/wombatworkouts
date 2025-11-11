class ReminderCheckJob < ApplicationJob
  queue_as :default

  def perform
    # Find all enabled reminders
    Reminder.enabled.find_each do |reminder|
      # Check if notification should be sent for this reminder
      if should_send_reminder?(reminder)
        SendPushNotificationJob.perform_later(reminder.id)
      end
    end
  end

  private

  def should_send_reminder?(reminder)
    # Get current time in user's timezone
    user_time = Time.current.in_time_zone(reminder.timezone)
    current_day = user_time.strftime("%A").downcase

    # Check if today is a scheduled day
    return false unless reminder.days_of_week.include?(current_day)

    # Build today's scheduled time in user's timezone
    scheduled_time = user_time.change(
      hour: reminder.time.hour,
      min: reminder.time.min,
      sec: 0
    )

    # Send if we're past scheduled time AND haven't sent today
    user_time >= scheduled_time &&
      (reminder.last_sent_at.nil? ||
       reminder.last_sent_at.in_time_zone(reminder.timezone).to_date < user_time.to_date)
  end
end
