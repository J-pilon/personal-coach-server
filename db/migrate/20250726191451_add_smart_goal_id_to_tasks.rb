# frozen_string_literal: true

class AddSmartGoalIdToTasks < ActiveRecord::Migration[7.1]
  def change
    add_reference :tasks, :smart_goal, null: true, foreign_key: true
  end
end
