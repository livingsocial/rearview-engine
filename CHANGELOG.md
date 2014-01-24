## 1.1.2 (2014-01-24)

Bugfixes:

- remove crypto related initializer (rearview/#20)

## 1.1.1 (2014-01-23)

Bugfixes:

- forgot to bundle correctly before release

## 1.1.0 (2014-01-23)

Features:

- improvements to collect_aberrations (#2,@steveakers)
- send rearview statistics through through statsd if configured in config/initializers/rearview.rb
 - monitor metrics: total runs, success, and failures
 - jvm metrics: heap, non-heap, initial, used, max, and committed
- improvements to logging
 - provide a default log formatter that includes the thread name

Bugfixes:

- fixed alert URL: the alert URL now matches the ecosystem link so that canceling or saving the monitor
goes back to the monitor category in the context of its parent dashboard.
- added missing spec for Numeric extension
- removed inconsistant use of include Celluloid::Logger vs Rearview::Logger
- removed some superfluous and noisy logging statements

## 1.0.2 (2014-01-07)

Features:

- improve authentication support (database/google oauth2) by enhancing configuration and session view
- created new rake task to validate configuration for users(rake rearview:config:verify)

Bugfixes:

- minor performance tweak to job data retrieval
- added various missing database indexes
- fixed url generation for alerts which was creating links to livingsocial.com internal servers
- prevent database pool from being exhausted if graphite is down
