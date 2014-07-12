# -*- coding: utf-8 -*-
class PlanningConfirmationsController < ApplicationController
  unloadable

  def update_confirmer
  	#Rails.logger.error("update_confirmer params = ".red + params.inspect.red)
  	confirmation_type = params[:type] == "0" ? :KGIP_confirmation : :head_confirmation 
  	#issue_id = params[:id]# => issue,
  	#user_id = params[:user_id]
  	#date_start = params[:start_date]# => @current_date
  	confirms = PlanningConfirmation.where(id: params[:id]).where(["date_start <= ? ", Date.today-1.week])
  	if confirms.any?
	  	column_value = confirms.map(&confirmation_type)[0]
	  	confirms[0].update_column(confirmation_type, !column_value)
      if (! confirms[0].KGIP_confirmation) && (! confirms[0].head_confirmation)
        confirms[0].update_column(:hours, 0.0)
      else
        if (confirms[0].hours.to_f == 0.0) && (params[:hours].to_f > 0.0)
          confirms[0].update_column(:hours, params[:hours].to_f)
        end
      end
	  	confirms[0].save
	  end

  	render text: ''

  end
end