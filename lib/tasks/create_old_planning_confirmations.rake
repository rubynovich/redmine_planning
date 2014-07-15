namespace :redmine do
  namespace :plugins do
    desc 'Create old planning confirmations'
    task :create_old_planning_confirmations => :environment do
      Person.active.each do |person|
        if TimeEntry.where(:user_id => person.id).any?
          puts PlanningConfirmation.create_or_change_planning(person).inspect
        end
      end
    end
  end
end
