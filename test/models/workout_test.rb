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
require "test_helper"

class WorkoutTest < ActiveSupport::TestCase
  # Test 1: Exercise unrolling expands repeat_count into individual instances
  test "initialize_from_program unrolls exercises with repeat_count" do
    user = users(:john)
    program = programs(:strength_program)

    # Create exercises with different repeat counts
    program.exercises.destroy_all
    program.exercises.create!(name: "Push-ups", repeat_count: 3, position: 1, video_url: "https://youtube.com/pushups")
    program.exercises.create!(name: "Squats", repeat_count: 2, position: 2, video_url: "https://youtube.com/squats")

    workout = Workout.new(user: user, program: program)
    workout.initialize_from_program(program)

    # Should have 5 total exercise instances (3 + 2)
    assert_equal 5, workout.exercises_data.length

    # First exercise should be unrolled into 3 instances
    assert_equal "Push-ups", workout.exercises_data[0]["name"]
    assert_equal 1, workout.exercises_data[0]["repeat_instance"]
    assert_equal 3, workout.exercises_data[0]["repeat_total"]

    assert_equal "Push-ups", workout.exercises_data[1]["name"]
    assert_equal 2, workout.exercises_data[1]["repeat_instance"]
    assert_equal 3, workout.exercises_data[1]["repeat_total"]

    assert_equal "Push-ups", workout.exercises_data[2]["name"]
    assert_equal 3, workout.exercises_data[2]["repeat_instance"]
    assert_equal 3, workout.exercises_data[2]["repeat_total"]

    # Second exercise should be unrolled into 2 instances
    assert_equal "Squats", workout.exercises_data[3]["name"]
    assert_equal 1, workout.exercises_data[3]["repeat_instance"]
    assert_equal 2, workout.exercises_data[3]["repeat_total"]

    assert_equal "Squats", workout.exercises_data[4]["name"]
    assert_equal 2, workout.exercises_data[4]["repeat_instance"]
    assert_equal 2, workout.exercises_data[4]["repeat_total"]

    # All should start incomplete and not skipped
    workout.exercises_data.each do |exercise|
      assert_equal false, exercise["completed"]
      assert_equal false, exercise["skipped"]
      assert exercise["id"].present? # Should have unique ID
    end

    # Should set program_title
    assert_equal program.title, workout.program_title
  end

  test "initialize_from_program snapshots reps and duration_seconds" do
    user = users(:john)
    program = programs(:strength_program)
    program.exercises.destroy_all
    program.exercises.create!(name: "Push-ups", repeat_count: 2, position: 1, reps: 12)
    program.exercises.create!(name: "Plank", repeat_count: 2, position: 2, reps: nil, duration_seconds: 45)

    workout = Workout.new(user: user, program: program)
    workout.initialize_from_program(program)

    pushups = workout.exercises_data.first
    plank = workout.exercises_data.last
    assert_equal 12, pushups["reps"]
    assert_nil pushups["duration_seconds"]
    assert_nil plank["reps"]
    assert_equal 45, plank["duration_seconds"]
  end

  # Test 2: Finding current incomplete exercise
  test "current_exercise returns first incomplete exercise" do
    user = users(:john)
    program = programs(:strength_program)
    workout = Workout.new(user: user, program: program)
    workout.initialize_from_program(program)
    workout.save!

    # First exercise should be current
    current = workout.current_exercise
    assert_not_nil current
    assert_equal workout.exercises_data[0]["id"], current["id"]

    # Mark first complete
    workout.mark_exercise_complete(current["id"])

    # Second exercise should now be current
    current = workout.current_exercise
    assert_equal workout.exercises_data[1]["id"], current["id"]
  end

  # Test 3: Marking exercise complete and auto-advancing
  test "mark_exercise_complete sets completed flag and sets started_at" do
    user = users(:john)
    program = programs(:strength_program)
    workout = Workout.new(user: user, program: program)
    workout.initialize_from_program(program)
    workout.save!

    exercise_id = workout.exercises_data[0]["id"]
    assert_nil workout.started_at

    workout.mark_exercise_complete(exercise_id)
    workout.reload

    # Should set started_at timestamp
    assert_not_nil workout.started_at

    # Exercise should be marked complete
    completed_exercise = workout.exercises_data.find { |e| e["id"] == exercise_id }
    assert_equal true, completed_exercise["completed"]
    assert_equal false, completed_exercise["skipped"]
  end

  # Test 4: Completion detection when all exercises done
  test "complete? returns true when all exercises completed or skipped" do
    user = users(:john)
    program = programs(:strength_program)
    workout = Workout.new(user: user, program: program)
    workout.initialize_from_program(program)
    workout.save!

    assert_equal false, workout.complete?

    # Mark all exercises as complete or skipped
    workout.exercises_data.each_with_index do |exercise, index|
      if index.even?
        workout.mark_exercise_complete(exercise["id"])
      else
        workout.skip_exercise(exercise["id"])
      end
    end

    workout.reload
    assert_equal true, workout.complete?
    assert_not_nil workout.completed_at
  end

  # Test 5: Skip functionality
  test "skip_exercise marks exercise as skipped and advances" do
    user = users(:john)
    program = programs(:strength_program)
    workout = Workout.new(user: user, program: program)
    workout.initialize_from_program(program)
    workout.save!

    exercise_id = workout.exercises_data[0]["id"]
    workout.skip_exercise(exercise_id)
    workout.reload

    # Exercise should be marked skipped
    skipped_exercise = workout.exercises_data.find { |e| e["id"] == exercise_id }
    assert_equal false, skipped_exercise["completed"]
    assert_equal true, skipped_exercise["skipped"]

    # Current exercise should now be the second one
    current = workout.current_exercise
    assert_equal workout.exercises_data[1]["id"], current["id"]
  end

  # Test 6: Completion stats
  test "completion_stats returns accurate counts" do
    user = users(:john)
    program = programs(:strength_program)
    workout = Workout.new(user: user, program: program)
    workout.initialize_from_program(program)
    workout.save!

    # Mark some complete and some skipped
    workout.mark_exercise_complete(workout.exercises_data[0]["id"])
    workout.mark_exercise_complete(workout.exercises_data[1]["id"])
    workout.skip_exercise(workout.exercises_data[2]["id"])

    stats = workout.completion_stats
    assert_equal 2, stats[:completed_count]
    assert_equal 1, stats[:skipped_count]
    assert_equal workout.exercises_data.length, stats[:total_count]
  end
end
