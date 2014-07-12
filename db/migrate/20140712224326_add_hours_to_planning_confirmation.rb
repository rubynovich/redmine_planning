class AddHoursToPlanningConfirmation < ActiveRecord::Migration
  def change
    add_column :planning_confirmations, :hours, :float, default: 0.0
  end
end
