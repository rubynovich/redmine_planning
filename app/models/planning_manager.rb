class PlanningManager < ActiveRecord::Base
  unloadable
  
  belongs_to :user

  validates_presence_of :user_id  
  validates_uniqueness_of :user_id
  
  def workers
    v = read_attribute(:workers)
    v = YAML::load(v) if v.is_a?(String)
    v = if v.present? && v.is_a?(Array)
      v.map{ |i| User.find(i) }.compact
    else
      []
    end
    v
  end

  def worker_ids
    workers.map(&:id)
  end

  def self.user_ids
    all.map{|i| User.find(i) }.compact.sort.map(&:id)
  end

  def add_workers(array_ids)
    self.workers = (worker_ids+array_ids).uniq
    self.save
  end
  
  def remove_worker(id)
    self.workers = worker_ids-[id]
    self.save
  end

  def workers=(v)
    v = v.to_yaml if v.present?
    write_attribute(:workers, v.to_s)
  end
end
