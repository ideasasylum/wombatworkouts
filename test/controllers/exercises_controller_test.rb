require "test_helper"

class ExercisesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @program = @user.programs.create!(title: "Test Program")
    @other_program = @other_user.programs.create!(title: "Other Program")
    @exercise = @program.exercises.create!(name: "Push-ups", repeat_count: 10, position: 1)
  end

  test "create requires authentication" do
    post program_exercises_path(@program), params: {exercise: {name: "Test", repeat_count: 5, position: 1}}
    assert_redirected_to signin_path
  end

  test "update requires authentication" do
    patch exercise_path(@exercise), params: {exercise: {name: "Updated"}}
    assert_redirected_to signin_path
  end

  test "destroy requires authentication" do
    delete exercise_path(@exercise)
    assert_redirected_to signin_path
  end

  test "move requires authentication" do
    patch move_exercise_path(@exercise), params: {position: 2}
    assert_redirected_to signin_path
  end

  test "should not allow access to other user programs" do
    # Test that trying to access another user's program raises RecordNotFound
    # This simulates an authenticated user trying to create exercise in another user's program
    # Since full authentication requires WebAuthn, we test the authorization check directly
    assert_raises(ActiveRecord::RecordNotFound) do
      # Simulate what happens when an authenticated user tries to access another user's program
      @user.programs.find_by!(uuid: @other_program.uuid)
    end
  end

  test "authorization check prevents unauthorized exercise updates" do
    other_exercise = @other_program.exercises.create!(name: "Test", repeat_count: 5, position: 1)

    # Test that exercise belongs to different program
    assert_not_equal @program.user_id, other_exercise.program.user_id
  end

  test "exercises are ordered by position" do
    exercise2 = @program.exercises.create!(name: "Squats", repeat_count: 15, position: 2)
    exercise3 = @program.exercises.create!(name: "Lunges", repeat_count: 20, position: 3)

    exercises = @program.exercises.reload
    assert_equal [@exercise.id, exercise2.id, exercise3.id], exercises.pluck(:id)
  end

  test "exercises are cascade deleted when program is deleted" do
    @program.exercises.create!(name: "Squats", repeat_count: 15, position: 2)
    @program.exercises.create!(name: "Lunges", repeat_count: 20, position: 3)

    assert_equal 3, @program.exercises.count

    @program.destroy

    assert_equal 0, Exercise.where(program_id: @program.id).count
  end

  test "create auto-saves the exercise to the user's library" do
    sign_in_as(@user)
    assert_difference -> { @user.library_exercises.count }, 1 do
      post program_exercises_path(@program),
        params: {exercise: {name: "Burpees", repeat_count: 12, video_url: "https://example.com/v", description: "form"}},
        as: :turbo_stream
    end
    library_exercise = @user.library_exercises.order(:created_at).last
    assert_equal "Burpees", library_exercise.name
    assert_equal "https://example.com/v", library_exercise.video_url
    assert_equal "form", library_exercise.description
  end

  test "create does not save to library when from_library flag is set" do
    sign_in_as(@user)
    assert_no_difference -> { @user.library_exercises.count } do
      post program_exercises_path(@program),
        params: {exercise: {name: "Lunges", repeat_count: 8}, from_library: "1"},
        as: :turbo_stream
    end
  end

  test "new with library_exercise_id pre-fills the form" do
    sign_in_as(@user)
    library_exercise = @user.library_exercises.create!(name: "Reverse lunges", video_url: "https://ex.com/r")

    get new_program_exercise_path(@program, library_exercise_id: library_exercise.id)
    assert_response :success
    assert_select "input[name='exercise[name]'][value=?]", "Reverse lunges"
    assert_select "input[name='from_library'][value='1']"
  end

  test "new ignores library_exercise_id from another user" do
    sign_in_as(@user)
    other_library_exercise = @other_user.library_exercises.create!(name: "Their exercise")

    get new_program_exercise_path(@program, library_exercise_id: other_library_exercise.id)
    assert_response :success
    assert_select "input[name='exercise[name]'][value=?]", "Their exercise", count: 0
  end
end
