class CreateReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :reminders do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}, index: true
      t.references :program, null: false, foreign_key: {on_delete: :cascade}, index: true
      t.text :days_of_week, null: false  # JSON text column for SQLite compatibility
      t.time :time, null: false
      t.string :timezone, null: false
      t.boolean :enabled, default: true, null: false, index: true

      t.timestamps
    end
  end
end
