# == Schema Information
#
# Table name: library_exercises
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string           not null
#  video_url   :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer          not null
#
require "test_helper"

class LibraryExerciseTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "is valid with name" do
    library_exercise = @user.library_exercises.build(name: "Push-ups")
    assert library_exercise.valid?
  end

  test "requires a name" do
    library_exercise = @user.library_exercises.build(name: "")
    assert_not library_exercise.valid?
    assert_includes library_exercise.errors[:name], "can't be blank"
  end

  test "belongs to user" do
    library_exercise = @user.library_exercises.create!(name: "Squats")
    assert_equal @user, library_exercise.user
  end

  test "validates video_url format when present" do
    library_exercise = @user.library_exercises.build(name: "Burpees", video_url: "not-a-url")
    assert_not library_exercise.valid?
    assert_includes library_exercise.errors[:video_url], "must be a valid URL"
  end

  test "allows blank video_url" do
    library_exercise = @user.library_exercises.build(name: "Lunges", video_url: "")
    assert library_exercise.valid?
  end

  test "alphabetical scope orders case-insensitively" do
    @user.library_exercises.create!(name: "burpees")
    @user.library_exercises.create!(name: "Plank")
    @user.library_exercises.create!(name: "Air squats")

    names = @user.library_exercises.alphabetical.pluck(:name)
    assert_equal ["Air squats", "burpees", "Plank"], names
  end

  test "attributes_for_exercise excludes user_id, repeat_count, and timestamps" do
    library_exercise = @user.library_exercises.create!(name: "Dips", video_url: "https://example.com/v", description: "form notes")
    attrs = library_exercise.attributes_for_exercise
    assert_equal %w[name video_url description].sort, attrs.keys.sort
  end

  test "is destroyed when user is destroyed" do
    @user.library_exercises.create!(name: "Sit-ups")
    assert_difference -> { LibraryExercise.count }, -1 do
      @user.destroy
    end
  end
end
