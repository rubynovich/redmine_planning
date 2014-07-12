class ChangeDateStartOnPlanningConfirmation < ActiveRecord::Migration
  def up
    change_column :planning_confirmations, :date_start, :date
  end

  def down
    change_column :planning_confirmations, :date_start, :datetime
  end
end
