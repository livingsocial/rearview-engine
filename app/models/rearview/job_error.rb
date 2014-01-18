
module Rearview
  class JobError < ActiveRecord::Base

    self.table_name = "job_errors"

    include Rearview::ConstantsModuleMaker
    include Rearview::Ext::StateMachine

    make_constants_module :status,
      :constants => [:success,:failed,:error,:graphite_error,:graphite_metric_error]

    attr_accessible :created_at, :job_id, :message, :status
    attr_accessor :end_date
    belongs_to :job

    validates :job_id, :presence => true

    scope :only_errors, -> { where('status != ?',Status::SUCCESS) }
    scope :order_created, -> { order('created_at DESC') }

    state_machine :status, :initial => nil do

      # Temporarily removed :error from this group so alerts don't get sent at that state [REAR-183]
      error_group = [:failed,:graphite_error,:graphite_metric_error]

      after_transition nil => error_group, :do => :create_alert
      after_transition error_group => error_group, :do => :update_alert

      event :success do
        transition all => :success
      end

      event :failed do
        transition all => :failed
      end

      event :error do
        transition all => :error
      end

      event :graphite_error do
        transition all => :graphite_error
      end

      event :graphite_metric_error do
        transition all => :graphite_metric_error
      end

      state :success
      state :failed
      state :error
      state :graphite_error
      state :graphite_metric_error
    end

    def self.search(params)
      filter = self.where(:job_id=>params[:id])
      order_direction = "DESC"
      if params[:start_date]
        filter = filter.where("created_at >= ?",params[:start_date])
        order_direction = "ASC"
      end
      if params[:end_date]
        filter = filter.where("created_at <= ?",params[:end_date])
        order_direction = "ASC"
      end
      if params[:limit]
        filter = filter.limit(params[:limit])
      end
      if params[:offset]
        filter = filter.offset(params[:offset])
      end
      filter.order("created_at #{order_direction}")
    end

    def self.calculate_durations(errors)
      last_with_error = nil         # most recently found error
      (errors.each do |e|
        if e.status == Status::SUCCESS
          unless last_with_error.nil?
            last_with_error.end_date = e.created_at.utc.to_i
            last_with_error = nil
          end
        else
          last_with_error = e
        end
      end).reject { |e| e.status == Status::SUCCESS }
    end

    def self.application_errors(application_id)
      joins("INNER JOIN jobs ON jobs.id = job_errors.job_id").joins("INNER JOIN applications ON applications.id = jobs.app_id").where("applications.id = ?",application_id)
    end

    def self.last_error(job_id)
      only_errors.where("job_id = ?",job_id).order_created.limit(1).first
    end

    def self.latest_entry(job_id)
      where("job_id = ?",job_id).order_created.limit(1).first
    end

    def create_alert(transition)
      Rearview::AlertsHandler.new(self.job,event_data[:monitor_results]).run
      self.last_alerted_at = Time.now.utc
      save!
    end

    def update_alert(transition)
      if !self.last_alerted_at || Time.now.utc >= self.last_alerted_at.utc + self.job.error_timeout.minutes
        Rearview::AlertsHandler.new(self.job,event_data[:monitor_results]).run
        self.last_alerted_at = Time.now.utc
        save!
      end
    end

  end
end
