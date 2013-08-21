class CreateAddWorkersToPlanningManagers < ActiveRecord::Migration
  def change
    add_column :planning_managers, :workers, :text
  end
end
