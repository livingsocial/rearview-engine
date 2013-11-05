require 'ostruct'
require 'optparse'
require 'devise'
require 'ancestry'
require 'state_machine'
require 'protected_attributes'
require 'httparty'
require 'celluloid'
require 'jbuilder'

jar_dir =  File.expand_path('../../jar',  __FILE__)
for jar in Dir["#{jar_dir}/*.jar"]
  require jar
end

module Rearview
  class Engine < ::Rails::Engine
    isolate_namespace Rearview
    config.generators do |g|
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
    config.assets.enabled = false
    config.serve_static_assets = true
    config.i18n.enforce_available_locales = false
    initializer 'static_assets.load_static_assets' do |app|
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end
    initializer 'devise.use_rearview_helpers' do |app|
      Devise::SessionsController.class_eval { helper Rearview::ApplicationHelper }
    end
    Jbuilder.key_format :camelize => :lower
  end
end
