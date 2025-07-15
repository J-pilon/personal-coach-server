class CreateTasks < ActiveRecord::Migration[6.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.boolean :completed, default: false
      t.integer :action_category, null: false
      t.references :profile, null: false, foreign_key: true

      t.timestamps
    end
  end
end
