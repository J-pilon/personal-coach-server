class CreateTasks < ActiveRecord::Migration[6.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.boolean :completed, default: false
      t.integer :action_category, null: false

      # come back to this file. Think about what the name should be for eisenhower labels

      t.timestamps
    end
  end
end
