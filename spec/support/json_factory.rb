
module JsonFactory

  module Utils
    class << self
      def apply_attributes(json,ar,*attribs)
        attribs.inject(json) { |a,v| a[v.to_s.camelize(:lower)] = ar.attributes[v.to_s] ; a }
        self
      end
      def apply_defaults(json,ar=nil)
        json["format"] = :json
        self
      end
    end
  end

  module User
    class << self
      def update(job)
        json = {}.tap do |json|
          JsonFactory::Utils.apply_defaults(json)
          json["preferences"] = { "pref1" => "val1", "pref2" => "val2" }
        end
        yield json if block_given?
        json
      end
    end
  end

  module Monitor
    class << self
      def create
        {}.tap do |json|
          json["metrics"] = "blah.blah.blah"
          json["format"] = :json
          json["monitorExpr"] = "abc"
          json["minutes"] = 1
          json["toDate"] = "now"
        end
      end
    end
  end

  module Job
    class << self
      def create(job)
        {}.tap do |json|
          JsonFactory::Utils.apply_attributes(json,job,:user_id,:name,:active,:alert_keys,:cron_expr,:error_timeout,:minutes,:metrics,:monitor_expr,:to_date,:description).apply_defaults(json,job)
          json["dashboard_id"] = job.app_id
          yield json if block_given?
        end
      end
      def update(job)
        json = self.create(job)
        json["id"] = job.id
        yield json if block_given?
        json
      end
    end
  end

  module Dashboard
    class << self
      def create(dashboard)
        {}.tap do |json|
          JsonFactory::Utils.apply_attributes(json,dashboard,:user_id,:name).apply_defaults(json,dashboard)
          yield json if block_given?
        end
      end
    end
  end

end
