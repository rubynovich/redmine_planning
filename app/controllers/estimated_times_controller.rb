class EstimatedTimesController < ApplicationController
  unloadable
  
  before_filter :add_info, :only => [:new, :index]
  
  helper :timelog
  include TimelogHelper
  
  def index
    @estimated_time = EstimatedTime.new
  end

  def new
    @estimated_time = EstimatedTime.new(params[:estimated_time])
  end
  
  def create
      @estimated_time = EstimatedTime.new(params[:estimated_time])  
      if @estimated_time.present? && @estimated_time.save
        flash[:notice] = l(:notice_successful_create)      
        redirect_to :action => :index, :current_date => params[:current_date]
      else
        add_info
        render :action => :new, :current_date => params[:current_date]
      end
#    rescue
#      render_404      
  end
  
  private
  
    def add_info
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
end
