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
      user_ids = []
      PlanningConfirmation.select("distinct user_id").map(&:user_id).uniq.each do |user_id|
        if user_id && (user_id == Person.find(user_id).department.try(:find_head).try(:id))
          user_ids << user_id
        end
      end

      user_ids.each do |user_id|
        new_head_id = PlanningConfirmation.get_head_id(user_id)
        PlanningConfirmation.where(user_id: user_id).update_all(:head_id => new_head_id)
      end
    end

  end
end
