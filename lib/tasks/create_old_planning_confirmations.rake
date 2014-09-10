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

    desc 'reassign issues'
    task :reassign => :environment do
      settings = Setting[:plugin_redmine_planning]
      Issue.where(["issues.due_date >= ?",'2014-06-01'.to_date]).where(assigned_to_id: Group.all.map(&:id)).each do |issue|
        journal = issue.journals.joins(:details).where(["journal_details.prop_key = 'status_id' and journal_details.old_value = ? and journal_details.value = ?",settings[:new_issue_status].to_s, settings[:in_work_issue_status].to_s ]).first
        if journal.present?
          JournalDetail.skip_callback(:create)
          JournalDetail.create(journal_id: journal.id, property: 'attr', prop_key: 'assigned_to_id', old_value: issue.assigned_to_id, value: journal.user_id)
          JournalDetail.set_callback(:create)
          issue.update_column(:assigned_to_id, journal.user_id)
        end
      end
    end

  end
end
