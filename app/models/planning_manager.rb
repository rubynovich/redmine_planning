class PlanningManager < ActiveRecord::Base
  unloadable
  
  belongs_to :user

  validates_presence_of :user_id  
  validates_uniqueness_of :user_id
  
  def workers
    v = read_attribute(:workers)
    v = YAML::load(v) if v.is_a?(String)
    if v.present? && v.is_a?(Array)
      v.map do |i|
        begin
          User.find(i)
        rescue
          nil
        end
      end.compact
    else
      []
    end
  end

  def worker_ids
    workers.map(&:id)
  end

  def self.user_ids
#    begin
      all.select(&:user).map(&:user).sort.map(&:id)
#    rescue
#      all.map{|i| User.find(i) }.compact.sort.map(&:id)
#    end
  end

  def add_workers(array_ids)
    self.workers = (worker_ids+array_ids.map(&:to_i)).uniq
    self.save
  end
  
  def remove_worker(worker_id)
    self.workers = worker_ids-[worker_id.to_i]
    self.save
  end

  def workers=(v)
    v = v.to_yaml if v.present?
    write_attribute(:workers, v.to_s)
  end
end
