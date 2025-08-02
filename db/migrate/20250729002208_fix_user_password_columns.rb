# frozen_string_literal: true

# Migration to fix user password columns for Devise compatibility
class FixUserPasswordColumns < ActiveRecord::Migration[7.1]
  def change
    # Rename password_digest to encrypted_password for Devise compatibility
    rename_column :users, :password_digest, :encrypted_password

    # Make encrypted_password nullable since Devise will handle it
    change_column_null :users, :encrypted_password, true
  end
end
