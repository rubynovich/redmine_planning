module EstimatedTimesHelper
  def span_for(text, title = "")
    content_tag :span, :title => title do
      text
    end
  end

  def can_confirm_time_entries?
    Project.where(id: Role.kgip_role.members.where(user_id: User.current.id).map(&:project_id).uniq, is_external: true).any? ||
                      Department.where(confirmer_id: User.current.id).any?
  end

  def first_day 
    day = @current_date
    f_day = day - (day.wday-1)
    if Setting[:plugin_redmine_planning][:confirm_time_period].to_s == "1" # месяц
      f_day = day - (day.mday-1)
    end
    f_day
  end

  def is_confirmer_checked(issue, confirmer_type, user, date)
    PlanningConfirmation.where(issue_id: issue.id, user_id: user.id, date_start: date).map(&confirmer_type).first
  end

  def is_confirmer_checked_for_user(issue, confirmer_type, user, date)
    pcs = PlanningConfirmation.where(issue_id: issue.id, user_id: user.id, date_start: date)
    return -1 unless pcs.any?
    pcs.map(&confirmer_type).first
  end

  def get_issue_confirmation(issue, user, date)
    PlanningConfirmation.where(issue_id: issue.id, user_id: user.id, date_start: date).first
  end

  def is_confirmer_checked_conf(confirmation, confirmer_type)
    PlanningConfirmation.where(id: confirmation.id).map(&confirmer_type).first
  end


  def has_confirm_record(issue, user = nil)
    user ||= User.current
    return PlanningConfirmation.where(issue_id: issue.id, user_id: user.id).first.present?
  end




  def title_name_kgip(issue)
    h((issue.project.kgips.first.try(:name) || l(:label_confirmer_undefined)).to_s)
  end

  def title_name_confirmer(user_id)
    h(User.where(id: PlanningConfirmation.get_head_id(user_id)).first.try(:name) || l(:label_confirmer_undefined))
  end

  def title_name_head(user_id)
    h(User.where(id: user_id).first.try(:name) || l(:label_confirmer_undefined))
  end

  # def title_name_confirmer(confirmation, confirmer_id)
  #   confirm_id = PlanningConfirmation.where(id: confirmation.id).map(&confirmer_id).first
  #   #Rails.logger.error((issue.id.inspect + " " + f_day.inspect + " " + confirm_id.inspect).red)
  #   unless confirm_id.blank?
  #     return h(User.find(confirm_id).name)
  #   else
  #     return ""
  #   end
  # end

  def sum_hours_spent_on(day)
    TimeEntry.
      where(spent_on: @current_date + day.days, user_id: @current_user.id).
      sum(:hours)
  end

  def sum_hours_plan_on(day)
    EstimatedTime.
      where(plan_on: @current_date + day.days, user_id: @current_user.id).
      sum(:hours)
  end

  #def link_to_sum_hours_spent_on(day)
  #  TimeEntry.
  #    where(spent_on: @current_date + day.days, user_id: @current_user.id)
  #end

  def link_to_sum_hours_plan_on(day)
    sum = sum_hours_plan_on(day)
    style = {style: style_for_sum(sum), title: title_for_sum_hours_plan_on(day)}
    url = {controller: :estimated_times, action: :list,
      current_user_id: @current_user.id,
      start_date: @current_date + day.days,
      end_date: @current_date + day.days}
    label = html_hours("%.2f" % sum)

    link_to(label, url, style)
  end

  def link_to_sum_hours_spent_on(day)
    sum = sum_hours_spent_on(day)
    style = {style: style_for_sum(sum), title: title_for_sum_hours_spent_on(day)}
    url = {controller: :timelog, action: :index,
      user_id: @current_user.id,
      spent_on: @current_date + day.days}
    label = html_hours("%.2f" % sum)

    link_to(label, url, style)
  end

  def title_for_sum_hours_spent_on(day)
    TimeEntry.
      where(spent_on: @current_date + day.days, user_id: @current_user.id).
      select([:issue_id, :hours]).
      map{ |i| "##{i.issue_id} - #{'%.2f' % i.hours}"}.
      join("\r")
  end

  def title_for_sum_hours_plan_on(day)
    EstimatedTime.
      where(plan_on: @current_date + day.days, user_id: @current_user.id).
      select([:issue_id, :hours]).
      map{ |i| "##{i.issue_id} - #{'%.2f' % i.hours}"}.
      join("\r")
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
        link_to html_hours("%.2f" % estimated_time.hours), {:action => 'edit', :id => estimated_time.id}, :title => estimated_time.comments
      else
        span_for html_hours("%.2f" % estimated_time.hours), estimated_time.comments
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
    (count_of_back_days(day).days.ago <= day)&&(day < 1.day.from_now.to_date)&&
    (!(Setting[:plugin_redmine_planning][:issue_statuses].try(:to_a) || []).map{|i| i.to_i}.include?(issue.status_id.to_i))
  end

  def count_of_back_days(day)
    Rails.logger.error("Day #{day.inspect} ")
    business_days = 1
    calendar_days = 1
    current_day = day
    debugger
    while business_days < 10
      current_day -= 1.day
      calendar_days += 1
      holiday = Calendar.is_holiday?(current_day) 
      p holiday
      business_days += 1 unless holiday
    end
    Rails.logger.error("Result #{calendar_days} ")
    calendar_days
  end

  def link_to_spent_and_edit(issue, day, can_edit)
    shift_day = @current_date + day.days
    time_entries = @time_entries.select{ |te| (te.spent_on == shift_day)&&(te.issue_id == issue.id)}
    if time_entries.any?
      sum = time_entries.map{|i| i.hours }.sum(0.0)
      comment = time_entries.map{ |i| i.comments }.reject{ |i| i.blank? }.join("\r")
      if can_change_spent?(issue, shift_day) && my_planning?
        link_to html_hours("%.2f" % sum), {:controller => 'timelog', :action => 'index', :project_id => issue.project, :issue_id => issue, :period_type => 2, :from => shift_day, :to => shift_day}, :title => comment
      else
        sum > 0.0 ? span_for(html_hours("%.2f" % sum), comment) : "-"
      end
    else
      if can_change_spent?(issue, shift_day) && my_planning? && can_edit
        link_to "+", {:controller => 'timelog', :action => 'new', :issue_id => issue, :time_entry => {:spent_on => shift_day}}, :title => t(:title_spent_on_date, :date => format_date(shift_day), :wday => t("date.abbr_day_names")[shift_day.wday])
      else
        "-"
      end
    end
  end


  def show_spent_for_user(issue, day, user)
    shift_day = @current_date + day.days
    time_entries = @time_entries.select{ |te| (te.spent_on == shift_day)&&(te.issue_id == issue.try(:id))&&(te.user_id == user.try(:id))}
    if time_entries.any?
      sum = time_entries.map{|i| i.hours }.sum(0.0)
      comment = time_entries.map{ |i| i.comments }.reject{ |i| i.blank? }.join("\r")
      sum > 0.0 ? span_for(html_hours("%.2f" % sum), comment) : "-"
    else
      "-"
    end
  end

  def sum_spent_for_user_issue(issue, user)
    time_entries = TimeEntry.where(issue_id: issue.try(:id), user_id: user.try(:id))
    if time_entries.any?
      time_entries.map{|i| i.hours }.sum(0.0).to_f
    else
      0.0
    end
  end

  def comments_spent_for_user_issue(issue, user)
    time_entries = TimeEntry.where(issue_id: issue.try(:id), user_id: user.try(:id))
    if time_entries.any?
      time_entries.map{ |i| i.comments }.reject{ |i| i.blank? }.join("\r")
    else
      nil
    end
  end


  def sum_spent_for_issue(issue)
    time_entries = TimeEntry.where(issue_id: issue.try(:id))
    if time_entries.any?
      time_entries.sum(:hours).to_f
    else
      0.0
    end
  end

  def link_to_spent(issue, day)
    link_to_spent_and_edit(issue, day, true)
  end

  def link_to_spent_without_edit(issue, day)
    link_to_spent_and_edit(issue, day, false)
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
    %w{overdue closed not_planned not_urgent group_by_project}
  end

  def confirm_filters
    %w{group_by_project group_by_user confirmed_time}
  end

  def index_to_csv
    encoding = l(:general_csv_encoding)
    decimal_separator = l(:general_csv_decimal_separator)
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields

      header_fields_1 = [ "#", l(:field_subject), l(:field_deadline)] + (0...7).map{ |day| [(@current_date + day.days).strftime("%d.%m")]*2 }.flatten 
      header_fields_1.map!{|field| Redmine::CodesetUtil.from_utf8(field, encoding) }

      header_fields_2 = [ "" ]*3 + [l(:label_plan), l(:label_spent)]*7
      header_fields_2.map!{|field| Redmine::CodesetUtil.from_utf8(field, encoding) }

      csv << header_fields_1
      csv << header_fields_2

      # csv lines
      @assigned_issues.each do |issue|
        col_values = (0...7).map do |day|
          shift_day = @current_date + day.days
          plan = @estimated_times.select{ |et| (et.plan_on == shift_day)&&(et.issue_id == issue.id)}.map(&:hours).sum(0.0)
          spent = @time_entries.select{ |te| (te.spent_on == shift_day)&&(te.issue_id == issue.id)}.map(&:hours).sum(0.0)

          [plan, spent].map do |f|
            ("%.2f" % f).gsub('.', decimal_separator)
          end
        end.flatten

        csv_line = [ issue.id.to_s, issue.subject + " (#{issue.status})", issue_dates(issue) ] + col_values
        csv_line.map!{|field| Redmine::CodesetUtil.from_utf8(field, encoding) }

        csv << csv_line
      end
    end
    export
  end

  def list_to_csv
    encoding = l(:general_csv_encoding)
    decimal_separator = l(:general_csv_decimal_separator)
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      header_fields = [
                       l(:label_date),
                       l(:label_member),
                       l(:label_project),
                       l(:label_issue),
                       l(:field_comments),
                       l(:field_hours) ]
      header_fields.map!{|field| Redmine::CodesetUtil.from_utf8(field, encoding) }
      csv << header_fields

      # csv lines
      @estimated_times.each do |entry|
        csv_line = [
          format_date(entry.plan_on),
          entry.user.name,
          entry.project.name,
          "#{entry.issue.tracker} ##{entry.issue.id}: " + entry.issue.subject,
          entry.comments,
          ("%.2f" % entry.hours).gsub('.', decimal_separator)
        ]
        csv_line.map!{|field| Redmine::CodesetUtil.from_utf8(field, encoding) }
        csv << csv_line
      end
    end
    export
  end

  def style_for_workplace_start_time(workplace_time)
    delay = workplace_time.delay.seconds_since_midnight
    start_time = workplace_time.start_time.seconds_since_midnight
    if start_time == 0.0
      "color: gray"
    elsif delay > 900.0
      "color: red"
    elsif delay > 0.0
      "color: darkorange"
    else
      "color: green"
    end
  end

  def style_for_workplace_end_time(workplace_time)
    duration = workplace_time.duration.seconds_since_midnight
    end_time = workplace_time.end_time.seconds_since_midnight
    if end_time == 0.0
      "color: gray"
    elsif duration > 3600*9
      "color: red"
    elsif duration > 3600*8
      "color: darkorange"
    else
      "color: green"
    end
  end

  def title_for_workplace_start_time(workplace_time)
    l(:label_workplace_delay)+": "+workplace_time.delay.strftime("%H:%M")
  end

  def title_for_workplace_end_time(workplace_time)
    l(:label_workplace_duration)+": "+workplace_time.duration.strftime("%H:%M")
  end

end
