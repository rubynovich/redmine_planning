require_dependency 'department'

module PlanningPlugin
  module DepartmentPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable


        before_update :set_old_attributes
        before_create :reset_old_attributes


        after_update :change_head_planning
        after_create :change_head_planning
      end
    end

    module ClassMethods
    end

    module InstanceMethods

      def set_old_head_id
        @old_attributes = self.attributes
      end

      def reset_old_attributes
        @old_attributes = {}
      end

      def change_head_planning
        PlanningConfirmation.sidekiq_delay.change_head_planning(self) if (!@old_attributes) || (@old_attributes["confirmer_id"] != self.confirmer_id) || (@old_attributes["head_id"] != self.head_id)
      end

      def all_children
        all = []
        self.children.each do |category|
          all << category
          root_children = category.all_children.flatten
          all << root_children unless root_children.empty?
        end
        return all.flatten
      end


    end
  end
end
