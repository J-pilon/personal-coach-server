# frozen_string_literal: true

# Migration to add Devise columns to existing users table
class AddDeviseToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users do |t|
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
    end

    add_index :users, :reset_password_token, unique: true
  end
end
