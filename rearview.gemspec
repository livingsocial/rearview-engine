$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rearview/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rearview"
  s.license     = "MIT"
  s.version     = Rearview::VERSION
  s.authors     = ["Trent Albright"]
  s.email       = ["trent.albright@gmail.com"]
  s.homepage    = "https://github.com/livingsocial/rearview"
  s.summary     = "Timeseries data monitoring framework"
  s.description = "Timeseries data monitoring framework running as a rails engine"
  s.platform    = "jruby"
  s.required_ruby_version = ">= 1.9.3"

  s.files = Dir["{app,bin,config,db,lib,public,script,spec,tasks}/**/*"] + ["Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.0.2"
  s.add_dependency "devise", "~> 3.2.2"
  s.add_dependency "ancestry", "~> 2.0.0"
  s.add_dependency "state_machine", "~> 1.2.0"
  s.add_dependency "protected_attributes", "~> 1.0.5"
  s.add_dependency "httparty", "~> 0.12.0"
  s.add_dependency "celluloid", "~> 0.14.1"
  s.add_dependency "broach", "~> 0.3.0"
  s.add_dependency "jbuilder", "~> 1.5.2"
  s.add_dependency "statsd-ruby", "~> 1.2.1"

  s.add_development_dependency "activerecord-jdbcmysql-adapter"
  s.add_development_dependency "foreman"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "pry"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "mocha"
  s.add_development_dependency "timecop"
end
