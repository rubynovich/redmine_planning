class CreateDeleteWorkersColumns < ActiveRecord::Migration
  def change
    remove_column :planning_managers, :workers
  end
end
