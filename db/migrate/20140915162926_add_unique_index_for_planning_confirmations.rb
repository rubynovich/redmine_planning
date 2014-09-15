class AddUniqueIndexForPlanningConfirmations < ActiveRecord::Migration
  def up
    add_index :planning_confirmations, [:user_id, :issue_id, :date_start], unique: true, name: 'index_planning_confirmations_unique'
  end

  def down
    remove_index :planning_confirmations, :name => 'index_planning_confirmations_unique'
  end
end
