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

    desc 'rehead confirmation'
    task :rehead => :environment do
      PlanningConfirmation.all.each do |conf|
        if conf.user_id == conf.user.becomes(Person).department.try(:parent).try(:find_head).try(:id)
          conf.update_column(:head_id, conf.get_head_id) if conf.user_id.present?
        end
      end
    end

  end
end
