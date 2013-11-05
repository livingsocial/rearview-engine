module Rearview
  module Distribute
    class << self

      def by_delay(jobs)
        job_meta = jobs.map { |j| [j,{:delay=>j.delay,:initial_delay=>0}] }
        job_meta.sort! { |a,b| a.last[:delay] <=> b.last[:delay] }
        default_offset_amnt = 2.0
        other_offset_amnt = 2.0
        default_offset_count = 0
        other_offset_count = 0
        job_meta.each do |m|
          if m.first.cron_expr == "0 * * * * ?"
            m.last[:initial_delay] = default_offset_amnt * default_offset_count
            default_offset_count+=1
          else
            m.last[:initial_delay] = other_offset_amnt * other_offset_count
            other_offset_count+=1
          end
        end
        job_meta
      end

      def inspect(dist_jobs)
        parts = []
        dist_jobs.each do |dj|
          job = dj.first
          meta = dj.second
          parts << sprintf("job: %.5d cron:%30.25s meta:%s",job.id,job.cron_expr,meta.inspect)
        end
        parts.join("\n")
      end

    end
  end
end
