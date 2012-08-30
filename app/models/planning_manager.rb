class PlanningManager < ActiveRecord::Base
  unloadable
  
  belongs_to :user
  
  validates_uniqueness_of :user_id
  
  def workers
    v = read_attribute(:workers)
    v = YAML::load(v) if v.is_a?(String)
    v = if v.present?
      User.find(v) 
    else
      []
    end
    v
  end

  def workers=(v)
    v = v.to_yaml if v.present?
    write_attribute(:workers, v.to_s)
  end
    
end
