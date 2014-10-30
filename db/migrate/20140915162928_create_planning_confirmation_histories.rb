class CreatePlanningConfirmationHistories < ActiveRecord::Migration
  def change
    create_table :planning_confirmation_histories do |t|
      t.references :planning_confirmation
      t.datetime :event_time
      t.references :user
      t.boolean :confirm_as_kgip
      t.boolean :confirm_as_head
      t.boolean :action #true - confirm, false - unconfirm
      t.boolean :as_deputy_employee
      t.integer :deputed_user_id
      t.float :current_week_hours
      t.float :current_issue_user_hours
      t.float :current_issue_hours
    end
  end
end
