class PlanningPreferencesController < ApplicationController
  unloadable

  #  include Rails.application.routes.url_helpers

  before_filter :require_login, :only => [:save]

  helper :estimated_times
  include EstimatedTimesHelper

  def save
    user = User.current
    user_preferences = user.planning_preference || user.build_planning_preference
    
    permitted_keys = exclude_filters.map{|f| 'exclude_'+f.to_s}
    user_preferences.preferences = params.select{|k,v| permitted_keys.include?(k)}
    unless user_preferences.save
      Rails.logger.error('  Could not save PlanningPreferences for user with id #{user.id}'.red)
    end

    # render text: params.keys.inspect

    render nothing: true

  end

  def drop
    user = User.current
    if user_preferences = user.planning_preference
      unless user_preferences.destroy
        Rails.logger.error('  Could not destroy PlanningPreferences for user with id #{user.id}'.red)
      end
    end

    # render nothing: true

    redirect_to estimated_times_path(params.keep_if{|k,v| not(k =~ /^exclude/)})



  end


end
