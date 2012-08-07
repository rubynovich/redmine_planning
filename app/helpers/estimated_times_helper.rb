module EstimatedTimesHelper
  def sum_hours_spent_on(day)  
    @assigned_issues.map do |issue|
      if time_entries = TimeEntry.find(:all, :conditions => {:issue_id => issue.id, :spent_on => @current_date + day.days, :user_id => @current_user})
        time_entries.map{ |i| i.hours }.sum(0.0)
      end
    end.compact.sum(0.0)
  end
  
  def sum_hours_plan_on(day)
    @assigned_issues.map do |issue|
      if estimated_times = EstimatedTime.find(:all, :conditions => {:issue_id => issue.id, :plan_on => @current_date + day.days, :user_id => @current_user})
        estimated_times.map{|i| i.hours }.sum(0.0)
      end
    end.compact.sum(0.0)
  end
  
  def issue_dates(issue)
    str = ""
    if issue.start_date.present?
      str += issue.start_date.strftime("%d.%m")
      str += "-"  if issue.due_date.present?
    end
    str += format_date(issue.due_date) if issue.due_date.present?
    str
  end
  
  def can_change_plan?(issue, day)
    (User.current == @current_user)&&
    (issue.start_date && (issue.start_date < day))&&
    (issue.due_date && (day < issue.due_date))&&
    (1.day.ago < day)&&(day < 2.week.from_now.to_date)
  end
  
  def link_to_plan(issue, day)
    shift_day = @current_date + day.days
    if estimated_time = EstimatedTime.find(:first, :conditions => {:user_id => @current_user, :plan_on => shift_day, :issue_id => issue})
      if can_change_plan?(issue, shift_day)
        link_to estimated_time.hours, {:action => 'edit', :id => estimated_time.id}
      else
        estimated_time.hours
      end
    else
      if can_change_plan?(issue, shift_day)
        link_to "+", {:action => 'new', :estimated_time => {:plan_on => shift_day, :issue_id => issue}}
      else
        "-"
      end
    end
  end
  
  def can_change_spant?(issue, day)
    (User.current == @current_user)&&
    (issue.start_date && (issue.start_date < day))&&
    (issue.due_date && (day < issue.due_date))&&
    (2.week.ago < day)&&(day < 1.day.from_now.to_date)
  end
  
  def link_to_spant(issue, day)
    shift_day = @current_date + day.days
    if time_entries = TimeEntry.find(:all, :conditions => {:issue_id => issue.id, :spent_on => shift_day, :user_id => @current_user})
      sum = time_entries.map{|i| i.hours }.sum(0.0)
      if sum > 0.0
        if can_change_spant?(issue, shift_day)
          link_to sum, {:controller => 'timelog', :action => 'index', :project_id => issue.project, :issue_id => issue, :period_type => 2, :from => shift_day, :to => shift_day}, :title => time_entries.map{ |i| i.comments }.reject{ |i| i.blank? }.join("\r")
        else
          sum
        end
      else
        if can_change_spant?(issue, shift_day)
          link_to "+", {:controller => 'timelog', :action => 'new', :issue_id => issue, :time_entry => {:spent_on => shift_day}}
        else
          "-"
        end
      end
    end
  end
  
  def style_for_sum(sum)
    if sum < 6.0
      "color: green"
    elsif sum < 8.0
      "color: orange"
    else
      "color: red"
    end
  end
end
