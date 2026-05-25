class MakeTasksReminderAtNullable < ActiveRecord::Migration[7.2]
  def change
    change_column_default :tasks, :reminder_at, from: "2000-01-01 09:00:00", to: nil
    change_column_null :tasks, :reminder_at, true
  end
end
