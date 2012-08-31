class PlanningManagersController < ApplicationController
  unloadable
  layout 'admin'

  before_filter :require_admin  

  def index
    @planning_managers = PlanningManager.all(:order => "users.lastname, users.firstname", :include => :user)
  end  
    
  def edit
    @planning_manager = PlanningManager.find(params[:id])
  end
  
  def update
    @planning_manager = PlanningManager.find(params[:id])
    @planning_manager.add_workers(params[:worker_ids])
    
    redirect_to :action => 'edit', :id => params[:id]
  end
  
  def create
    users = User.find(params[:manager_ids])
    users.each do |user|
      PlanningManager.create(:user_id => user.id)
    end
    redirect_to :action => 'index'
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
