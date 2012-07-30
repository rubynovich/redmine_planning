class EstimatedTimesController < ApplicationController
  unloadable
  
  helper :timelog
  include TimelogHelper
  
  def index
    @current_date = if params[:current_date].blank? 
      Date.today
    else
      Date.parse(params[:current_date])
    end
    @current_date -= @current_date.wday.days - 1.day
    @current_user = User.current
    @current_dates = [@current_date-2.week, @current_date-1.week, @current_date, @current_date+1.week, @current_date+2.week]
    @assigned_issues = Issue.visible.open.find(:all, 
      :conditions => {
        :assigned_to_id => ([User.current.id] + User.current.group_ids)}, 
      :limit => 10, 
      :include => [ :status, :project, :tracker, :priority ], 
      :order => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date")
  end
  
  def create
      project_id = Issue.find(params[:estimated_time][:issue_id]).project.id
      plan_on = Date.parse(params[:estimated_time][:plan_on])
      tyear = plan_on.year
      tmonth = plan_on.month
      tweek = plan_on.cweek
      flash[:notice] = l(:notice_successful_create)      
      redirect_to :action => :index, :current_date => params[:current_date]
#      render :action => :index, :current_date => params[:current_date]
#    rescue
#      render_404      
  end
end
