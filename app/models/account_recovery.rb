# == Schema Information
#
# Table name: account_recoveries
#
#  id         :integer          not null, primary key
#  code       :string           not null
#  expires_at :datetime         not null
#  used_at    :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
class AccountRecovery < ApplicationRecord
  belongs_to :user

  validates :code, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # Generate a random 6-digit code
  before_validation :generate_code, on: :create
  before_validation :set_expiration, on: :create

  # Scopes
  scope :active, -> { where("expires_at > ? AND used_at IS NULL", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :used, -> { where.not(used_at: nil) }

  def active?
    !expired? && !used?
  end

  def expired?
    expires_at <= Time.current
  end

  def used?
    used_at.present?
  end

  def mark_as_used!
    update!(used_at: Time.current)
  end

  private

  def generate_code
    # Generate 6-digit code
    self.code ||= SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
  end

  def set_expiration
    # Code expires in 15 minutes
    self.expires_at ||= 15.minutes.from_now
  end
end
