class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}, index: true
      t.text :endpoint, null: false
      t.text :p256dh_key, null: false
      t.text :auth_key, null: false

      t.timestamps
    end
  end
end
