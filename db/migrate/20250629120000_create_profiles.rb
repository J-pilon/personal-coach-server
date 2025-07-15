class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.string :first_name
      t.string :last_name
      t.string :work_role
      t.string :education
      t.text :desires
      t.text :limiting_beliefs
      t.string :onboarding_status, default: 'incomplete'
      t.datetime :onboarding_completed_at
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
