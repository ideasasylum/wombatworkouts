class SendPushNotificationJob < ApplicationJob
  queue_as :default

  def perform(reminder_id)
    reminder = Reminder.find_by(id: reminder_id)
    return unless reminder

    program = reminder.program
    user = reminder.user

    # Fetch all push subscriptions for the user
    subscriptions = user.push_subscriptions

    return if subscriptions.empty?

    # Build notification payload
    message = JSON.generate({
      title: "Workout Reminder",
      body: "Time to work out! #{program.title}",
      url: Rails.application.routes.url_helpers.program_url(program, host: ENV.fetch("APP_HOST", "localhost:3000"))
    })

    # Send notification to each subscription
    subscriptions.each do |subscription|
      send_notification(subscription, message)
    end

    # Update last_sent_at timestamp
    reminder.update(last_sent_at: Time.current)
  end

  private

  def send_notification(subscription, message)
    WebPush.payload_send(
      message: message,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh_key,
      auth: subscription.auth_key,
      vapid: {
        subject: "mailto:admin@wombatworkouts.com",
        public_key: ENV["VAPID_PUBLIC_KEY"],
        private_key: ENV["VAPID_PRIVATE_KEY"]
      }
    )
  rescue WebPush::InvalidSubscription, WebPush::ExpiredSubscription => e
    # Remove invalid or expired subscriptions
    Rails.logger.info "Removing invalid push subscription: #{subscription.id} - #{e.message}"
    subscription.destroy
  rescue => e
    # Log other errors but don't fail the job
    Rails.logger.error "Failed to send push notification: #{e.message}"
  end
end
