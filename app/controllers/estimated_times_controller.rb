class EstimatedTimesController < ApplicationController
  unloadable
  
  before_filter :get_current_date
  before_filter :get_project
  before_filter :get_current_user
  before_filter :get_planning_manager
  before_filter :add_info, :only => [:new, :index, :edit, :update]
  before_filter :authorized
  before_filter :require_planning_manager  
  
  helper :timelog
  include TimelogHelper
  helper :sort
  include SortHelper  
  helper :estimated_times
  include EstimatedTimesHelper
  
  def index
    @estimated_time = EstimatedTime.new
    
    respond_to do |format|
      format.html{ render :action => :index }
      format.csv{ send_data(index_to_csv, :type => 'text/csv; header=present', :filename => @current_date.strftime("planning_table_%Y-%m-%d_#{@current_user.login}.csv"))}
    end
  end

  def new
    @estimated_time = EstimatedTime.new(params[:estimated_time])
  end
  
  def edit
    @estimated_time = EstimatedTime.find(params[:id])
  end
  
  def update
      @estimated_time = EstimatedTime.find(params[:id])
      if params[:estimated_time][:hours].to_f <= 0.0      
        flash[:notice] = l(:notice_successful_delete) if @estimated_time.destroy
        redirect_to :action => :index, :current_date => @current_date
      elsif @estimated_time.update_attributes(params[:estimated_time])
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => :index, :current_date => @current_date
      else
        render :action => :edit, :current_date => @current_date
      end    
    rescue
      render_403
  end
  
  def create
      @estimated_time = EstimatedTime.new(params[:estimated_time])  
      if @estimated_time.present? && @estimated_time.save
        flash[:notice] = l(:notice_successful_create)      
        redirect_to :action => :index, :current_date => @current_date
      else
        add_info
        render :action => :new, :current_date => @current_date
      end
  end
  
  def destroy
      if (estimated_time = EstimatedTime.find(params[:id]))
        flash[:notice] = l(:notice_successful_delete) if estimated_time.destroy
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
end
