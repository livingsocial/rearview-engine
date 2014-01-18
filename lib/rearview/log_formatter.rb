# copied from logger.rb
module Rearview
  class LogFormatter
    Format = "%s, [%s#%d/%s] %5s -- %s: %s\n"

    attr_accessor :datetime_format

    def initialize
      @datetime_format = nil
    end

    def call(severity, time, progname, msg)
      thread_name = java.lang.Thread.currentThread.getName
      default_name = ( progname.present? ? progname : "Rearview" )
      Format % [severity[0..0],format_datetime(time),$$,thread_name,severity,default_name,msg2str(msg)]
    end

  private

    def format_datetime(time)
      if @datetime_format.nil?
        time.strftime("%Y-%m-%dT%H:%M:%S.") << "%06d " % time.usec
      else
        time.strftime(@datetime_format)
      end
    end

    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        "#{ msg.message } (#{ msg.class })\n" <<
          (msg.backtrace || []).join("\n")
      else
        msg.inspect
      end
    end
  end
end
