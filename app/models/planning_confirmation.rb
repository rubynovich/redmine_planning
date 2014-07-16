class PlanningConfirmation < ActiveRecord::Base
  unloadable

  belongs_to :user, class_name: 'Person', foreign_key: 'user_id'
  belongs_to :issue
  belongs_to :kgip, class_name: 'Person', foreign_key: 'KGIP_id'
  belongs_to :leader, class_name: 'Person', foreign_key: 'head_id'
  has_one :project, :through => :issue


  def planned_in?
    ! PlanningConfirmation.no_time_planned(self.issue_id, self.date_start)
  end


  class << self
  def confirm_time_period
  	[[l(:label_confirm_time_week), 0], [l(:label_confirm_time_month), 1]]
  end


  def create_planning(params)
    #Rails.logger.error(("create_planning2: " + params.inspect).red)
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
	
	#Rails.logger.error("create_planning created".red)
  end
  
  def change_dates_planning(issue_params, old_issue) # смена сроков



    confirms = (PlanningConfirmation.where(issue_id: old_issue.id, KGIP_confirmation: [nil, false]) +
          PlanningConfirmation.where(issue_id: old_issue.id, head_confirmation: [nil, false])).uniq

    confirms.each do |confirm|
      if ((confirm.date_start.to_date + planning_duration(confirm.date_start)) < issue_params[:start_date].try(:to_date)) || (confirm.date_start.to_date > issue_params[:due_date].try(:to_date))
        #Rails.logger.error("uhhu! " + confirm.date_start.inspect.red)
        confirm.destroy if no_time_planned(old_issue.id, confirm.date_start)
      end
    end

    return true if Person.where(id: issue_params[:assigned_to_id]).first.try(:department_id).nil?
    head_id = get_head_id(issue_params[:assigned_to_id])
    kgip_id = get_kgip_id(issue_params[:project_id])

    if (issue_params[:start_date].try(:to_date) < old_issue.start_date.to_date) && (first_date(issue_params[:start_date].try(:to_date)) != first_date(old_issue.start_date.to_date))
      due_d = (issue_params[:due_date].to_date < old_issue.start_date.to_date) ? issue_params[:due_date].to_date : first_date(old_issue.start_date.to_date)-1
      #Rails.logger.error("change start ".red+first_date(due_d).inspect.red)
      create_planning_for_period(first_date(issue_params[:start_date]), first_date(due_d), issue_params[:assigned_to_id], old_issue.id, kgip_id, head_id)
    end

    if (issue_params[:due_date].to_date > old_issue.due_date.to_date) && (first_date(issue_params[:due_date].to_date) != first_date(old_issue.due_date.to_date))
      start_d = (issue_params[:start_date].to_date > old_issue.due_date.to_date) ? issue_params[:start_date].to_date : first_date(old_issue.due_date.to_date) + planning_duration(first_date(old_issue.due_date.to_date))
      #Rails.logger.error("change end".red)
      create_planning_for_period(first_date(start_d), issue_params[:due_date], issue_params[:assigned_to_id], old_issue.id, kgip_id, head_id)
    end
  	
  end

  def change_assigned_to_planning(issue_params, old_issue) # смена сроков

    confirms = (PlanningConfirmation.where(issue_id: old_issue.id, KGIP_confirmation: [nil, false]) +
          PlanningConfirmation.where(issue_id: old_issue.id, head_confirmation: [nil, false])).uniq

    f_day = (Setting[:plugin_redmine_planning][:confirm_time_period].to_s == "1") ? (Date.today.beginning_of_month + 5.days).beginning_of_week : Date.today.beginning_of_week

    #f_day = Date.today - (Date.today.wday-1)
    #if Setting[:plugin_redmine_planning][:confirm_time_period].to_s == "1" # месяц
    #	f_day = Date.today - (Date.today.mday-1)
    #end
    confirms.each do |confirm|
      if confirm.date_start.to_date > f_day
        confirm.update_column(:user_id, issue_params[:assigned_to_id])
      end
    end

    return true if Person.where(id: issue_params[:assigned_to_id]).first.try(:department_id).nil?

    if first_date(old_issue.try(:start_date)) <= f_day
      create_planning_for_period(f_day, f_day+ planning_duration(f_day), issue_params[:assigned_to_id],
        old_issue.id, get_kgip_id(issue_params[:project_id]), get_head_id(issue_params[:assigned_to_id]))
    end

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
      where([%{#{JournalDetail.table_name}.old_value = ?}, person.id.to_s]).
      where(%{#{Journal.table_name}.journalized_type = 'Issue'}).pluck(:journalized_id).uniq

      assigned_ids = Issue.where(["due_date >= ? AND assigned_to_id = ?", '2014-06-01', person.id]).pluck(:id).uniq
      head_id = get_head_id(person.id)

      pcs_attrs = Issue.where(id: (iss_ids+assigned_ids).uniq).map{|issue|
        issue_from_date = issue.start_date < '2014-06-02'.to_date ? '2014-06-02'.to_date : issue.start_date.to_date
        (issue_from_date..issue.due_date.to_date).map{|date| date.beginning_of_week}.uniq.map{|day|
          {
              :user_id => person.id,
              :issue_id => issue.id,
              :date_start => day
              #:KGIP_id => get_kgip_id(issue.project_id),
              #:head_id => head_id
          }
        }
      }.flatten
      #puts pcs_attrs.inspect


      issue_ids = []
      gsql_query = '('+(pcs_attrs.map{|item|
        issue_ids << item[:issue_id]
        PlanningConfirmation.send(:sanitize_conditions, item)
        #Issue.where(id: )
      }+['1 = 2']).join(%{) OR (})+')'

      kgips_hash = {}
      Issue.where(id: issue_ids).each{|i| kgips_hash.merge!(i.id => get_kgip_id(i.project_id)) if i.project.is_external?}



      pcs_ex = PlanningConfirmation.where(gsql_query).map{|i| i.attributes.symbolize_keys.select{|k,v| [:user_id, :issue_id, :date_start].include?(k)}}
      create_hash = (pcs_attrs - pcs_ex).map{|itm| itm.merge({
                                                                 :KGIP_id => get_kgip_id(Issue.find(itm[:issue_id]).try(:project_id)),
                                                                 :head_id => head_id
                                                             }) }
      #puts create_hash.inspect
      PlanningConfirmation.create(create_hash)
    else
      PlanningConfirmation.delete_all(["user_id = ?", person.id])
    end
  end



  def no_time_planned(issue_id, date_start)
  	spent_times = TimeEntry.where("issue_id = ? AND spent_on BETWEEN ? AND ?", issue_id, date_start, date_start + planning_duration(date_start))
  	return spent_times.blank?
  end

  private
  
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
    department = Person.where(id: assigned_to_id).first.try(:department)
    department.confirmer_id.blank? ? department.find_head.try(:id) : department.confirmer_id if department
  end

  def get_kgip_id(project_id)
	  Role.kgip_role.members.where(project_id: project_id).first.try(:user_id)
  end

  def first_date(start_date)
    (Setting[:plugin_redmine_planning][:confirm_time_period].to_s == "1") ? (start_date.beginning_of_month + 5.days).beginning_of_week : start_date.beginning_of_week
  end

  def create_planning_for_period(first_d, due_date, a_id, i_id, kgip_id, head_id)
  	while first_d.to_date <= due_date.to_date

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
