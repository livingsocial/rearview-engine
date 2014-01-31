ENV['RAILS_ENV'] ||= 'test'
require File.expand_path("../dummy/config/environment.rb", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'mocha/setup'
require 'factory_girl_rails'
require 'shoulda'
require 'timecop'
require 'coveralls'

Coveralls.wear!

Rails.backtrace_cleaner.remove_silencers!

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

Rearview.configure do |config|
  config.logger = Rails.logger
  config.sandbox_dir = Rails.root + "sandbox"
  config.sandbox_exec = ["rvm-exec","ruby-1.9.3-p448@rearview-sandbox","ruby"]
  config.sandbox_timeout = 10
  config.preload_jobs = false
  config.enable_monitor = false
  config.default_url_options = { host: 'localhost', port: '3000' }
  config.statsd_connection = { host: '127.0.0.1', port: 8125, namespace: 'rearview' }
end

Rearview.boot!

RSpec.configure do |config|
  config.mock_with :mocha
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"
  config.include FactoryGirl::Syntax::Methods
end

