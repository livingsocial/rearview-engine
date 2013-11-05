module Rearview
  module Ext
    module StateMachine
      extend ActiveSupport::Concern
      included do
        attr_accessor :event_data
      end

      def fire_event(name,event_data={})
        self.event_data = event_data
        fire_events(name)
      end
    end
  end
end
