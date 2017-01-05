module Columbo
  module Resource
    class Publisher

      def initialize(object)
        @object = object
      end

      def publish(event_type, options = {}, &block)
        begin
          publish_event(event_type, options, &block)
        rescue Exception => e
          Columbo.logger.warn(e.message)
          false
        end
      end

      def publish!(event_type, options = {}, &block)
        publish_event(event_type, options, &block)
      end

      private

      def publish_event(event_type, options, &block)
        @payload = OpenStruct.new(resource: {})
        block.call(@payload) if block_given?

        if Columbo.client.is_a? Columbo::Client::AMQP
          options = { routing_key: "#{@object.class.name.underscore}.#{event_type}" }.merge(options)
        end

        Columbo.client.publish(build_event, options)
      end

      def resource
        resource_label = @payload.resource[:label]
        if resource_label.nil?
          resource_label = @object.respond_to?(:columbo_resource_label) ? @object.columbo_resource_label : default_resource_label
        end

        resource_attributes = @payload.resource[:attributes]
        if resource_attributes.nil?
          resource_attributes = @object.respond_to?(:columbo_payload) ? @object.columbo_payload : @object.as_json
        end

        {
          uid: @payload.resource[:uid] || @object.id,
          type: @payload.resource[:type] || @object.class.name.underscore,
          label: resource_label,
          attributes: resource_attributes
        }
      end

      def system
        @payload.system || Columbo.configuration.system.to_h
      end

      def actor
        @payload.actor || @object.columbo_actor
      end

      def related_resources
        related_resources = @payload.related_resources
        if related_resources.nil?
          related_resources = @object.respond_to?(:columbo_related_resources) ? @object.columbo_related_resources : nil
        end
      end

      def default_resource_label
        "#{@object.class.name.underscore}##{@object.id}"
      end

      def build_event
        {
          system: system,
          actor: actor,
          resource: resource,
          related_resources: related_resources,
          timestamp: @payload.timestamp || DateTime.now.utc.to_formatted_s(:iso8601),
          action: @payload.action || "#{@object.class.name.underscore}.#{event_type}"
        }
      end
    end
  end
end
