namespace :redmine do
  namespace :plugins do
    desc 'Create old planning confirmations'
    task :create_old_planning_confirmations => :environment do
      Person.active.each do |person|
        if TimeEntry.where(:user_id => person.id).any?
          res = PlanningConfirmation.create_or_change_planning(person)
          puts res.inspect unless res == 0
        end
      end
    end
  end
end
