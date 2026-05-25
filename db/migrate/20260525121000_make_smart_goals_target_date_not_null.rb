class MakeSmartGoalsTargetDateNotNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :smart_goals, :target_date, false
  end
end
