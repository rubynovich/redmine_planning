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
  
  def edit
    @planning_manager = PlanningManager.find(params[:id])
  end
  
  def update
    @planning_manager = PlanningManager.find(params[:id])
    @planning_manager.add_workers(params[:worker_ids])
    
    respond_to do |format|
      format.html { redirect_to :action => 'edit', :id => params[:id]}
      format.js {
        render(:update) {|page|
          page.replace_html "content-users", :partial => 'worker'
          users.each {|user| page.visual_effect(:highlight, "user-#{user.id}") }
        }
      }
    end  
  end
  
  def create
    if params[:worker_ids].present?
#      users = User.find(params[:user_ids])
#      users.each do |user|
#        HrMember.create(:user_id => user.id)
#      end if request.post?
#      respond_to do |format|
#        format.html { redirect_to :action => 'index'}
#        format.js {
#          render(:update) {|page|
#            page.replace_html "content-users", :partial => 'worker'
#            users.each {|user| page.visual_effect(:highlight, "user-#{user.id}") }
#          }
#        }
#      end  
    elsif params[:manager_ids].present?
      users = User.find(params[:manager_ids])
      users.each do |user|
        PlanningManager.create(:user_id => user.id)
      end if request.post?
      respond_to do |format|
        format.html { redirect_to :action => 'index'}
        format.js {
          render(:update) {|page|
            page.replace_html "content-users", :partial => 'manager'
            users.each {|user| page.visual_effect(:highlight, "user-#{user.id}") }
          }
        }
      end
    else
      redirect_to :action => 'index'
    end
  end  
  
  def destroy
    if params[:id].present?
      @planning_manager = PlanningManager.find(params[:id])
      if params[:worker_id].present?
        @planning_manager.remove_worker(params[:worker_id])        
        redirect_to :action => 'edit', :id => params[:id]
      else
        @planning_manager.destroy
        redirect_to :action => 'index'
      end
    else
      redirect_to :action => 'index'
    end
  end
end
