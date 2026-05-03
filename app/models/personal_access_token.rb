# == Schema Information
#
# Table name: personal_access_tokens
#
#  id           :integer          not null, primary key
#  last_used_at :datetime
#  name         :string           not null
#  revoked_at   :datetime
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer          not null
#
require "digest"

class PersonalAccessToken < ApplicationRecord
  TOKEN_PREFIX = "wwp_"
  TOKEN_BYTES = 32

  belongs_to :user

  attr_reader :token

  validates :name, presence: true, length: {maximum: 100}
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where(revoked_at: nil) }

  before_validation :generate_token, on: :create

  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    active.find_by(token_digest: digest_for(raw_token))
  end

  def self.digest_for(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked?
  end

  def touch_last_used!
    update_columns(last_used_at: Time.current)
  end

  private

  def generate_token
    return if token_digest.present?

    @token = TOKEN_PREFIX + SecureRandom.hex(TOKEN_BYTES)
    self.token_digest = self.class.digest_for(@token)
  end
end
