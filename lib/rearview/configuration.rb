require 'optparse'
require 'pry'

module Rearview
  class Configuration

    include ActiveModel::Model

    class UrlValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        if value.present?
          uri = URI.parse(value) rescue nil
          unless uri.present? && uri.scheme.present? && (uri.scheme.downcase=="http" || uri.scheme.downcase=="https")
            record.errors.add attribute, (options[:message] || "is not a valid URL")
          else
            if options[:reachable]
              reachable = ReachableValidator.new(options.dup.merge(attributes: @attributes))
              reachable.validate_each(record,attribute,value)
            end
          end
        end
      end
    end

    class ReachableValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        if value.present?
          response = HTTParty.get(value) rescue nil
          unless response.present? && response.code == 200
            record.errors.add attribute, (options[:message] || "is not a reachable URL")
          end
        end
      end
    end

    class DirectoryValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        if value.present?
          unless File.directory?(value)
            record.errors.add attribute, (options[:message] || "is not a directory")
          end
        end
      end
    end

    ATTRIBUTES = [:default_from, :graphite_url, :pagerduty_url, :sandbox_exec,
      :sandbox_timeout, :sandbox_dir, :enable_alerts, :preload_jobs, :logger, :enable_monitor, :verify]

    attr_accessor *ATTRIBUTES

    validates :graphite_url, presence: true, url: { reachable: true }
    validates :pagerduty_url, presence: true, url: true
    validates :default_from, presence: true
    validates :sandbox_dir, presence: true, directory: true
    validates :sandbox_exec, presence: true
    validates :sandbox_timeout, presence: true, numericality: { greater_than: 4 }

    validate :validate_sandbox_execution

    def initialize(attributes={})
      @default_from = "rearview@localhost"
      @sandbox_timeout = 5
      @enable_alerts = true
      @preload_jobs = true
      @verify = false
      @enable_monitor = true
      @pagerduty_url = "https://events.pagerduty.com/generic/2010-04-15/create_event.json"
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

    def dump
      ATTRIBUTES.sort.map { |attrib| "#{attrib.to_s}=#{(self.send(attrib).nil? ? "nil" : self.send(attrib))}" }.join("\n")
    end

  end
end

