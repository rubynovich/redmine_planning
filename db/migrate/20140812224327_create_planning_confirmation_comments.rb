class CreatePlanningConfirmationComments < ActiveRecord::Migration
  def change
    create_table :planning_confirmation_comments do |t|
      t.references :planning_confirmation
      t.text :comment
      t.integer :user_id
      t.integer :confirmation_type #0 - kgip, 1 - head
      t.boolean :is_confirmation
      t.timestamps
    end
  end
end
