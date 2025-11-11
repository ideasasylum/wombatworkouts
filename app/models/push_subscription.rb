# == Schema Information
#
# Table name: push_subscriptions
#
#  id         :integer          not null, primary key
#  auth_key   :text             not null
#  endpoint   :text             not null
#  p256dh_key :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
class PushSubscription < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :endpoint, presence: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true
  validate :endpoint_must_be_https

  private

  def endpoint_must_be_https
    return if endpoint.blank?

    unless endpoint.start_with?("https://")
      errors.add(:endpoint, "must be an HTTPS URL")
    end
  end
end
