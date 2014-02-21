## 1.2.0 (unreleased)

Features:

- improved UI for validation of a monitor (@talbright)
- add validation of monitor metrics, cron expression, and alert keys during test, edit, and create monitor (@talbright)
- added user prefs panel (@talbright)
- added user prefs for default alert key(s) (@talbright)
- add link to sign-out (@talbright)
- added support for travis on github (@talbright)
- added support for coveralls on github (@talbright)
- various improvements to configuration (@talbright)
- make setup script idempotent (@talbright)
- stats service that sends VM metrics to graphite for self-monitoring (@talbright)
- metrics validation service that checks for missing metrics daily and emails monitor owner (@talbright)

Bugfixes:

- remove hard coded URL paths in JS; paths should be dynamic based on engine mount path (@talbright)
- remove initializer duplicated in engine and host (@talbright)
- fix for issue where newly created monitor disappeared from dashboard (@talbright)
- fix for postgresql schema incompatibility (@talbright)
- fix monitor link in alert that was incorrect in some cases (@talbright)
- improve test coverage (@talbright)
- login screen looks bad after refreshing, especially in chrome (@steveakers)

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
