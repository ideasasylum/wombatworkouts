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

    # Check if we're past scheduled time
    return false unless user_time >= scheduled_time

    # Check if we've already sent today
    if reminder.last_sent_at.present?
      last_sent_date = reminder.last_sent_at.in_time_zone(reminder.timezone).to_date
      return false if last_sent_date >= user_time.to_date
    end

    # Only send if we're within 1 hour of scheduled time to avoid late notifications
    # This ensures reminders are timely even if job is delayed
    time_since_scheduled = user_time - scheduled_time
    return false if time_since_scheduled > 1.hour

    true
  end
end
