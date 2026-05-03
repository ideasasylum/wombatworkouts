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
require "test_helper"

class ExerciseTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @program = @user.programs.create!(title: "Test Program")
  end

  test "should be valid with required attributes" do
    exercise = @program.exercises.build(name: "Push-ups", repeat_count: 10, position: 1)
    assert exercise.valid?
  end

  test "should belong to program" do
    exercise = @program.exercises.create!(name: "Squats", repeat_count: 15, position: 1)
    assert_equal @program, exercise.program
  end

  test "should require name" do
    exercise = @program.exercises.build(repeat_count: 10, position: 1)
    assert_not exercise.valid?
    assert_includes exercise.errors[:name], "can't be blank"
  end

  test "should require repeat_count" do
    exercise = @program.exercises.build(name: "Lunges", position: 1)
    assert_not exercise.valid?
    assert_includes exercise.errors[:repeat_count], "can't be blank"
  end

  test "should require repeat_count to be a positive integer" do
    exercise = @program.exercises.build(name: "Plank", repeat_count: 0, position: 1)
    assert_not exercise.valid?
    assert_includes exercise.errors[:repeat_count], "must be greater than 0"
  end

  test "should validate video_url format when present" do
    exercise = @program.exercises.build(name: "Burpees", repeat_count: 20, position: 1, video_url: "not-a-url")
    assert_not exercise.valid?
    assert_includes exercise.errors[:video_url], "must be a valid URL"
  end

  test "should allow blank video_url" do
    exercise = @program.exercises.build(name: "Jumping Jacks", repeat_count: 30, position: 1, video_url: "")
    assert exercise.valid?
  end

  test "should allow valid video_url" do
    exercise = @program.exercises.build(name: "Mountain Climbers", repeat_count: 25, position: 1, video_url: "https://example.com/video")
    assert exercise.valid?
  end

  test "should have markdown description" do
    exercise = @program.exercises.create!(name: "Sit-ups", repeat_count: 50, position: 1, description: "Focus on form and breathing")
    assert_equal "Focus on form and breathing", exercise.description
  end

  test "is valid with duration_seconds and no reps" do
    exercise = @program.exercises.build(name: "Plank", repeat_count: 3, position: 1, reps: nil, duration_seconds: 45)
    assert exercise.valid?, exercise.errors.full_messages.to_sentence
  end

  test "rejects both reps and duration_seconds" do
    exercise = @program.exercises.build(name: "Plank", repeat_count: 3, position: 1, reps: 10, duration_seconds: 30)
    assert_not exercise.valid?
    assert_includes exercise.errors[:base], "cannot set both reps and duration"
  end

  test "rejects neither reps nor duration_seconds" do
    exercise = @program.exercises.build(name: "Plank", repeat_count: 3, position: 1, reps: nil, duration_seconds: nil)
    assert_not exercise.valid?
    assert_includes exercise.errors[:base], "must set either reps or duration"
  end

  test "duration_seconds upper bound" do
    exercise = @program.exercises.build(name: "Plank", repeat_count: 1, position: 1, reps: nil, duration_seconds: Exercise::MAX_DURATION_SECONDS + 1)
    assert_not exercise.valid?
    assert exercise.errors[:duration_seconds].any?
  end

  test "effort_label for reps" do
    assert_equal "1 rep", @program.exercises.build(reps: 1).effort_label
    assert_equal "10 reps", @program.exercises.build(reps: 10).effort_label
  end

  test "effort_label for durations" do
    assert_equal "45s", @program.exercises.build(reps: nil, duration_seconds: 45).effort_label
    assert_equal "1m 30s", @program.exercises.build(reps: nil, duration_seconds: 90).effort_label
    assert_equal "2m", @program.exercises.build(reps: nil, duration_seconds: 120).effort_label
  end
end
