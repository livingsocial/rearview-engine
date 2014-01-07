## 1.0.2

Features:

- improve authentication support (database/google oauth2) by enhancing configuration and session view
- created new rake task to validate configuration for users(rake rearview:config:verify)

Bugfixes:

- minor performance tweak to job data retrieval
- added various missing database indexes
- fixed url generation for alerts which was creating links to livingsocial.com internal servers
- prevent database pool from being exhausted if graphite is down
