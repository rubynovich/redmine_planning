# -*- coding: utf-8 -*-
class PlanningConfirmationsController < ApplicationController
  unloadable

  def update_confirmer
  	confirmation_type = params[:type] == "0" ? :kgip_confirmation : :head_confirmation
    @ctype = params[:type] == "0" ? 0 : 1
    @confirm ||= PlanningConfirmation.where(id: params[:id]).where(["date_start <= ? ", Date.today-1.week]).first
  	if @confirm
	  	@confirm.update_column(confirmation_type, params[:status].to_s == "1")
      if (! @confirm.kgip_confirmation) && (! @confirm.head_confirmation)
        @confirm.update_column(:hours, 0.0)
        TimeEntry.where(tyear: @confirm.date_start.year, tweek: @confirm.date_start.cweek).update_all(is_confirmed: false)
      else
        if (@confirm.hours.to_f == 0.0) && (params[:hours].to_f > 0.0)
          @confirm.update_column(:hours, params[:hours].to_f)
          if (@confirm.kgip_confirmation || @confirm.kgip_confirmation.nil?) && (@confirm.head_confirmation || @confirm.head_confirmation.nil?)
            TimeEntry.where(tyear: @confirm.date_start.year, tweek: @confirm.date_start.cweek).update_all(is_confirmed: true)
          end
        end
      end
      @is_confirmation = params[:status].to_s == "1"
	  	@confirm.save
      @comment = @confirm.planning_confirmation_comments.build
	  end
  end

  def  create_confirmation
    if (@user = User.where(id: params[:user_id]).first) && (@issue = Issue.where(id:  params[:issue_id]).first)
      @head_id = @user.must_head_confirm ? PlanningConfirmation.get_head_id(@user.id) : nil
      @kgip_id = @user.must_kgip_confirm ? PlanningConfirmation.get_kgip_id(@issue.project_id) : nil
      if @head_id || @kgip_id
        @confirm = PlanningConfirmation.create(
              user_id: @user.id,
              issue_id: @issue.id,
              head_id: @head_id,
              kgip_id: @kgip_id,
              date_start: Date.parse(params[:date_start]).beginning_of_week)
        update_confirmer
      end
    end
  end

  def create_comment
    if params[:planning_confirmation_comment] && params[:planning_confirmation_comment][:comment].present? && (@confirm = PlanningConfirmation.where(id: params[:id]).first)
      @comment = @confirm.planning_confirmation_comments.build(params[:planning_confirmation_comment])
      @comment.save
      @ctype = @comment.confirmation_type
      @is_confirmation = @comment.is_confirmation
    end
  end

end