
module Rearview
  class MonitorService
    class MonitorServiceError < StandardError; end;
    include Celluloid
    include Rearview::Logger
    attr_accessor :jobs
    attr_reader :supervisor
    def initialize(jobs=[])
      self.jobs = jobs
      @supervisor = nil
      @started = false
    end
    def jobs=(jobs)
      @jobs = jobs.inject({}) { |c,v| c[v.id] = v ; c }
    end
    def started?
      @started
    end
    def startup
      raise MonitorServiceError.new("service already started") if started?
      # TODO actor could die, need to reference by name in registry and/or create link
      @supervisor = Rearview::MonitorSupervisor.run!
      @supervisor.add_tasks(@jobs.values)
      @started = true
    end
    def shutdown
      raise MonitorServiceError.new("service not started") unless started?
      @supervisor.remove_all_tasks
      @supervisor.terminate
      @started = false
    end
    def schedule(job)
      logger.debug "#{self} schedule job: #{job.id}"
      raise MonitorServiceError.new("service not started") unless started?
      if @jobs[job.id]
        remove(job)
      end
      add(job)
    end
    def unschedule(job)
      logger.debug "#{self} unschedule job: #{job.id}"
      raise MonitorServiceError.new("service not started") unless started?
      if @jobs[job.id]
        remove(job)
      end
    end
    def add(job)
      raise MonitorServiceError.new("service not started") unless started?
      if @jobs[job.id]
        logger.warn "#{self}#add job:#{job.id} already added"
      else
        @supervisor.add_tasks([job])
        @jobs[job.id] = job
      end
    end
    def remove(job)
      raise MonitorServiceError.new("service not started") unless started?
      if !@jobs[job.id]
        logger.warn "#{self}#remove job:#{job.id} has already been removed"
      else
        @supervisor.remove_tasks([job])
        @jobs.delete(job.id)
      end
    end

  end

end

