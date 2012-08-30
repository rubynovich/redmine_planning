class PlanningManagersController < ApplicationController
  unloadable
  layout 'admin'

  before_filter :require_admin  

  def index
    @planning_managers = PlanningManager.all.sort_by{ |pm| pm.user.name }
  end
  
  def new
    @planning_manager = PlanningManager.new
    @candidates = User.active.not_planning_managers.all(:order => "lastname, firstname")
  end
  
  def create
    @planning_manager = PlanningManager.new(params[:planning_manager])
    if @planning_manager.save
      flash[:notice] = l(:notice_successful_create)
    end
    
    respond_to do |format|
      format.html { redirect_to :action => 'index'}
#      format.js {
#        render(:update) {|page|
#          page.replace_html "content-users", :partial => 'users'
#          users.each {|user| page.visual_effect(:highlight, "user-#{user.id}") }
#        }
#      }
    end
  end  
end
