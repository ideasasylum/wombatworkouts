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
require "test_helper"

class ProgramTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should be valid with title and user" do
    program = @user.programs.build(title: "Upper Body Strength")
    assert program.valid?
  end

  test "should require title" do
    program = @user.programs.build(description: "Some description")
    assert_not program.valid?
    assert_includes program.errors[:title], "can't be blank"
  end

  test "should require title length maximum 200 characters" do
    program = @user.programs.build(title: "a" * 201)
    assert_not program.valid?
    assert_includes program.errors[:title], "is too long (maximum is 200 characters)"
  end

  test "should require user association" do
    program = Program.new(title: "Test Program")
    assert_not program.valid?
    assert_includes program.errors[:user], "must exist"
  end

  test "should generate UUID on create" do
    program = @user.programs.create(title: "Test Program")
    assert_not_nil program.uuid
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, program.uuid)
  end

  test "should belong to user" do
    program = @user.programs.create(title: "Test Program")
    assert_equal @user, program.user
  end

  # Task Group 1.1: Tests for Program#duplicate
  test "duplicate should create a new program with copied attributes" do
    original_program = programs(:strength_program)
    new_user = users(:two)

    duplicated_program = original_program.duplicate(new_user.id)

    assert_not_nil duplicated_program
    assert duplicated_program.persisted?
    assert_equal original_program.title, duplicated_program.title
    assert_equal original_program.description, duplicated_program.description
    assert_equal new_user.id, duplicated_program.user_id
    assert_not_equal original_program.id, duplicated_program.id
    assert_not_equal original_program.uuid, duplicated_program.uuid
  end

  test "duplicate should deep copy all exercises with correct positions" do
    original_program = programs(:strength_program)
    new_user = users(:two)

    duplicated_program = original_program.duplicate(new_user.id)

    assert_equal original_program.exercises.count, duplicated_program.exercises.count

    original_program.exercises.order(:position).each_with_index do |original_exercise, index|
      duplicated_exercise = duplicated_program.exercises.order(:position)[index]

      assert_equal original_exercise.name, duplicated_exercise.name
      assert_equal original_exercise.repeat_count, duplicated_exercise.repeat_count
      if original_exercise.description.nil?
        assert_nil duplicated_exercise.description
      else
        assert_equal original_exercise.description, duplicated_exercise.description
      end
      if original_exercise.video_url.nil?
        assert_nil duplicated_exercise.video_url
      else
        assert_equal original_exercise.video_url, duplicated_exercise.video_url
      end
      assert_equal original_exercise.position, duplicated_exercise.position
      assert_not_equal original_exercise.id, duplicated_exercise.id
      assert_equal duplicated_program.id, duplicated_exercise.program_id
    end
  end

  test "duplicate should generate new UUID for duplicated program" do
    original_program = programs(:strength_program)
    new_user = users(:two)

    duplicated_program = original_program.duplicate(new_user.id)

    assert_not_nil duplicated_program.uuid
    assert_not_equal original_program.uuid, duplicated_program.uuid
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, duplicated_program.uuid)
  end

  test "duplicate should assign new user_id" do
    original_program = programs(:strength_program)
    original_user = original_program.user
    new_user = users(:two)

    duplicated_program = original_program.duplicate(new_user.id)

    assert_equal new_user.id, duplicated_program.user_id
    assert_not_equal original_user.id, duplicated_program.user_id
  end

  test "duplicate should work with program that has no exercises" do
    original_program = programs(:cardio_program)
    # Ensure it has no exercises for this test
    original_program.exercises.destroy_all
    new_user = users(:two)

    duplicated_program = original_program.duplicate(new_user.id)

    assert_not_nil duplicated_program
    assert duplicated_program.persisted?
    assert_equal 0, duplicated_program.exercises.count
    assert_equal original_program.title, duplicated_program.title
    assert_equal new_user.id, duplicated_program.user_id
  end
end
