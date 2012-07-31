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
end
