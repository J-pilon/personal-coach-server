class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.string :source, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :tickets, :kind
    add_index :tickets, :created_at
  end
end
