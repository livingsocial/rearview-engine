module Rearview
  class JobsController < ApplicationController
    respond_to :json

    def index
      @jobs = if params[:dashboard_id].present?
                Rearview::Job.where(:app_id=>params[:dashboard_id])
              else
                Rearview::Job.all
              end
    end

    def create
      upsert(allowed_create_params)
      render :show
    end

    def update
      upsert(allowed_update_params)
      render :show
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

    def upsert(filtered_params)
      @job = Rearview::Job.find_or_initialize_by(id: params[:id])
      dashboard_id = filtered_params.delete("dashboard_id")
      if dashboard_id.present? && dashboard_id.to_i!=@job.app_id
        @job.dashboard = Rearview::Dashboard.find(dashboard_id.to_i)
      end
      @job.update_attributes!(filtered_params)
      @job.sync_monitor_service
    end

    def allowed_create_params
      filtered_params = underscore_params
      filtered_params.delete_if { |k,v|
        ["controller","job_type","version","action","job","id","format","created_at","modified_at"].include?(k)
      }
    end

    def allowed_update_params
      filtered_params = underscore_params
      filtered_params.delete_if { |k,v|
        !["dashboard_id","name","active","alert_keys","cron_expr","error_timeout","minutes","metrics","monitor_expr","to_date","description"].include?(k)
      }
    end

    def underscore_params
      params.inject({}.with_indifferent_access) { |a,(k,v)| a[k.to_s.underscore] = v; a }
    end

  end
end
