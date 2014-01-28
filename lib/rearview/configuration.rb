require 'optparse'
require 'pry'

module Rearview
  class Configuration

    include ActiveModel::Model

    class UrlValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        passed = true
        if value.present?
          uri = URI.parse(value) rescue nil
          unless uri.present? && uri.scheme.present? && (uri.scheme.downcase=="http" || uri.scheme.downcase=="https")
            record.errors.add attribute, (options[:message] || "is not a valid URL")
            passed = false
          end
        end
        passed
      end
    end

    class DirectoryValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        passed = true
        if value.present?
          unless File.directory?(value)
            record.errors.add attribute, (options[:message] || "is not a directory")
            passed = false
          end
        end
      end
    end

    ATTRIBUTES = [:default_from, :graphite_connection, :pagerduty_url, :sandbox_exec,
                  :sandbox_timeout, :sandbox_dir, :enable_alerts, :preload_jobs,
                  :logger, :enable_monitor, :verify, :default_url_options,
                  :authentication, :enable_stats, :statsd_connection]

    attr_accessor *ATTRIBUTES

    validates :graphite_connection, presence: true
    validates :pagerduty_url, presence: true, url: true
    validates :default_from, presence: true
    validates :default_url_options, presence: true
    validates :sandbox_dir, presence: true, directory: true
    validates :sandbox_exec, presence: true
    validates :sandbox_timeout, presence: true, numericality: { greater_than: 4 }
    validates :authentication, presence: true
    validates :statsd_connection, presence: true, if: -> { self.stats_enabled? }

    validate :validate_sandbox_execution
    validate :validate_graphite_connection

    def initialize(attributes={})
      @default_from = "rearview@localhost"
      @sandbox_timeout = 5
      @enable_alerts = true
      @preload_jobs = true
      @verify = false
      @enable_monitor = true
      @authentication = { strategy: :database }
      @enable_stats = false
      @default_url_options = {:host=>"localhost",:port=>"3000"}
      @pagerduty_url = "https://events.pagerduty.com/generic/2010-04-15/create_event.json"
      @graphite_connection = {}
      super
    end

    def alerts_enabled?
      enable_alerts
    end

    def monitor_enabled?
      enable_monitor
    end

    def preload_jobs?
      preload_jobs
    end

    def stats_enabled?
      enable_stats
    end

    def verify?
      verify
    end

    def with_argv(argv)
      OptionParser.new do |opts|
        opts.on("--[no-]preload", "Enable/disable job loading")  { |v| self.preload_jobs = v }
        opts.on("--[no-]alerts", "Enable/disable alerts")  { |v| self.enable_alerts = v }
        opts.on("--[no-]monitor", "Enable/disable monitor")  { |v| self.enable_monitor = v }
        opts.on("--[no-]verify", "Enable/disable verification")  { |v| self.verify = v }
      end.parse!(argv)
    end

    def validate_sandbox_execution
       script_file = File.join(sandbox_dir,"verify_sandbox.rb")
       cmd = sandbox_exec.clone << script_file
       process_builder = ProcessBuilder.new(cmd).redirectErrorStream(true)
       process_builder.directory(java.io.File.new(sandbox_dir.to_s))
       process_builder.environment.delete("GEM_HOME")
       process_builder.environment.delete("GEM_PATH")
       process = process_builder.start
       exit_code = process.waitFor
       output = process.get_input_stream.to_io.read
       exit_code == 0
    end

    def validate_graphite_connection
      if graphite_connection.present?
        if !graphite_connection[:url].present?
          self.errors.add(:graphite_connection, "graphite URL can't be blank")
        else
          url_validator = UrlValidator.new({ attributes: [:graphite_connection], message: "does not contain a valid URL" })
          if url_validator.validate_each(self,:graphite_connection,graphite_connection[:url])
            client = Graphite::Client.new(graphite_connection)
            binding.pry
            unless(client.reachable?)
              self.errors.add(:graphite_connection, "graphite cannot be reached")
            end
          end
        end
      end
    end

    def dump
      ATTRIBUTES.sort.map { |attrib| "#{attrib.to_s}=#{(self.send(attrib).nil? ? "nil" : self.send(attrib))}" }.join("\n")
    end

  end
end

