class CreatePlanningConfirmations < ActiveRecord::Migration
  def change
    create_table :planning_confirmations do |t|
      t.integer  :user_id
      t.integer  :issue_id
      t.datetime :date_start
      t.integer  :kgip_id
      t.integer  :head_id
      t.boolean  :kgip_confirmation
      t.boolean  :head_confirmation
    end
  end
end
