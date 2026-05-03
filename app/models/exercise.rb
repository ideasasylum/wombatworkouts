# == Schema Information
#
# Table name: exercises
#
#  id           :integer          not null, primary key
#  description  :text
#  name         :string           not null
#  position     :integer          not null
#  repeat_count :integer          not null
#  reps         :integer          default(10), not null
#  video_url    :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  program_id   :integer          not null
#
class Exercise < ApplicationRecord
  # Associations
  belongs_to :program

  # Validations
  validates :name, presence: true
  validates :repeat_count, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :reps, presence: true, numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: 1000}
  validates :position, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :video_url, format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL"}, allow_blank: true
end
