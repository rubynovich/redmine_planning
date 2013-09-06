class CreateSubordinates < ActiveRecord::Migration
  def change

    create_table :subordinates do |t|
      t.integer :planning_manager_id
      t.integer :principal_id
    end

  end
end
