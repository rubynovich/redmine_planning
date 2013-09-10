class CopyWorkersToSubordinates < ActiveRecord::Migration

  def self.up

    for manager in PlanningManager.all
      next unless manager[:workers]
      workers = YAML.load(manager[:workers])
      for worker in workers
        Subordinate.create({:planning_manager_id => manager.id, :principal_id => worker}) if worker
      end
    end

  end

  def self.down

  end

end
