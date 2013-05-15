class PlanningManagersController < ApplicationController
  unloadable
  layout 'admin'

  before_filter :require_admin
  before_filter :find_planning_manager, :only => [:edit, :update, :destroy]
  before_filter :find_manager_candidates, :only => [:index, :autocomplete_for_manager]
  before_filter :find_worker_candidates, :only => [:edit, :autocomplete_for_worker]

  def index
    @planning_managers = PlanningManager.all(:order => "users.lastname, users.firstname", :include => :user).select(&:user)
  end

  def edit
  end

  def update
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

  def autocomplete_for_manager
    render :layout => false
  end

  def autocomplete_for_worker
    render :layout => false
  end

  private
    def find_planning_manager
      @planning_manager = PlanningManager.find(params[:id])
    end

    def find_manager_candidates
      @manager_candidates = User.active.not_planning_managers.like(params[:q]).all(:order => "lastname, firstname")
    end

    def find_worker_candidates
      find_planning_manager
      @worker_candidates = User.active.not_workers(@planning_manager).planning_managers.like(params[:q]).all(:order => "lastname, firstname")
    end
end
