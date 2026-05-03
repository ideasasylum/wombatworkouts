# == Schema Information
#
# Table name: workouts
#
#  id             :integer          not null, primary key
#  completed_at   :datetime
#  exercises_data :text
#  program_title  :string
#  started_at     :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  program_id     :integer
#  user_id        :integer          not null
#
class Workout < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :program, optional: true  # Workouts persist even if program is deleted (historical snapshot)

  # Validations
  validates :user_id, presence: true
  validates :program_title, presence: true

  # JSON serialization for exercises_data
  # Each exercise instance contains: id (UUID), name, description, video_url,
  # reps, duration_seconds, position, repeat_instance, repeat_total,
  # completed (boolean), skipped (boolean)
  serialize :exercises_data, coder: JSON

  # Initialize workout from a program by snapshotting and unrolling exercises
  # Expands repeat_count into individual exercise instances
  def initialize_from_program(program)
    instances = []
    position = 0

    program.exercises.order(:position).each do |exercise|
      repeat_count = exercise.repeat_count || 1

      repeat_count.times do |repeat_index|
        position += 1
        instances << {
          "id" => SecureRandom.uuid,
          "name" => exercise.name,
          "description" => exercise.description,
          "video_url" => exercise.video_url,
          "reps" => exercise.reps,
          "duration_seconds" => exercise.duration_seconds,
          "position" => position,
          "repeat_instance" => repeat_index + 1,
          "repeat_total" => repeat_count,
          "completed" => false,
          "skipped" => false
        }
      end
    end

    self.exercises_data = instances
    self.program_title = program.title  # Store snapshot of program name
    self
  end

  # State query methods

  # Returns true if all exercises are completed or skipped
  def complete?
    return false if exercises_data.blank?
    exercises_data.all? { |exercise| exercise["completed"] || exercise["skipped"] }
  end

  # Returns true if workout has started but not completed
  def in_progress?
    started_at.present? && !complete?
  end

  # Returns hash with completion statistics
  def completion_stats
    return {completed_count: 0, skipped_count: 0, total_count: 0} if exercises_data.blank?

    {
      completed_count: exercises_data.count { |e| e["completed"] },
      skipped_count: exercises_data.count { |e| e["skipped"] },
      total_count: exercises_data.length
    }
  end

  # Exercise navigation methods

  # Returns the first exercise where completed=false and skipped=false
  def current_exercise
    return nil if exercises_data.blank?
    exercises_data.find { |exercise| !exercise["completed"] && !exercise["skipped"] }
  end

  # Returns the exercise after the current exercise
  def next_exercise
    current = current_exercise
    return nil if current.nil?

    current_index = exercises_data.index { |e| e["id"] == current["id"] }
    return nil if current_index.nil? || current_index >= exercises_data.length - 1

    exercises_data[current_index + 1..]&.find { |exercise| !exercise["completed"] && !exercise["skipped"] }
  end

  # Find exercise instance by UUID
  def find_exercise(exercise_id)
    return nil if exercises_data.blank?
    exercises_data.find { |exercise| exercise["id"] == exercise_id }
  end

  # Find exercise instance by array index
  def find_exercise_by_index(index)
    return nil if exercises_data.blank?
    return nil if index < 0 || index >= exercises_data.length
    exercises_data[index]
  end

  # Exercise action methods

  # Marks exercise as complete, sets started_at if first action, sets completed_at if last
  def mark_exercise_complete(exercise_id)
    exercise = find_exercise(exercise_id)
    return false if exercise.nil?

    exercise["completed"] = true
    exercise["skipped"] = false

    # Set started_at timestamp if this is the first action
    self.started_at ||= Time.current

    # Set completed_at if all exercises are now done
    self.completed_at = Time.current if complete?

    save
  end

  # Marks exercise as skipped, sets started_at if first action, sets completed_at if last
  def skip_exercise(exercise_id)
    exercise = find_exercise(exercise_id)
    return false if exercise.nil?

    exercise["skipped"] = true
    exercise["completed"] = false

    # Set started_at timestamp if this is the first action
    self.started_at ||= Time.current

    # Set completed_at if all exercises are now done
    self.completed_at = Time.current if complete?

    save
  end
end
