class CreateLibraryExercises < ActiveRecord::Migration[8.1]
  def change
    create_table :library_exercises do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :video_url
      t.text :description

      t.timestamps
    end
  end
end
