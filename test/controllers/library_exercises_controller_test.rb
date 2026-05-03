require "test_helper"

class LibraryExercisesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @library_exercise = @user.library_exercises.create!(name: "Push-ups", video_url: "https://example.com/v")
  end

  test "index requires authentication" do
    get library_exercises_path
    assert_redirected_to signin_path
  end

  test "edit requires authentication" do
    get edit_library_exercise_path(@library_exercise)
    assert_redirected_to signin_path
  end

  test "update requires authentication" do
    patch library_exercise_path(@library_exercise), params: {library_exercise: {name: "New"}}
    assert_redirected_to signin_path
  end

  test "destroy requires authentication" do
    delete library_exercise_path(@library_exercise)
    assert_redirected_to signin_path
  end

  test "index only returns current user's library exercises" do
    sign_in_as(@user)
    @other_user.library_exercises.create!(name: "Their secret exercise")

    get library_exercises_path
    assert_response :success
    assert_select "h3", text: "Push-ups"
    assert_select "h3", text: "Their secret exercise", count: 0
  end

  test "edit cannot access another user's library exercise" do
    sign_in_as(@user)
    other_library_exercise = @other_user.library_exercises.create!(name: "Other")

    get edit_library_exercise_path(other_library_exercise)
    assert_response :not_found
  end

  test "update modifies the library exercise" do
    sign_in_as(@user)
    patch library_exercise_path(@library_exercise), params: {library_exercise: {name: "Updated name"}}
    assert_redirected_to library_exercises_path
    assert_equal "Updated name", @library_exercise.reload.name
  end

  test "update rejects invalid params" do
    sign_in_as(@user)
    patch library_exercise_path(@library_exercise), params: {library_exercise: {name: ""}}
    assert_response :unprocessable_entity
    assert_equal "Push-ups", @library_exercise.reload.name
  end

  test "destroy removes the library exercise" do
    sign_in_as(@user)
    assert_difference -> { @user.library_exercises.count }, -1 do
      delete library_exercise_path(@library_exercise)
    end
    assert_redirected_to library_exercises_path
  end

  test "destroy cannot remove another user's library exercise" do
    sign_in_as(@user)
    other_library_exercise = @other_user.library_exercises.create!(name: "Other")
    delete library_exercise_path(other_library_exercise)
    assert_response :not_found
    assert LibraryExercise.exists?(other_library_exercise.id)
  end
end
