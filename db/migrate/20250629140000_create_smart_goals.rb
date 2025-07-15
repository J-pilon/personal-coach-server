class CreateSmartGoals < ActiveRecord::Migration[7.1]
  def change
    create_table :smart_goals do |t|
      t.string :title, null: false
      t.text :description
      t.string :timeframe, null: false
      t.text :specific
      t.text :measurable
      t.text :achievable
      t.text :relevant
      t.text :time_bound
      t.boolean :completed, default: false
      t.references :profile, null: false, foreign_key: true
      t.datetime :target_date

      t.timestamps
    end
  end
end
