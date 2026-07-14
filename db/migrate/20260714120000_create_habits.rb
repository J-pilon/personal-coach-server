class CreateHabits < ActiveRecord::Migration[7.2]
  def change
    create_table :habits do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :smart_goal, null: false, foreign_key: true
      t.string :title, null: false
      t.string :frequency, null: false
      t.jsonb :frequency_config, default: {}, null: false
      t.string :cue, null: false
      t.string :minimum_version, null: false
      t.string :normal_version, null: false
      t.integer :position, null: false
      t.datetime :archived_at

      t.timestamps
    end

    add_index :habits, %i[smart_goal_id position],
              unique: true,
              where: 'archived_at IS NULL',
              name: 'index_habits_on_goal_position_active'
  end
end
