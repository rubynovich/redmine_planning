class CreatePlanningManagers < ActiveRecord::Migration
  def self.up
    create_table :planning_managers do |t|
      t.column :user_id, :integer
      t.column :workers, :text
    end
  end

  def self.down
    drop_table :planning_managers
  end
end
