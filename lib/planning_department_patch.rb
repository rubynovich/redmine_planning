require_dependency 'department'

module PlanningPlugin
  module DepartmentPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable


        after_update :change_head_planning
        after_create :change_head_planning
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def change_head_planning
        PlanningConfirmation.change_head_planning(self)
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
