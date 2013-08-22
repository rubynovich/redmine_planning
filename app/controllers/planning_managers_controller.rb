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
    if params[:worker_ids]

      for worker_id in params[:worker_ids]
        
        @planning_manager.subordinates.create(principal_id: worker_id.to_i)        
        
        principal = Principal.find(worker_id.to_i)
        
        if principal.kind_of?(Group)
          for user in principal.users - [@planning_manager.user]
            @planning_manager.subordinates.create(principal_id: user.id)
          end
        end
      
      end
    end
    redirect_to :action => 'edit', :id => params[:id]
  end

  def create
    principals = Principal.find(params[:manager_ids])
    for principal in principals
      if principal.kind_of?(Group)
        principal.users.each{|user| PlanningManager.create(:user_id => user.id)}
      else
        PlanningManager.create(:user_id => principal.id)
      end
    end
    redirect_to :action => 'index'
  end

  def destroy
    if params[:id].present?
      if params[:worker_id].present?
        principal = Principal.find(params[:worker_id].to_i)
        if principal.kind_of?(User)
          @planning_manager.subordinates.where(principal_id: params[:worker_id]).first.destroy  
        else
          @planning_manager.subordinates.where(principal_id: principal.id).first.destroy
          @planning_manager.subordinates.where(principal_id: principal.users.map(&:id)).map(&:destroy)
        end
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
      # fixme
      find_planning_manager
      @worker_candidates = Principal.not_workers(@planning_manager).like(params[:q]).all(:order => "lastname, firstname")
    end
end
