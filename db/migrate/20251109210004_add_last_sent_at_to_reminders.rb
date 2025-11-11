class AddLastSentAtToReminders < ActiveRecord::Migration[8.1]
  def change
    add_column :reminders, :last_sent_at, :datetime
  end
end
