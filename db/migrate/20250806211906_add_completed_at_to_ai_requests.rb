class AddCompletedAtToAiRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :ai_requests, :completed_at, :datetime
  end
end
