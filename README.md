# Rearview (Ruby Edition)

<img src="http://code.livingsocial.net/analytics/rearview-ruby/raw/master/rearview.png"/>

JRuby port of Rearview

https://rearview.livingsocial.net

# Requirements

  - latest rvm
  - jvm 1.6
  - jruby 1.7.5

# Installation

    % ./script/bootstrap

# Running

    % foreman start rearview_web

# Deployment

## first time deployment

If this is the first time you have deployed to production or myqa, run the following command. Note that
this only needs to be run ONCE:

    % script/deploy --setup

This sets up a cap wrapper specific to rearview, which accepts the same parameters as cap normally would:

    % rearview_cap -T

## deploy to production

    % rearview_cap deploy

## deploy to myqa

    % rearview_cap myqa deploy

# MYQA

## restarting application

    % sudo /usr/local/bin/pumactl rearview-ruby cold-restart

## starting the rails console

    $ PATH=/opt/jruby/bin:$PATH RAILS_ENV=production bundle exec rails console

## running rake tasks

    $ PATH=/opt/jruby/bin:$PATH RAILS_ENV=production bundle exec rake db:migrate



===============================================================================

Some setup you must do manually if you haven't yet:

  1. Ensure you have defined default url options in your environments files. Here
     is an example of default_url_options appropriate for a development environment
     in config/environments/development.rb:

       config.action_mailer.default_url_options = { :host => 'localhost:3000' }

     In production, :host should be set to the actual host of your application.

  2. Ensure you have defined root_url to *something* in your config/routes.rb.
     For example:

       root :to => "home#index"

  3. Ensure you have flash messages in app/views/layouts/application.html.erb.
     For example:

       <p class="notice"><%= notice %></p>
       <p class="alert"><%= alert %></p>

  4. If you are deploying on Heroku with Rails 3.2 only, you may want to set:

       config.assets.initialize_on_precompile = false

     On config/application.rb forcing your application to not access the DB
     or load models when precompiling your assets.

  5. You can copy Devise views (for customization) to your app by running:

       rails g devise:views

===============================================================================
