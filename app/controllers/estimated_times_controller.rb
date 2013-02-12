class EstimatedTimesController < ApplicationController
  unloadable

  before_filter :get_current_date
  before_filter :get_project
  before_filter :get_current_user
  before_filter :get_planning_manager
  before_filter :add_info, :only => [:new, :index, :edit, :update]
  before_filter :authorized
  before_filter :require_planning_manager
  before_filter :new_estimated_time, :only => [:new, :index, :create]
  before_filter :find_estimated_time, :only => [:edit, :update, :destroy]

  helper :timelog
  include TimelogHelper
  helper :sort
  include SortHelper
  helper :estimated_times
  include EstimatedTimesHelper

  def index
    respond_to do |format|
      format.html{ render :action => :index }
      format.csv{ send_data(index_to_csv, :type => 'text/csv; header=present', :filename => @current_date.strftime("planning_table_%Y-%m-%d_#{@current_user.login}.csv"))}
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
      if params[:estimated_time][:google_calendar].present?
        begin
          cal = Google::Calendar.new(
            :username => params[:estimated_time][:google_username],
            :password => params[:estimated_time][:google_password])
          time = params[:estimated_time][:google_start_time].
            seconds_since_midnight
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
    else
      add_info
      render :action => :new, :current_date => @current_date
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

    @assigned_issues = Issue.visible.
      find(:all,
        :conditions => {:assigned_to_id => ([@current_user.id] + @current_user.group_ids)},
        :include => [:status, :project, :tracker, :priority],
        :order => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date")


    @assigned_issue_ids = if params[:issue_id].present? &&
      (issue = Issue.visible.find(params[:issue_id]))

      [issue.id]
    else
      @assigned_issues.map(&:id)
    end

    @estimated_times = EstimatedTime.for_user(@current_user.id).for_issues(@assigned_issue_ids).all(:order => sort_clause)

    respond_to do |format|
      format.html{ render :action => :list }
      format.csv{ send_data(list_to_csv, :type => 'text/csv; header=present', :filename => Date.today.strftime("planning_list_%Y-%m-%d_#{@current_user.login}.csv"))}
    end
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

      @assigned_issues = Issue.visible.
        actual(@current_date, @current_date+6.days).
        in_project(@project).
        exclude_closed(params[:exclude_closed]).
        exclude_overdue(params[:exclude_overdue], @current_date).
        exclude_not_planned(params[:exclude_not_planned], @current_date).
        find(:all,
          :conditions => {:assigned_to_id => ([@current_user.id] + @current_user.group_ids)},
          :include => [:status, :project, :tracker, :priority],
          :order => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date")

      @project_issues = if params[:exclude_group_by_project].present?
        [[nil, @assigned_issues]]
      else
        @assigned_issues.group_by(&:project).sort_by{|p,i| p.name }
      end

      @assigned_issue_ids = @assigned_issues.map(&:id)

      @estimated_times = EstimatedTime.
        for_issues(@assigned_issue_ids).
        actual(@current_date, @current_date+6.days).
        for_user(@current_user.id)

      @estimated_time_sum = EstimatedTime.
        for_issues(@assigned_issue_ids).
        for_user(@current_user.id).
        group_by(&:issue_id)

      @time_entries = TimeEntry.
        for_issues(@assigned_issue_ids).
        actual(@current_date, @current_date+6.days).
        for_user(@current_user.id)

      @assigned_projects = Member.find(:all, :conditions => {:user_id => @current_user.id}).map{ |m| m.project }
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
end
