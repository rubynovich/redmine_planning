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
      :order => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.updated_on DESC")
  end
end
