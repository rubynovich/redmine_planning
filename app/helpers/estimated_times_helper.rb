module EstimatedTimesHelper
  def span_for(text, title = "")
    content_tag :span, :title => title do
      text
    end
  end
  
  def sum_hours_spent_on(day)  
    time_entries = @time_entries.group_by(&:spent_on)[@current_date + day.days]
    if time_entries.present?
      time_entries.map{|i| i.hours }.sum(0.0)
    else
      0.0
    end
  end
  
  def sum_hours_plan_on(day)
    estimated_times = @estimated_times.group_by(&:plan_on)[@current_date + day.days]
    if estimated_times.present?
      estimated_times.map{|i| i.hours }.sum(0.0)
    else
      0.0
    end
  end

  def my_planning?
    (User.current == @current_user)
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
    day&&issue&&
    (issue.start_date && (issue.start_date <= day))&&
    (issue.due_date && (day <= issue.due_date))&&
    (1.day.ago < day) && !issue.status.is_closed?   
  end
  
  def link_to_plan(issue, day)
    shift_day = @current_date + day.days
    estimated_time = @estimated_times.select{ |et| (et.plan_on == shift_day)&&(et.issue_id == issue.id)}.first
    if estimated_time.present?
      if can_change_plan?(issue, shift_day)&&my_planning?
        link_to estimated_time.hours, {:action => 'edit', :id => estimated_time.id}, :title => estimated_time.comments
      else
        span_for estimated_time.hours, estimated_time.comments
      end
    else
      if can_change_plan?(issue, shift_day)&&my_planning?
        link_to "+", {:action => 'new', :estimated_time => {:plan_on => shift_day, :issue_id => issue}}, :title => t(:title_plan_on_date, :date => format_date(shift_day), :wday => t("date.abbr_day_names")[shift_day.wday])
      else
        "-"
      end
    end
  end
  
  def can_change_spent?(issue, day)    
    issue&&day&&
    (issue.start_date && (issue.start_date <= day))&&
    (issue.due_date && (day <= issue.due_date))&&
    (1.week.ago <= day)&&(day < 1.day.from_now.to_date)
  end
  
  def link_to_spent(issue, day)
    shift_day = @current_date + day.days
    time_entries = @time_entries.select{ |te| (te.spent_on == shift_day)&&(te.issue_id == issue.id)}
    if time_entries.any?
      sum = time_entries.map{|i| i.hours }.sum(0.0)
      comment = time_entries.map{ |i| i.comments }.reject{ |i| i.blank? }.join("\r")
      if can_change_spent?(issue, shift_day) && my_planning?
        link_to sum, {:controller => 'timelog', :action => 'index', :project_id => issue.project, :issue_id => issue, :period_type => 2, :from => shift_day, :to => shift_day}, :title => comment
      else
        sum > 0.0 ? span_for(sum, comment) : "-"
      end      
    else
      if can_change_spent?(issue, shift_day) && my_planning?
        link_to "+", {:controller => 'timelog', :action => 'new', :issue_id => issue, :time_entry => {:spent_on => shift_day}}, :title => t(:title_spent_on_date, :date => format_date(shift_day), :wday => t("date.abbr_day_names")[shift_day.wday])
      else
        "-"
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
  
  def exclude_filters
    %w{closed not_planned}  
  end
end
