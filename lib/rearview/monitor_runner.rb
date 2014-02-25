require 'active_support'
require 'date/format'
require 'json'
require 'time'

java_import "java.lang.ProcessBuilder"

class GraphiteException < Exception; end
class GraphiteMetricException < Exception; end

module Rearview
  class MonitorRunner
    @@DEFAULT_MINUTES = 60
    @@monitor_script = nil
    @@utilities_script = nil
    @@sandbox_utils_template = "#{Rearview::Engine.root}/lib/rearview/templates/utilities.rb"
    @@sandbox_monitor_template = "#{Rearview::Engine.root}/lib/rearview/templates/monitor.rb"
    class << self

      include Rearview::Logger

      # Main worker method whic fetches data then calls eval
      def run(metrics,
              monitor_expr = nil,
              minutes      = nil,
              namespace    = {},
              verbose      = false,
              to_date      = nil,
              immediate = false)
        logger.debug "#{self} run"
        begin
          data = fetch_data(metrics, minutes, to_date)
          if !data.empty?
            namespace.merge!({ :minutes => minutes.nil? ? @@DEFAULT_MINUTES : minutes.to_i })
            eval(data, monitor_expr, namespace, verbose, immediate)
          end
        rescue Exception => e
          logger.error("Monitor failure #{e.message}\n#{e.backtrace.join("\n")}")
          handleError(e)
        end
      end

      def monitor_script
        unless(@@monitor_script)
          @@monitor_script = open(@@sandbox_monitor_template).read
        end
        @@monitor_script
      end

      def utilities_script
        unless(@@utilities_script)
          @@utilities_script = open(@@sandbox_utils_template).read
        end
        @@utilities_script
      end

      # Handles building a graphite API uri, issuing the request and parsing the result into a TimeSeries.
      # FYI, I just killed a monitor which was fetching a shitload of data and spiking rearview's memory.
      # I think you ought to make it a priority to move the graphite call into the monitor_template so it's
      # not within the same proc as the main server....
      def fetch_data(metrics, minutes = nil, to_date = nil)
        logger.debug "#{self} fetch_data"
        encMetrics = metrics.delete_if { |m| m.empty? }.map { |m| URI.escape(m) }
        from, to   = create_from_to_dates(minutes, to_date)
        params = {}.tap do |h|
          h["from"] = from
          h["until"] = to
          h["format"] = "raw"
          h["target"] = metrics.delete_if { |m| m.empty? }
        end

        begin
          response = Graphite::Client.new(Rearview.config.graphite_connection).render(params)
          case response.status
          when 200
            Graphite::RawParser.parse(response.body)
          else
            message = response.body
            logger.error("Graphite request failure: #{message}")
            raise GraphiteMetricException.new(message)
          end
        rescue Exception => e
          logger.error e
          raise e
        end
      end

      def eval(data, expr = nil, initial_ns = {}, verbose = false, immediate = false)
        logger.debug "#{self} eval"
        # prepare variable map for the monitor process
        namespace = create_namespace(data, initial_ns)

        # spawn the monitor and return the JSON result
        result = exec_process(expr, namespace,immediate)

        # # Use monitor-generated graph or create a default
        graph_data = result[:graph_data]
        output     = result[:output]
        error      = result[:error]

        graph_data = if graph_data.nil? or graph_data.empty?
                       default_graph_data(data)
                     else
                       graph_data
                     end

        status = if error
                   if error.index("Timeout Error") or error.index("Insecure operation")
                     "security_error"
                   else
                     "failed"
                   end
                 else
                   "success"
                 end

        {
          :monitor_output => {
            :status     => status,
            :output     => output,
            :graph_data => graph_data
          },
          :message => error,
          :data => data
        }
      end

      def exec_process(expr = "", namespace = {}.to_json, immediate=false)
        logger.debug "#{self} exec_process"

        # create script template
        script_text = self.monitor_script % {utilities: self.utilities_script, expression: expr, timeout: Rearview.config.sandbox_timeout, namespace: namespace}
        script_file = Tempfile.new("monitor_script",Rearview.config.sandbox_dir.to_s)
        script_file.sync = true
        script_file.write(script_text)
        cmd = Rearview.config.sandbox_exec.clone << script_file.path
        logger.info "#{self} exec_process #{cmd}"

        # setup process
        process_builder = ProcessBuilder.new(cmd).redirectErrorStream(true)
        process_builder.directory(java.io.File.new(Rearview.config.sandbox_dir.to_s))
        process_builder.environment.delete("GEM_HOME")
        process_builder.environment.delete("GEM_PATH")
        process_builder.environment.delete("BUNDLE_BIN_PATH")
        process_builder.environment.delete("BUNDLE_GEMFILE")

        # run process
        exit_code = nil
        output = nil
        process = nil
        begin
          logger.info "#{self} exec_process start"
          process = process_builder.start
          exit_code = Celluloid::Future.new { process.wait_for }.value(Rearview.config.sandbox_timeout)
          output  = process.get_input_stream.to_io.read
        rescue Celluloid::TimeoutError => e
          exit_code = 1
          process.destroy rescue nil
          output = "Execution of script timed out in #{Rearview.config.sandbox_timeout}s"
        rescue Exception => e
          exit_code = 2
          output = e.message
        end

        # handle results
        if exit_code == 0
          begin
            JSON.parse(output).to_hash.symbolize_keys
          rescue Exception => e
            { :graph_data => nil, :output => output.to_s, :error => e.message }
          end
        else
          { :graph_data => nil, :output => output, :error => output }
        end

      ensure
        script_file.close
        script_file.unlink
      end


      # Populates the NS will vars passed in initialNS. Also plops the data in @timeseries
      def create_namespace(data, initial_ns)
        # Build the namespace with all the prepped tuples above
        init = initial_ns.map { |kv| ["@" + kv.first.to_s, kv.last] }.flatten
        ns = Hash[*init]
        { "@timeseries" => data }.merge(ns).to_json
      end

      def default_graph_data(data)
        data.map do |ts|
          {
            ts.first[:metric] => ts.map do |dp|
              value = dp[:value]
              [ dp[:timestamp], value.nil? ? nil : value.to_f ]
            end
          }
        end
      end

      # Helper to create an AnalysisResult from an Exception.
      def handleError(e)
        # these should probably become some sort of class
        status = case e.class
                 when GraphiteMetricException
                   "graphite_metric_error"
                 when GraphiteException
                   "graphite_error"
                 else
                   "error"
                 end

        message = e.message

        output  = {
          :status     => status,
          :output     => message,
          :graph_data => nil
        }

        {
          :status  => status,
          :output  => output,
          :message => message,
          :data    => nil
        }
      end

      def normalize_results(results)
        normalized = { status: "error", output: nil, graph_data: nil }
        unless results.nil?
          if results[:monitor_output]
            normalized[:status] = results[:monitor_output][:status]
            normalized[:output] = results[:monitor_output][:output]
            if results[:monitor_output][:graph_data].present?
              normalized[:graph_data] = if results[:monitor_output][:graph_data].kind_of?(Array)
                results[:monitor_output][:graph_data].inject({}) do |acc,v|
                  v.each { |k,v| acc[k] = v }
                  acc
                end
              else
                results[:monitor_output][:graph_data]
              end
            end
          elsif results[:output]
            if results[:output][:status].present?
              normalized[:status] = results[:output][:status]
            end
            if results[:output][:output].present?
              normalized[:output] = results[:output][:output]
            end
          end
        end
        normalized
      end

      def create_from_to_dates(minutes = nil, to_date = nil)
        logger.debug "#{self}#create_from_to_dates minutes:#{minutes} to_date:#{to_date}"
        graphite_date_format = '%H:%M_%Y%m%d'
        incoming_date_format = '%m/%d/%Y %H:%M'
        mins = minutes.nil? ? @@DEFAULT_MINUTES : minutes.to_i
        if to_date == "now" || to_date.nil?
          now = Time.now.gmtime
        else
          now = DateTime.strptime(to_date, incoming_date_format)
        end
        to = (now - 1.minutes).strftime(graphite_date_format)
        from = (now - (mins + 1).minutes).strftime(graphite_date_format)
        logger.debug "#{self}#create_from_to_dates from:#{from} to:#{to}"
        [from,to]
      end

    end
  end
end
