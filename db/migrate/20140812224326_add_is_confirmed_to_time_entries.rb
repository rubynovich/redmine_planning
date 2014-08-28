class AddIsConfirmedToTimeEntries < ActiveRecord::Migration
  def change
    add_column :time_entries, :is_confirmed, :boolean, default: false
  end
end
