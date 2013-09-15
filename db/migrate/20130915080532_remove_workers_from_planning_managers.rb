class RemoveWorkersFromPlanningManagers < ActiveRecord::Migration
  def up
    remove_column :planning_managers, :workers
  end

  def down
    add_column :planning_managers, :workers, :text
  end
end
