json.errors @validation_fields.keys.find_all { |f| !@job.errors[f].empty? }.inject({}) { |a,v| a[v] = @job.errors[v]; a }
