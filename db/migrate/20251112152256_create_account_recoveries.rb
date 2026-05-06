class CreateAccountRecoveries < ActiveRecord::Migration[8.1]
  def change
    create_table :account_recoveries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :account_recoveries, :code, unique: true
  end
end
