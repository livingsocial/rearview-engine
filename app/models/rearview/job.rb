
module Rearview
  class Job < ActiveRecord::Base

    include Rearview::ConstantsModuleMaker
    include Rearview::Ext::StateMachine

    self.table_name = "jobs"

    make_constants_module :status,
      :constants => [:success,:failed,:error,:graphite_error,:graphite_metric_error,:security_error]

    attr_accessible :created_at, :updated_at, :name, :active, :last_run,
      :cron_expr, :status, :user_id, :alert_keys, :deleted_at, :error_timeout,
      :next_run, :description, :app_id, :metrics, :monitor_expr, :minutes,
      :to_date

    belongs_to :dashboard, :foreign_key => :app_id
    belongs_to :user
    has_one :job_data, :dependent => :destroy
    has_many :job_errors, :dependent => :destroy

    serialize :metrics, JSON
    serialize :alert_keys, JSON

    before_save :set_defaults
    before_update :set_defaults
    before_destroy :unschedule

    validates :app_id, :cron_expr, :name, :metrics, :presence => true
    validate :valid_cron_expression
    validate :valid_alert_keys

    scope :schedulable, -> { where(:active=>true) }

    state_machine :status, :initial => nil do

      error_group = [:failed,:error,:graphite_metric_error,:graphite_error,:security_error]

      after_transition nil => any, :do => :create_associated_event
      after_transition :success => error_group , :do => :create_associated_event
      after_transition error_group => :success, :do => :create_associated_event
      after_transition :success => :success, :do => :update_associated_event
      after_transition error_group => error_group, :do => :update_associated_event

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

      event :security_error do
        transition all => :security_error
      end

      state :success
      state :failed
      state :error
      state :graphite_error
      state :graphite_metric_error
      state :security_error

    end

    def schedule
      Rearview.monitor_service.schedule(self)
    end

    def unschedule
      Rearview.monitor_service.unschedule(self)
    end

    def reset
      self.unschedule if active
      self.job_data.destroy unless(self.job_data.nil?)
      self.job_errors.clear
      self.status = nil
      self.save!
      self.reload
      self.schedule if active
    end

    # The number of seconds to delay before the next time this job should run
    def delay
      if cron_expr == "0 * * * * ?"
        60.0
      else
        Rearview::CronHelper.next_valid_time_after(cron_expr)
      end
    end

    # This doesn't fit nicely as a callback -- the monitor itself needs to update
    # the job which triggers a fun cycle of events =)
    def sync_monitor_service
      if active
        schedule
      else
        unschedule
      end
    end

    def valid_cron_expression
      if cron_expr.present? && !Rearview::CronHelper.valid_expression?(cron_expr)
        errors.add(:cron_expr, "not a valid cron expression")
      end
    end

    def valid_alert_keys
      if alert_keys.present?
        schemes = Rearview::Alerts.registry.keys
        alert_keys.each do |key|
          begin
            uri = URI(key)
            scheme = uri.scheme
            unless scheme.present? && schemes.include?(scheme)
              errors.add(:alert_keys,"unsupported scheme")
            else
              scheme_class = Rearview::Alerts.registry[scheme]
              unless scheme_class.key?(key)
                errors.add(:alert_keys,"#{scheme} URI is invalid")
              end
            end
          rescue URI::InvalidURIError, URI::InvalidComponentError
            errors.add(:alert_keys,"#{key} is an invalid URI")
          end
        end
      end
    end

    def create_associated_event(transition)
      report_transition(transition)
      job_error_attrs = {}
      job_error_attrs.merge!(event_data[:job_error]) if event_data.try(:[],:job_error)
      job_error = job_errors.create(job_error_attrs)
      job_error.fire_event(translate_associated_event(transition),event_data)
    end

    def update_associated_event(transition)
      report_transition(transition)
      job_error = Rearview::JobError.latest_entry(self)
      if job_error.present?
        job_error.fire_event(translate_associated_event(transition),event_data)
      end
    end

    protected

    def report_transition(transition)
      Rearview::Statsd.report do |stats|
        metric = ( transition.event.to_s == 'success' ?  'success' : 'failure' )
        stats.increment("monitor.#{metric}")
      end
    rescue
      logger.error "#{self} report_transition failed: #{$!}\n#{$@.join("\n")}"
    end

    def translate_associated_event(transition)
      if transition.event.to_s == Status::SECURITY_ERROR
        :error
      else
        transition.event
      end
    end

    def set_defaults
      unless self.alert_keys.present?
        self.alert_keys = []
      end
    end

  end
end
