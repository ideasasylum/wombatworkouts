class ChangeRepsDefaultOnExercises < ActiveRecord::Migration[8.1]
  def change
    change_column_default :exercises, :reps, from: 10, to: 1
  end
end
