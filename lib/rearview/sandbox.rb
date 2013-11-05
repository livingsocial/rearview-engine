
module Rearview
  module Sandbox
    class << self

      include Rearview::Logger

      def valid?
        valid_exec = self.valid_exec?
        valid_graphite_connection = self.valid_graphite_connection?
        valid_exec && valid_graphite_connection
      end

      def valid_exec?
        script_file = File.join(Rearview.config.sandbox_dir,"verify_sandbox.rb")
        cmd = Rearview.config.sandbox_exec.clone << script_file
        logger.info "#{self} checking sandbox with #{cmd}"
        process_builder = ProcessBuilder.new(cmd).redirectErrorStream(true)
        process_builder.directory(java.io.File.new(Rearview.config.sandbox_dir.to_s))
        process_builder.environment.delete("GEM_HOME")
        process_builder.environment.delete("GEM_PATH")
        process = process_builder.start
        exit_code = process.waitFor
        output = process.get_input_stream.to_io.read
        logger.info "#{self} sandbox execution: \n#{output}"
        unless exit_code == 0
          logger.error "#{self} unable to execute in sandbox"
        end
        exit_code == 0
      end

      def valid_graphite_connection?
        url = "#{Rearview.config.graphite_url}/dashboard"
        logger.info "#{self} checking graphite connection to #{url}"
        response = HTTParty.get(url)
        unless response.code == 200
          logger.error "#{self} unable to communicate with graphite"
        end
        response.code == 200
      rescue
        logger.error "#{self} unable to communicate with graphite #{$!}"
        false
      end

    end
  end
end
