class CreatePlanningPreferences < ActiveRecord::Migration
  def change
    create_table :planning_preferences do |t|
      t.integer :user_id
      t.text    :preferences
    end
  end
end
