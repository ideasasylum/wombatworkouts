# == Schema Information
#
# Table name: reminders
#
#  id           :integer          not null, primary key
#  days_of_week :text             not null
#  enabled      :boolean          default(TRUE), not null
#  last_sent_at :datetime
#  time         :time             not null
#  timezone     :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  program_id   :integer          not null
#  user_id      :integer          not null
#
class Reminder < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :program

  # Valid day names
  VALID_DAYS = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

  # Serialize days_of_week as JSON for SQLite compatibility
  serialize :days_of_week, coder: JSON

  # Scopes
  scope :enabled, -> { where(enabled: true) }

  # Validations
  validates :time, presence: true
  validates :timezone, presence: true
  validate :days_of_week_must_not_be_empty
  validate :days_of_week_must_include_valid_days
  validate :timezone_must_be_valid

  private

  def days_of_week_must_not_be_empty
    if days_of_week.blank? || (days_of_week.is_a?(Array) && days_of_week.empty?)
      errors.add(:days_of_week, "must include at least one day")
    end
  end

  def days_of_week_must_include_valid_days
    return if days_of_week.blank?
    return unless days_of_week.is_a?(Array)

    invalid_days = days_of_week - VALID_DAYS
    if invalid_days.any?
      errors.add(:days_of_week, "contains invalid day names")
    end
  end

  def timezone_must_be_valid
    return if timezone.blank?

    unless ActiveSupport::TimeZone[timezone]
      errors.add(:timezone, "is not a valid timezone")
    end
  end
end
