class AddPrimaryAndWhyToSmartGoals < ActiveRecord::Migration[7.2]
  def change
    add_column :smart_goals, :primary, :boolean, default: false, null: false
    add_column :smart_goals, :why, :text

    add_index :smart_goals, :profile_id,
              unique: true,
              where: '"primary" = true AND completed = false',
              name: 'index_smart_goals_one_primary_uncompleted_per_profile'
  end
end
