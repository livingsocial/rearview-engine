module Rearview
  class JobsController < ApplicationController
    respond_to :json
    before_action :underscore_params, only: [:create,:update]
    before_action :clean_emptiness, only: [:create,:update]

    def index
      @jobs = if params[:dashboard_id].present?
                Rearview::Job.where(:app_id=>params[:dashboard_id])
              else
                Rearview::Job.all
              end
    end

    def create
      dashboard_id = params.delete("dashboard_id")
      @job = Rearview::Job.new(job_create_params)
      @job.user_id = current_user.id
      @job.dashboard = Rearview::Dashboard.find(dashboard_id.to_i)
      if @job.save
        @job.sync_monitor_service
        render :show
      else
        render :show, status: 422
      end
    end

    def update
      @job = Rearview::Job.find(params[:id])
      dashboard_id = params.delete("dashboard_id")
      if dashboard_id.present? && dashboard_id.to_i!=@job.app_id
        @job.dashboard = Rearview::Dashboard.find(dashboard_id.to_i)
      end
      if @job.update_attributes(job_update_params)
        @job.sync_monitor_service
        render :show
      else
        render :show, status: 422
      end
    end

    def destroy
      @job = Rearview::Job.find(params[:id])
      @job.destroy
      render :show
    end

    def reset
      @job = Rearview::Job.find(params[:id])
      @job.reset
      render :show
    end

    def show
      @job = Rearview::Job.find(params[:id])
    end

    def data
      @job_data = Rearview::JobData.find_by(job_id:params[:id])
      unless @job_data.present?
        head :status => 404
      end
    end

    def errors
      @job_errors = Rearview::JobError.calculate_durations(Rearview::JobError.search(params).load)
    end

    private

    def underscore_params
      self.params = self.params.inject({}.with_indifferent_access) { |a,(k,v)| a[k.to_s.underscore] = v; a }
    end

    def job_update_params
      params.permit(:name,:active,{ :alert_keys => []},:cron_expr,:error_timeout,:minutes,{ :metrics => [] },:monitor_expr,:to_date,:description)
    end

    def job_create_params
      params.permit(:dashboard_id,:name,:active,{ :alert_keys => []},:cron_expr,:error_timeout,:minutes,{ :metrics => [] },:monitor_expr,:to_date,:description)
    end

    def clean_emptiness
      params[:metrics].reject! { |m| !m.present? } if params[:metrics].present?
      params[:alert_keys].reject! { |k| !k.present? } if params[:alert_keys].present?
    end

  end
end
