# frozen_string_literal: true

class AddReminderAtToTasks < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :reminder_at, :time, null: false, default: '09:00:00'
  end
end
