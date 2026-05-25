class ChangeTasksReminderAtToDatetime < ActiveRecord::Migration[7.2]
  def up
    change_column_default :tasks, :reminder_at, nil
    change_column_null :tasks, :reminder_at, true

    change_column :tasks,
                  :reminder_at,
                  :datetime,
                  using: "CASE WHEN reminder_at IS NULL THEN NULL ELSE (CURRENT_DATE + reminder_at)::timestamp END"
  end

  def down
    change_column :tasks, :reminder_at, :time, using: "reminder_at::time"
    execute "UPDATE tasks SET reminder_at = '09:00:00' WHERE reminder_at IS NULL"
    change_column_null :tasks, :reminder_at, false
    change_column_default :tasks, :reminder_at, "09:00:00"
  end
end
