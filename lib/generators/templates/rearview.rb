require 'rearview'

Rearview.configure do |config|

  config.logger = Rails.logger
  config.sandbox_dir = Rails.root + "sandbox"

  # Authentication support
  # Support for authentication in rearview is via devise, so while any devise supported
  # strategies will work, pre-wired support for the following strategies is included:
  #
  # :database - authenticate against the database
  # :google_oauth2 - authenticate using google oauth2
  # :custom - if you want to configure devise and Rearview::User model to use a different strategy
  #
  # For :google_oauth2 you need to include an option for matching email addresses/domains
  # ex:
  # config.authentication = { strategy: :google_oauth2, matching_emails: /@mycompany\.com$/ }
  #
  config.authentication = { strategy: :database }

  # Configure the path to a ruby 1.9.3 binary that will be used to execute your
  # monitor script in the sandbox.
  # ex:
  # config.sandbox_exec = ["/bin/env","-i","PATH=/opt/ruby-1.9.3/bin", "bundle", "exec", "ruby"]
  config.sandbox_exec = ["rvm-exec","ruby-1.9.3@rearview-sandbox","ruby"]

  # How long to wait for a monitor script to run in seconds. After this time
  # period the monitor script will be terminated.
  config.sandbox_timeout = 10

  # The url to your graphite web server
  # ex:
  # config.graphite_url="http://graphite.mycompany.com"
  config.graphite_url = nil

  # This is the email from: address used when sending alerts
  # ex:
  # config.default_from = "rearview@mycompany.com"
  config.default_from = "rearview@localhost"

  # The url options for rearview application host. Required to generate
  # monitor alerts with correct URL references.
  # ex:
  # config.default_url_options = { host: 'rearview.mycomopany.com', protocol: 'https'}
  config.default_url_options = { host: 'localhost', port: '3000'}

  # Enable collection of stats for rearview itself. This will send JVM and monitor related
  # stats to graphite using statsd.
  #
  config.enable_stats=false

  # The connection information for the stats service. Only necessary if enable_stats is true.
  # ex:
  # config.statsd_connection = { host: 'statsd.mycompany.com', port: 8125 , namespace: 'rearview' }
  #

  case Rails.env
    when "test"
      config.preload_jobs = false
    when "production"
      # If you want to make sure your configuration is correct on server startup. This
      # will make http requests that will slow down startup.
      # config.verify = true
  end

  if File.basename($0) == "rake"
    config.enable_monitor = false
    config.enable_stats = false
  end

  # Options passed via environment will override anything else set to this point...
  if ENV['REARVIEW_OPTS'].present?
    config.with_argv(ENV['REARVIEW_OPTS'].try(:split))
  end

end

Rearview.boot!

