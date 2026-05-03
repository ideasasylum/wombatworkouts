# == Schema Information
#
# Table name: exercises
#
#  id               :integer          not null, primary key
#  description      :text
#  duration_seconds :integer
#  name             :string           not null
#  position         :integer          not null
#  repeat_count     :integer          not null
#  reps             :integer          default(10)
#  video_url        :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  program_id       :integer          not null
#
class Exercise < ApplicationRecord
  MAX_DURATION_SECONDS = 86_400

  # Associations
  belongs_to :program

  # Validations
  validates :name, presence: true
  validates :repeat_count, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :reps, numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: 1000}, allow_nil: true
  validates :duration_seconds, numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_DURATION_SECONDS}, allow_nil: true
  validates :position, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :video_url, format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL"}, allow_blank: true
  validate :exactly_one_effort

  def duration?
    duration_seconds.present?
  end

  def effort_label
    if duration?
      format_duration(duration_seconds)
    else
      "#{reps} #{"rep".pluralize(reps)}"
    end
  end

  private

  def exactly_one_effort
    if reps.present? && duration_seconds.present?
      errors.add(:base, "cannot set both reps and duration")
    elsif reps.blank? && duration_seconds.blank?
      errors.add(:base, "must set either reps or duration")
    end
  end

  def format_duration(seconds)
    return "#{seconds}s" if seconds < 60
    minutes, secs = seconds.divmod(60)
    secs.zero? ? "#{minutes}m" : "#{minutes}m #{secs}s"
  end
end
