class CreateNotificationSchedules < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_schedules do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :kind, null: false
      t.time :local_time, null: false
      t.string :timezone, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :notification_schedules, %i[profile_id kind],
              unique: true,
              where: 'active = true',
              name: 'index_notification_schedules_active_kind'
  end
end
