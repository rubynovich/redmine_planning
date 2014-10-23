namespace :redmine do
  namespace :plugins do

    task :fix_kgip_confirmations => :environment do
      Project.where(is_external: true, status: 1).each do |project|
        PlanningConfirmation.joins(:issue).kgip_not_confirmed.where(["issues.project_id = ?", project.id]).update_all(:kgip_id => project.kgips.last)
      end
    end

    task :fix_heads_confirmations => :environment do
      User.active.each do |user|
        PlanningConfirmation.head_not_confirmed.where(user_id: user.id).update_all(head_id: PlanningConfirmation.get_head_id(user.id))
      end
    end


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

    desc 'remove planning_confirmations duplicates'
    task :remove_planning_confirmations_duplicates => :environment do
      count = PlanningConfirmation.find_by_sql("SELECT count(id) as cnt, user_id, issue_id, date_start FROM planning_confirmations GROUP BY user_id, issue_id, date_start HAVING COUNT(id) > 1").map(&:cnt).max.to_i
      count.times.each do
        del_pc_ids = PlanningConfirmation.find_by_sql("SELECT max(id) as id, user_id, issue_id, date_start FROM planning_confirmations GROUP BY user_id, issue_id, date_start HAVING COUNT(id) > 1").map(&:id)
        PlanningConfirmation.where(id: del_pc_ids).delete_all
      end
    end

    desc 'destroy_old_planning_confirmations_planned'
    task :destroy_old_planning_confirmations_planned => :environment do
      Person.update_all(must_kgip_confirm: false, must_head_confirm: false)
      PlanningConfirmation.not_any_confirmed.delete_all
      must_kgip_confirm_users = Project.where(is_external: true).joins("LEFT OUTER JOIN members ON projects.id = members.project_id").joins("LEFT OUTER JOIN users ON members.user_id = users.id").where(["(users.no_planning <> ?)",true]).where(["users.status = ?",1]).select("distinct members.user_id").map{|m| m.user_id.to_i}
      Person.where(id: must_kgip_confirm_users).update_all(must_kgip_confirm: true)
      Person.where(["no_planning <> ?",true]).where(time_confirm: 1).update_all(must_head_confirm: true)
    end

    #desc 'fix head_id'
    #task :fix_head_id => :environment do
    #  PlanningConfirmation.select("distinct user_id").map(&:user_id).each do |user_id|
    #    if (@user = User.where(id: user_id).first) && @user.present? && @user.becomes(Person).department.present?
    #      head_id = @user.becomes(Person).department.parent.nil? ? @user.becomes(Person).department.find_head : PlanningConfirmation.get_head_id(user_id)
    #      errs = PlanningConfirmation.where(["(user_id = ?) and (head_id <> ?)", user_id, head_id])
    #      ids = errs.map(&:id)
    #      puts ids.inspect if errs.count > 0
    #      puts "user_id: #{user_id} name: #{@user.name}\n--------------" if errs.count > 0
    #      errs.update_all(head_id: head_id)
    #
    #    end
    #  end
    #end

    #desc 'fix kgip confirmations'
    #task :fix_kgip_confirmations => :environment do
    #  Project.where(:is_external => true).each do |project|
    #    kgip_id = project.kgips.first.try(:id)
    #    planning_confirmation_ids = project.issues.joins(:planning_confirmations).map(&:id)
    #    PlanningConfirmation.where(issue_id: planning_confirmation_ids).kgip_not_confirmed.where(["kgip_id <> ?", kgip_id]).update_all(kgip_id: kgip_id)
    #    puts "update for project#{project.id}"
    #  end
    #end

  end
end
