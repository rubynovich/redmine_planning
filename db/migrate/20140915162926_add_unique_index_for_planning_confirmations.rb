class AddUniqueIndexForPlanningConfirmations < ActiveRecord::Migration
  def up
    add_index :planning_confirmations, [:user_id, :issue_id, :date_start], unique: true
  end

  def down
    remove_index :planning_confirmations, [:user_id, :issue_id, :date_start]
  end
end
