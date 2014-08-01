# -*- coding: utf-8 -*-
class PlanningConfirmationsController < ApplicationController
  unloadable

  def update_confirmer
  	confirmation_type = params[:type] == "0" ? :KGIP_confirmation : :head_confirmation
  	confirms = PlanningConfirmation.where(id: params[:id]).where(["date_start <= ? ", Date.today-1.week])
  	if confirm = confirms.first
	  	confirm.update_column(confirmation_type, params[:status].to_s == "1")
      if (! confirm.KGIP_confirmation) && (! confirm.head_confirmation)
        confirm.update_column(:hours, 0.0)
      else
        if (confirm.hours.to_f == 0.0) && (params[:hours].to_f > 0.0)
          confirm.update_column(:hours, params[:hours].to_f)
        end
      end
	  	confirm.save
	  end

  	render text: ''

  end
end