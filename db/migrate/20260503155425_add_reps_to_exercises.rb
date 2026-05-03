class AddRepsToExercises < ActiveRecord::Migration[8.1]
  def change
    add_column :exercises, :reps, :integer, null: false, default: 10
  end
end
