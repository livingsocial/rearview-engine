[![Build Status](https://secure.travis-ci.org/livingsocial/rearview-engine.png?branch=master)](http://travis-ci.org/livingsocial/rearview-engine)

Rails engine for [rearview](http://github.com/livingsocial/rearview). This project is for rearview developers only. For users please go to the [rearview](http://github.com/livingsocial/rearview) project for installation, configuration, and other details.

# Development Guide

Before developing please read how to [contribute](https://github.com/livingsocial/rearview-engine/blob/master/CONTRIBUTING.md).

## Intro

Before contributing you should read [Getting Started with Engines](http://guides.rubyonrails.org/engines.html) guide to familiarize yourself with rails engines.

Rearview consists of two components:

(1) Rearview engine (this repo)

The vast majority of any code customizations and bug fixes should be made here. 

(2) Rearview engine host (https://github.com/livingsocial/rearview)

This is mostly a convienience for users so they can quickly get rearview up and running. This also allows users to customize views and other components at well defined extension points without them having to submit them back into the code base.

**Note: the rearview engine is not completely isolated (yet) so it cannot be safely multi-tennated with other engines in the same host**

## Getting started

#### clone the rearview engine

    git clone git@github.com:livingsocial/rearview-engine.git

#### clone the rearview engine host

    git clone git@github.com:livingsocial/rearview.git
    
#### edit the engine host Gemfile to point to your local engine clone

Change the line simliar to this

    gem 'rearview', '~> 1.0.0'
    
To point to the path you cloned the engine too, for example

    gem 'rearview', :path => '~/clone/path/rearview-engine'

#### sync the engine host database

    rake rearview:install:migrations
    rake db:setup
    
#### start the engine host server

    bin/rails server
    
## User Interface Guide

Rearview does not use the asset pipeline. Instead you'll need to take a look at [public/rearview-src](https://github.com/livingsocial/rearview-engine/tree/master/public/rearview-src). In development mode javascript, css, etc is loaded directly from here. When rearview-engine is bundled as a Gem the various elements are pre-compiled (manually before **gem build**) using require and are loaded from [public/rearview](https://github.com/livingsocial/rearview-engine/tree/master/public/rearview).

To compile the ui before distribution, run the following rake task from inside rearview-engine:

    rake rearview:ui:build






    
