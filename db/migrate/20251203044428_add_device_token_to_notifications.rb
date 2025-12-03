class AddDeviceTokenToNotifications < ActiveRecord::Migration[7.2]
  def change
    add_reference :notifications, :device_token, null: true, foreign_key: true
  end
end
