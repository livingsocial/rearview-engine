
module Rearview
  class MonitorSupervisor < Celluloid::SupervisionGroup
    include Rearview::Logger
    class MonitorSupervisorError < StandardError; end;
    def add_tasks(jobs)
      if jobs.present?
        dist_jobs = Rearview::Distribute.by_delay(jobs)
        logger.debug Rearview::Distribute.inspect(dist_jobs)
        dist_jobs.each do |dj|
          job = dj.first
          meta = dj.last
          add(Rearview::MonitorTask,as: MonitorSupervisor.task_sym(job), args: [job,meta[:initial_delay]])
        end
      end
    end
    def remove_tasks(jobs)
      if jobs.present?
        jobs.each do |j|
          logger.debug "#{self} removing job:#{j.id}"
          member = @members.find { |m| m.actor.job == j }
          if !member.present?
            warn "#{self} remove job:#{j.id} failed because it is not present"
          else
            @members.reject! { |m| m == member }
            unlink(member.actor)
            member.actor.terminate
          end
        end
      end
    end
    def all_tasks
      actors
    end
    def remove_all_tasks
      actors.each do |a|
        begin
          unlink(a)
          a.terminate
        rescue DeadActorError, MailboxError
          warn "#{self} error while terminating #{a}: #{$!}\n#{$@}"
        end
      end
      @members = []
    end
    def self.task_sym(job)
      "job_#{job.id}".to_sym
    end
    def to_s
      "#{super.to_s} [threadId:#{java.lang.Thread.currentThread.getId} threadName:#{java.lang.Thread.currentThread.getName}]"
    end
  end
end

