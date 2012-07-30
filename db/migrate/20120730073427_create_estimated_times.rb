class CreateEstimatedTimes < ActiveRecord::Migration
  def self.up
    create_table :estimated_times do |t|
      t.column :project_id, :integer, :null => false
      t.column :issue_id, :integer
      t.column :user_id, :integer, :null => false
      t.column :hours, :float, :null => false
      t.column :comments, :string
      t.column :plan_on, :date, :null => false
      t.column :tyear, :integer, :null => false
      t.column :tmonth, :integer, :null => false
      t.column :tweek, :integer, :null => false
      t.column :created_on, :datetime, :null => false
      t.column :updated_on, :datetime, :null => false
    end
  end

  def self.down
    drop_table :estimated_times
  end
end
