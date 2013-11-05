require_dependency "rearview/application_controller"

module Rearview
  class DashboardsController < ApplicationController
    respond_to :json

    def index
      @dashboards = Rearview::Dashboard.roots
    end

    def show
      @dashboard = Rearview::Dashboard.find(params[:id])
    end

    def create
      upsert
      render :show
    end

    def update
      upsert
      render :show
    end

    def destroy
      @dashboard = Rearview::Dashboard.find params[:id]
      @dashboard.destroy
      render :show
    end

    def errors
      @job_errors = Rearview::JobError.calculate_durations(Rearview::JobError.application_errors(params[:id]).order_created.load)
    end

    private

    def upsert
      @dashboard = Rearview::Dashboard.find_or_initialize_by(id: params[:id])
      @dashboard.name = params[:name]
      @dashboard.user = current_user
      @dashboard.description = params[:description]
      @dashboard.save!
    end

  end
end
