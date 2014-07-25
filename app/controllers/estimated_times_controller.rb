# -*- coding: utf-8 -*-
class EstimatedTimesController < ApplicationController
  unloadable

  include Redmine::Utils::DateCalculation

  before_filter :get_current_date, except: [:confirm_time]
  before_filter :get_project
  before_filter :get_current_user, except: [:confirm_time]
  before_filter :get_planning_manager
  before_filter :add_info, :only => [:new, :index, :edit, :update, :weekend, :widget]
  before_filter :add_confirm_info, :only => [:confirm_time]
  before_filter :authorized # TODO в ApplicationController есть метод :require_login
  before_filter :require_planning_manager
  before_filter :new_estimated_time, :only => [:new, :index, :create]
  before_filter :find_estimated_time, :only => [:edit, :update, :destroy]
  before_filter :time_entry_month_sum, :only => [:index]

  helper :timelog
  include TimelogHelper
  helper :sort
  include SortHelper
  helper :estimated_times
  include EstimatedTimesHelper

  accept_api_auth :index, :show, :list, :widget, :create

  def index
    @workplace_times = begin
      WorkplaceTime.where(:user_id => @current_user.id).where("workday BETWEEN ? AND ?", @current_date, @current_date+7.days).group_by(&:workday)
    rescue
      {}
    end

    @users = [User.current] + @planning_manager.active_subordinates

    @planning_preference = User.current.planning_preference

    respond_to do |format|
      format.html{ render :action => :index }
      format.csv{ send_data(index_to_csv, :type => 'text/csv; header=present', :filename => @current_date.strftime("planning_table_%Y-%m-%d_#{@current_user.login}.csv"))}
      format.json{ render :json => @estimated_times, :except => [:issue_id, :project_id, :tmonth, :tyear, :tweek, :created_on, :updated_on], :include => {
          :project => {:only => [:id, :name]},
          :issue => {:only => [:id, :subject, :start_date, :due_date]}
        }
      }
    end
  end

  def confirm_time
    @current_date = @current_date.beginning_of_week

    @workplace_times = begin
      WorkplaceTime.where("workday BETWEEN ? AND ?", @current_date, @current_date+7.days).group_by(&:workday)
    rescue
      {}
    end

    #@users =  #[User.current] + @planning_manager.active_subordinates

    @planning_preference = User.current.planning_preference

    respond_to do |format|
      format.html{ render :action => :confirm_time }
      format.csv{ send_data(index_to_csv, :type => 'text/csv; header=present', :filename => @current_date.strftime("planning_table_%Y-%m-%d_#{@current_user.login}.csv"))}
      format.json{ render :json => @estimated_times, :except => [:issue_id, :project_id, :tmonth, :tyear, :tweek, :created_on, :updated_on], :include => {
          :project => {:only => [:id, :name]},
          :issue => {:only => [:id, :subject, :start_date, :due_date]}
        }
      }
    end
  end

  def new
  end

  def edit
  end

  def update
      if params[:estimated_time][:hours].to_f <= 0.0
        flash[:notice] = l(:notice_successful_delete) if @estimated_time.destroy
        redirect_back_or_default :action => :index, :current_date => @current_date
      elsif @estimated_time.update_attributes(params[:estimated_time])
        flash[:notice] = l(:notice_successful_update)
        redirect_back_or_default :action => :index, :current_date => @current_date
      else
        render :action => :edit, :current_date => @current_date
      end
    rescue
      render_403
  end

  def create
    if @estimated_time.present? && @estimated_time.save
      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.html{
          if params[:estimated_time][:google_calendar] == "1"
            begin
              cal = Google::Calendar.new(
                :username => params[:estimated_time][:google_username],
                :password => params[:estimated_time][:google_password])
              time = params[:estimated_time][:google_start_time].
                seconds_since_midnight - Time.now.utc_offset + (Setting[:plugin_redmine_planning][:google_time_fix].to_i.minutes.to_i)
              delta = (@estimated_time.hours*3600).round
              event = cal.create_event do |e|
                e.title = @estimated_time.comments
                e.content = [@estimated_time.issue.project.name, "##{@estimated_time.issue_id} #{@estimated_time.issue.subject}", @estimated_time.issue.description].join("\n")
                e.start_time = @estimated_time.plan_on.in(time)
                e.end_time = @estimated_time.plan_on.in(time + delta)
              end
              flash[:warning] = l(:google_calendar_create_event_successful)
              cookies[:google_username] = params[:estimated_time][:google_username]
              cookies[:google_password] = params[:estimated_time][:google_password]
            rescue
              flash[:error] = l(:google_calendar_create_event_error)
            end
          end
          redirect_back_or_default :action => :index, :current_date => @current_date
        }
        format.json{ render :json => @estimated_time}
      end
    else
      respond_to do |format|
        format.html{
          add_info
          render :action => :new, :current_date => @current_date
        }
        format.json{
          render_validation_errors(@estimated_time)
        }
      end

    end
  end

  def destroy
      if (@estimated_time.present?)
        flash[:notice] = l(:notice_successful_delete) if @estimated_time.destroy
      end
      redirect_to :action => :index, :current_date => @current_date
    rescue
      render_403
  end

  def list
    sort_init 'plan_on', 'desc'
    sort_update 'plan_on' => 'plan_on',
                'user' => 'user_id',
                'project' => "#{Project.table_name}.name",
                'issue' => 'issue_id',
                'hours' => 'hours'

    @assigned_issues = Issue.
      find(:all,
        :conditions => {:assigned_to_id => ([@current_user.id] + @current_user.group_ids)},
        :include => [:status, :project, :tracker, :priority],
        :order => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date")


    @assigned_issue_ids = if params[:issue_id].present? &&
      (issue = Issue.find(params[:issue_id]))

      [issue.id]
    else
      @assigned_issues.map(&:id)
    end

    @estimated_times = EstimatedTime.
      for_user(@current_user.id).
#      for_issues(@assigned_issue_ids).
      actual(params[:start_date], params[:end_date]).
      for_period(params[:period]).
      all(:order => sort_clause)

    respond_to do |format|
      format.html{ render :action => :list }
      format.csv{ send_data(list_to_csv, :type => 'text/csv; header=present', :filename => Date.today.strftime("planning_list_%Y-%m-%d_#{@current_user.login}.csv"))}
      format.json{ render :json => @estimated_times, :except => [:issue_id, :project_id, :tmonth, :tyear, :tweek, :created_on, :updated_on], :include => {
          :project => {:only => [:id, :name]},
          :issue => {:only => [:id, :subject, :start_date, :due_date]}
        }
      }
    end
  end

  def widget
    @to_respond = @estimated_times.group_by(&:plan_on).map{ |date, estimated_times|
      {
        :date => date,
        :projects => estimated_times.group_by(&:project).map{ |project, est_times|
          {
            :project => project.name,
            :issues => est_times.map{ |est_time|
              {
                :issue => {:id => est_time.issue_id, :name => est_time.issue.subject, :due_date => est_time.issue.due_date},
                :estimated_time => {:hours => est_time.hours},
                :time_entry => {
                  :hours => @time_entries.select{ |time_entry|
                    (time_entry.spent_on == date) && (est_time.issue_id == time_entry.issue_id)
                  }.map(&:hours).sum(0.0)
                }
              } unless est_time.issue.nil?
            }.compact
          }
        }
      }
    }

    respond_to do |format|
      format.json{ render :json => @to_respond}
    end
  end

  def weekend
    sat = @current_date + 5.days
    sun = @current_date + 6.days
    @weekend_users = EstimatedTime.where(["plan_on = ? OR plan_on = ?", sun, sat]).select('DISTINCT user_id').map(&:user)
  end

  private

    def get_current_date
      @current_date = if params[:current_date].blank?
        Date.today
      else
        Date.parse(params[:current_date])
      end
      @current_date -= @current_date.wday.days - 1.day
    end

    def get_project
      @project = if params[:project_id].present?
        Project.find_by_identifier(params[:project_id])
      end
    end

    def get_current_user
      @current_user = if params[:current_user_id].present?
        User.find(params[:current_user_id])
      else
        User.current
      end
    end

    def get_planning_manager
      @planning_manager = PlanningManager.find_by_user_id(User.current.id)
    end

    def add_info
      @current_dates = [@current_date-2.week, @current_date-1.week, @current_date, @current_date+1.week, @current_date+2.week]

      user = User.current
      if user.planning_preference.present? && params.keys.none?{|k| k =~ /^exclude/}
        user_preferences = user.planning_preference.preferences || Hash.new
        params.merge!(user_preferences){|key, params_value, preferences_value| params_value}
      end

      @assigned_issues = Issue.
        actual(@current_date, @current_date+6.days).
        in_project(@project).
        exclude_closed(params[:exclude_closed]).
        exclude_overdue(params[:exclude_overdue], @current_date).
        exclude_not_planned(params[:exclude_not_planned], @current_date).
        exclude_not_urgent(params[:exclude_not_urgent], @current_date).
        find(:all, :conditions => {:assigned_to_id => ([@current_user.id] + @current_user.group_ids)},
          :include => [:status, :project, :tracker, :priority],
          :order => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date")


      @project_issues = if params[:exclude_group_by_project].present?
        [[nil, @assigned_issues]]
      else
        @assigned_issues.group_by(&:project).sort_by{|p,i| p.name }
      end

      @assigned_issue_ids = @assigned_issues.map(&:id)

      @estimated_times = EstimatedTime.
        actual(@current_date, @current_date+6.days).
        for_user(@current_user.id)

      @estimated_time_sum = EstimatedTime.
        for_user(@current_user.id).
        group_by(&:issue_id)

      @time_entries = TimeEntry.
        actual(@current_date, @current_date+6.days).
        for_user(@current_user.id)

      @assigned_projects = Member.where(user_id: @current_user.id).includes(:project).select(&:project).map(&:project).sort_by(&:name)
    end

    def add_confirm_info
      @current_date = if params[:current_date].blank?
                        (Date.today - 1.week).beginning_of_week
                      else
                        Date.parse(params[:current_date]).beginning_of_week
                      end

      if (@current_date+1.week) > Date.today
        render_403;
        return
      end

      @current_dates = []
      [-2,-1,0,1,2].each do |c_week|
        @current_dates << @current_date+c_week.week if (@current_date+c_week.week+1.week) <= Date.today
      end

      # С какой ролью заходит подтверждающий
      @assigned_projects = User.current.projects.where(is_external: true).keep_if{|p| p.kgip_ids.include?(User.current.id)}
      #@assigned_projects = Project.where(id: Role.kgip_role.members.where(user_id: User.current.id).map(&:project_id).uniq, is_external: true)
      if @assigned_projects.count > 0
        @confirm_role = 0
        #as kgip
      end

      departments = Department.where(confirmer_id: User.current.id)
      if departments.any?
        @can_change_role = (@confirm_role == 0)
      end
      if departments.any? && ((params[:confirm_role].to_i == 1) || @confirm_role.nil?)
        #@assigned_projects = departments.map{|department| department.people}.flatten.map{|person| person.projects}.flatten.uniq
        #@assigned_projects = Project.where(id: departments.joins(:people => {:members => :project}).select('DISTINCT projects.id as project_id').map(&:project_id))
        @assigned_projects = Project.where("id in (#{departments.joins(:people => {:members => :project}).select('DISTINCT projects.id as project_id').to_sql})")
        @confirm_role = 1
      elsif @confirm_role.nil?
        render_403;
        return
      end
      @project_lists = @assigned_projects.dup
      if @project && @assigned_projects.include?(@project)
        @assigned_projects = [@project]
      elsif @project
        @assigned_projects = []
      end


      if @confirm_role == 0
        need_confirmations = PlanningConfirmation.joins(:project).where(date_start: @current_date, KGIP_id: User.current.id).where("projects.id IN (?)", @assigned_projects.map(&:id))
      else
        need_confirmations = PlanningConfirmation.joins(:project).where(date_start: @current_date, head_id: User.current.id).where("projects.id IN (?)", @assigned_projects.map(&:id))
      end
      @assigned_confirmations = need_confirmations

      if params[:confirm_confirmed_time].present? && !@assigned_confirmations.blank?
        @assigned_confirmations = @assigned_confirmations.where(KGIP_confirmation: [nil,false], head_confirmation: [nil,false])
      end


      @assigned_confirmations = @assigned_confirmations.where(id: @assigned_confirmations.map{|confirmation| confirmation.id if confirmation.planned_in?}.compact)
      @users = @assigned_confirmations.joins(:user).select('distinct users.id, users.*, planning_confirmations.user_id').order("users.lastname asc, users.firstname asc").map(&:user).sort
      if params[:current_user_id].present?  && @assigned_confirmations.any?
        @assigned_confirmations = @assigned_confirmations.where(user_id: params[:current_user_id].to_i)
      end
      @assigned_issue_ids = @assigned_confirmations.map(&:issue_id)


      project_confirmations = if params[:confirm_group_by_project].present?
                                [[nil, @assigned_confirmations]]
                              else
                                @assigned_confirmations.group_by(&:project).sort_by{|p,i| p.name }
                              end

      @user_confirmations = if params[:confirm_group_by_user].present?
                                [[nil, project_confirmations]]
                            else
                                unless params[:confirm_group_by_project].present?
                                  @assigned_confirmations.group_by(&:user).sort_by{|p,i| p.name }.map{|user, confirmations|
                                    [user , confirmations.group_by(&:project).sort_by{|p,i| p.name }]
                                  }
                                else
                                  @assigned_confirmations.group_by(&:user).sort_by{|p,i| p.name }.map{|user, confirmations|
                                    [user , [[nil, confirmations]]]
                                  }
                                end
                              end


      @current_user = params[:current_user_id].nil? ? nil : User.where(id: params[:current_user_id]).first
      @current_user = nil unless @users.map(&:id).include?(@current_user.id) if @current_user

      @time_entries = TimeEntry.
       for_issues(@assigned_issue_ids).
        actual(@current_date, @current_date+6.days)
    end

    def authorized
      render_404 unless User.current.class == User
    end

    def require_planning_manager
      (render_403; return false) unless User.current.is_planning_manager?
    end

    def parse_google_start_date
      if ["(4i)", "(5i)"].all?{|i|
        params[:estimated_time]["google_start_time"+i]
      }
        google_start_time = ["(4i)", "(5i)"].map{ |i|
          params[:estimated_time].delete("google_start_time"+i)
        }.join(":")
        params[:estimated_time][:google_start_time] = Time.parse(google_start_time)
      end
    end

    def new_estimated_time
      parse_google_start_date if params[:estimated_time].present?
      @estimated_time = EstimatedTime.new(params[:estimated_time])
    end

    def find_estimated_time
      @estimated_time = EstimatedTime.find(params[:id])
    end

    def time_entry_month_sum

      hours_per_day = Setting[:plugin_redmine_planning][:work_hours_per_day].to_i
      min_ratio = Setting[:plugin_redmine_planning][:min_unfilled_percent].to_f / 100

      month = Time.now.all_month
      month_start, month_end = month.begin.to_date, month.end.to_date

      @today_spent_hours = TimeEntry.where(user_id: @current_user.id, tmonth: Time.now.month, tyear: Time.now.year).sum('hours')
      
      @today_possible_hours = (working_days(month_start, Date.tomorrow) * hours_per_day).to_f
      @today_min_possible_hours = @today_possible_hours * min_ratio

      @month_possible_hours = (working_days(month_start, month_end + 1.day) * hours_per_day).to_f
      @month_min_possible_hours = @month_possible_hours * min_ratio

      @time_delta = (@today_spent_hours - @today_min_possible_hours).to_f


    end

end
