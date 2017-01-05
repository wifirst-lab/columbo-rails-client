module Columbo
  module Resource
    module Callbacks
      def self.included(base)
        base.class_eval do
          after_create :publish_create_event
          after_update :publish_update_event
          after_destroy :publish_destroy_event
        end
      end

      %w(create update destroy).each do |action|
        define_method("publish_#{action}_event") do
          action_name = action == 'destroy' ? "#{action}ed" : "#{action}d"
          self.columbo.publish("#{action_name}")
        end
      end
    end
  end
end
