class EstimatedTimesController < ApplicationController
  unloadable
  
  before_filter :add_info, :only => [:new, :index]
  before_filter :authorized
  
  helper :timelog
  include TimelogHelper
  
  def index
    @estimated_time = EstimatedTime.new
  end

  def new
    @estimated_time = EstimatedTime.new(params[:estimated_time])
  end
  
  def edit
    add_info
    @estimated_time = EstimatedTime.find(params[:id])
  end
  
  def update
    @estimated_time = EstimatedTime.find(params[:id])
    if @estimated_time.update_attributes(params[:estimated_time])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => :index, :current_date => params[:current_date]
    else
      render :action => :edit, :current_date => params[:current_date]
    end
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
  end
  
  private
  
    def add_info
      @current_date = if params[:current_date].blank? 
        Date.today
      else
        Date.parse(params[:current_date])
      end      
      @current_date -= @current_date.wday.days - 1.day
      @current_user = if params[:current_user_id].present? &&
        User.current.allowed_to?(:change_current_user, nil, :global=>true)
        User.find(params[:current_user_id])
      else
        User.current
      end
      @current_dates = [@current_date-2.week, @current_date-1.week, @current_date, @current_date+1.week, @current_date+2.week]
      @project = if params[:project_id].present?
        Project.find_by_identifier(params[:project_id])
      end
       
#      Issue.class_eval do
#        named_scope :in_project, lambda { |project|
#          if project.present?
#            { :conditions => 
#              {
#                :project_id => project.id
#              }
#            }
#          end
#        }

#        named_scope :actual, lambda { |start_date, due_date|
#          if start_date.present? && due_date.present?
#            { :conditions => 
#                ["#{IssueStatus.table_name}.is_closed = :is_closed OR #{Issue.table_name}.start_date BETWEEN :start_date AND :due_date OR #{Issue.table_name}.due_date BETWEEN :start_date AND :due_date", {:is_closed => false, :start_date => start_date, :due_date => due_date}],
#              :include => :status
#            }
#          else
#            { :conditions => 
#                ["#{IssueStatus.table_name}.is_closed = :is_closed",
#                  {:is_closed => false}],
#              :include => :status
#            }            
#          end
#        }                  
#      end   
           
      @assigned_issues = Issue.visible.actual(@current_date, @current_date+6.days).in_project(@project).find(:all, 
        :conditions => {:assigned_to_id => ([@current_user.id] + @current_user.group_ids)}, 
        :include => [ :status, :project, :tracker, :priority ], 
        :order => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date")
      @assigned_projects = Member.find(:all, :conditions => {:user_id => @current_user.id}).map{ |m| m.project }

#    rescue
#      render_404
    end    
    
    def authorized
      render_404 unless User.current.class == User      
    end
end
