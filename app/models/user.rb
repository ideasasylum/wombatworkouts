# == Schema Information
#
# Table name: users
#
#  id          :integer          not null, primary key
#  email       :string           not null
#  timezone    :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  webauthn_id :string           not null
#
class User < ApplicationRecord
  # Associations
  has_many :credentials, dependent: :destroy
  has_many :programs, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :reminders, dependent: :destroy
  has_many :account_recoveries, dependent: :destroy

  # Normalization (Rails 7.1+)
  normalizes :email, with: ->(email) { email.strip.downcase }

  # Validations
  validates :email, presence: true
  validates :email, uniqueness: {case_sensitive: false}
  validates :email, format: {with: /\A[^@\s]+@[^@\s]+\z/, message: "must be a valid email address"}
  validate :timezone_must_be_valid, if: :timezone?

  # Callbacks
  before_create :generate_webauthn_id

  private

  def generate_webauthn_id
    self.webauthn_id = SecureRandom.hex(16)
  end

  def timezone_must_be_valid
    return if timezone.blank?

    unless ActiveSupport::TimeZone[timezone]
      errors.add(:timezone, "is not a valid timezone")
    end
  end
end
