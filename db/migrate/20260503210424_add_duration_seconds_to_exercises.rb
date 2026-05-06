class AddDurationSecondsToExercises < ActiveRecord::Migration[8.1]
  def change
    add_column :exercises, :duration_seconds, :integer
    change_column_null :exercises, :reps, true
  end
end
