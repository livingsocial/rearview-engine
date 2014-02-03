json.(job,:id,:user_id,:name,:cron_expr,:metrics,:monitor_expr,:minutes,:to_date,:description,:active,:status,:last_run,:alert_keys,:error_timeout)
json.dashboardId job.app_id
json.createdAt job.created_at.to_i
json.modifiedAt job.updated_at.to_i
json.errors job.errors.full_messages
