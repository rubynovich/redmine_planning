class PlanningConfirmation < ActiveRecord::Base
  unloadable

  belongs_to :user, class_name: 'Person', foreign_key: 'user_id'
  belongs_to :issue
  belongs_to :kgip, class_name: 'Person', foreign_key: 'KGIP_id'
  belongs_to :leader, class_name: 'Person', foreign_key: 'head_id'

  class << self
  def confirm_time_period
  	[[l(:label_confirm_time_week), 0], [l(:label_confirm_time_month), 1]]
  end


  def create_planning(params)
    Rails.logger.error(("create_planning2: " + params.inspect).red)
    if params.class.to_s == "Hash"
    	assigned_to = User.find(params[:assigned_to_id])
    	id = params[:id]
    	project_id = params[:project_id]
    	start_date = params[:start_date].to_date
    	due_date = params[:due_date].to_date
    else
    	assigned_to = params.assigned_to
    	id = params.id
    	project_id = params.project_id
    	start_date = params.start_date.to_date
    	due_date = params.due_date.to_date
    end
    return true if assigned_to.department_id.nil? 

	create_planning_for_period(first_date(start_date), due_date, assigned_to.id, id, get_kgip_id(project_id), get_head_id(assigned_to.id))
	
	Rails.logger.error("create_planning created".red)   	
  end
  
  def change_dates_planning(params) # смена сроков 
    Rails.logger.error(("change_dates_planning: " + params.inspect).red)
    issue = params[:issue]
    old_issue = Issue.find(params[:id])

	confirms = (PlanningConfirmation.where(issue_id: params[:id], KGIP_confirmation: [nil, false]) + 
				PlanningConfirmation.where(issue_id: params[:id], head_confirmation: [nil, false])).uniq

	confirms.each do |confirm|		
		if ((confirm.date_start.to_date + planning_duration(confirm.date_start)) < issue[:start_date].to_date) || (confirm.date_start.to_date > issue[:due_date].to_date)
			Rails.logger.error("uhhu! " + confirm.date_start.inspect.red)
			confirm.destroy if no_time_planned(old_issue.id, confirm.date_start)
		end
	end

    return true if User.find(issue[:assigned_to_id]).department_id.nil? 
    head_id = get_head_id(issue[:assigned_to_id])
	kgip_id = get_kgip_id(issue[:project_id])

	if (issue[:start_date].to_date < old_issue.start_date.to_date) && (first_date(issue[:start_date].to_date) != first_date(old_issue.start_date.to_date))
		due_d = (issue[:due_date].to_date < old_issue.start_date.to_date) ? issue[:due_date].to_date : first_date(old_issue.start_date.to_date)-1
		Rails.logger.error("change start ".red+first_date(due_d).inspect.red) 
		
		create_planning_for_period(first_date(issue[:start_date]), first_date(due_d), issue[:assigned_to_id], old_issue.id, kgip_id, head_id)
	end

	if (issue[:due_date].to_date > old_issue.due_date.to_date) && (first_date(issue[:due_date].to_date) != first_date(old_issue.due_date.to_date))
		start_d = (issue[:start_date].to_date > old_issue.due_date.to_date) ? issue[:start_date].to_date : first_date(old_issue.due_date.to_date) + planning_duration(first_date(old_issue.due_date.to_date))
		Rails.logger.error("change end".red) 
		create_planning_for_period(first_date(start_d), issue[:due_date], issue[:assigned_to_id], old_issue.id, kgip_id, head_id)
	end

	Rails.logger.error("change_dates_planning updated".red) 
  	
  end

  def change_assigned_to_planning(params) # смена сроков 
    Rails.logger.error(("change_assigned_to_planning: " + params.inspect).red)
    issue = params[:issue]

	confirms = (PlanningConfirmation.where(issue_id: params[:id], KGIP_confirmation: [nil, false]) + 
				PlanningConfirmation.where(issue_id: params[:id], head_confirmation: [nil, false])).uniq

	f_day = Date.today - (Date.today.wday-1)
	if Setting[:plugin_redmine_planning][:confirm_time_period].to_s == "1" # месяц
		f_day = Date.today - (Date.today.mday-1)
	end
	confirms.each do |confirm|
		if confirm.date_start.to_date > f_day
			#confirm.issue_id = params[:id]
			#confirm.date_start = Date.today 
			#confirm.KGIP_id = kgip_id
			#confirm.head_id = head_id
			confirm.update_column(:user_id, issue[:assigned_to_id])
		end
	end

    return true if User.find(issue[:assigned_to_id]).department_id.nil? 

    if first_date(Issue.find(params[:id]).start_date) <= f_day 
		create_planning_for_period(f_day, f_day+ planning_duration(f_day), issue[:assigned_to_id], 
			params[:id], get_kgip_id(issue[:project_id]), get_head_id(issue[:assigned_to_id]))
	end

	Rails.logger.error("change_assigned_to_planning updated".red) 
  	
  end

  def change_kgip_planning(member_id) # смена КГИПа
  	PlanningConfirmation.update_all({:KGIP_id => Member.find(member_id).user_id}, {:issue_id => Member.find(member_id).project.issues.map(&:id)})
  end

  def change_head_planning(params) # смена руководителя
  	PlanningConfirmation.update_all({:head_id => params.confirmer_id}, {:user_id => Person.where(department_id: params.id).map(&:id)})
  end

  def create_or_change_planning(person)
  	if person.time_confirm.to_i == 1

  		# подтверждение для задач, назначенных на юзера сейчас и тех, которые были назначены раньше, но переназначены на другого

      iss_ids = JournalDetail.joins(:journal).
      where("#{Journal.table_name}.created_on >= '2014-06-01'").
      where(%{#{JournalDetail.table_name}.prop_key = 'assigned_to_id'}).
      where([%{#{JournalDetail.table_name}.old_value = ?}, person.id]).
      where(%{#{Journal.table_name}.journalized_type = 'Issue'}).pluck(:journalized_id).uniq

      assigned_ids = Issue.where("due_date >= ? AND assigned_to_id = ?", '2014-06-01', person.id).pluck(:id).uniq
      head_id = get_head_id(person.id)
      PlanningConfirmation.create( Issue.where(id: (iss_ids+assigned_ids).uniq).map{|issue| 
        issue_from_date = issue.start_date < '2014-06-02'.to_date ? '2014-06-02'.to_date : issue.start_date.to_date
        (issue_from_date..issue.due_date.to_date).map{|date| date.beginning_of_week}.uniq.map{|day|
          {
            :user_id => person.id,
            :issue_id => issue.id,
            :date_start => day, 
            :KGIP_id => get_kgip_id(issue.project_id),
            :head_id => head_id
          }
        }
      }.flatten)


  	else
  		PlanningConfirmation.delete_all("user_id = ?", params.id)
  	end
  end

  private  
  def no_time_planned(issue_id, date_start)
  	spent_times = TimeEntry.where("issue_id = ? AND spent_on BETWEEN ? AND ?", issue_id, date_start, date_start + planning_duration(date_start))
  	#Rails.logger.error("spent_times = " + spent_times.inspect.red)
  	return spent_times.blank?
  end
  
  def month_length(date)
  	case date.mon
	when 1, 3, 5, 7, 8, 10, 12
		return 31
	when 2
		if Date.leap?(date.year)
			return 29
		else
			return 28
		end
	else
		return 30
	end
  end

  def planning_duration(first_d)
  	if Setting[:plugin_redmine_planning][:confirm_time_period].to_s == "0"
		return 7
	else
		return month_length(first_d)
	end
  end

  def get_head_id(assigned_to_id)
    department = Department.find(User.find(assigned_to_id).department_id)
    head_id = department.confirmer_id.blank? ? department.head_id : department.confirmer_id
  end

  def get_kgip_id(project_id)
	role = Role.where(name: "КГИП")[0].members.where(project_id: project_id)[0]
	kgip_id = role.blank? ? nil : role.user_id  	
  end

  def first_date(start_date)
  	first_d = start_date.to_date - (start_date.to_date.wday-1)
	if Setting[:plugin_redmine_planning][:confirm_time_period].to_s == "1" # месяц
		first_d = start_date.to_date - (start_date.to_date.mday-1)
	end
	first_d
  end

  def create_planning_for_period(first_d, due_date, a_id, i_id, kgip_id, head_id)
  	while first_d.to_date <= due_date.to_date
  		Rails.logger.error("first_d = "+ first_d.inspect.green + ", planning_duration first_d = "+ planning_duration(first_d).inspect.green)

  		unless PlanningConfirmation.where(:user_id => a_id,
			                        :issue_id => i_id,
			                        :date_start => first_d, 
			                        :KGIP_id => kgip_id,
			                        :head_id => head_id).count > 0
			PlanningConfirmation.create(:user_id => a_id,
				                        :issue_id => i_id,
				                        :date_start => first_d, 
				                        :KGIP_id => kgip_id,
				                        :head_id => head_id)
		end
		first_d = first_d + planning_duration(first_d)
	end
  end
end

end
