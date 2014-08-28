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
        TimeEntry.where(tyear: confirm.date_start.year, tweek: confirm.date_start.cweek).update_all(is_confirmed: false)
      else
        if (confirm.hours.to_f == 0.0) && (params[:hours].to_f > 0.0)
          confirm.update_column(:hours, params[:hours].to_f)
          if (confirm.KGIP_confirmation || confirm.KGIP_confirmation.nil?) && (confirm.head_confirmation || confirm.head_confirmation.nil?)
            TimeEntry.where(tyear: confirm.date_start.year, tweek: confirm.date_start.cweek).update_all(is_confirmed: true)
          end
        end
      end
	  	confirm.save
	  end

  	render text: ''

  end
end