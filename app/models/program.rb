# == Schema Information
#
# Table name: programs
#
#  id          :integer          not null, primary key
#  description :text
#  title       :string           not null
#  uuid        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer          not null
#
class Program < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :exercises, -> { order(position: :asc) }, dependent: :destroy
  has_many :workouts, dependent: :nullify  # Workouts persist as snapshots even if program is deleted
  has_many :reminders, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :title, length: {maximum: 200}

  # Callbacks
  before_create :generate_uuid

  # Use UUID for URLs instead of ID
  def to_param
    uuid
  end

  # Task Group 1.2: Duplicate program with all exercises
  # Creates a deep copy of the program and all its exercises
  # Returns the newly created program instance
  def duplicate(new_user_id)
    ActiveRecord::Base.transaction do
      # Create new program with copied attributes
      duplicated_program = Program.new(
        title: title,
        description: description,
        user_id: new_user_id
      )
      duplicated_program.save!

      # Deep copy all exercises maintaining position order
      exercises.order(:position).each do |exercise|
        duplicated_program.exercises.create!(
          name: exercise.name,
          repeat_count: exercise.repeat_count,
          description: exercise.description,
          video_url: exercise.video_url,
          position: exercise.position
        )
      end

      duplicated_program
    end
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
