
module Rearview
  class DashboardChildrenController < Rearview::ApplicationController
    def index
      @dashboards = if params[:dashboard_id]
                      Rearview::Dashboard.find(params[:dashboard_id]).children
                    else
                      []
                    end
      render 'rearview/dashboards/index'
    end
    def create
      @dashboard = Rearview::Dashboard.new
      @dashboard.name = params[:name]
      @dashboard.user = current_user
      @dashboard.description = params[:description]
      if params[:dashboard_id]
        @dashboard.parent=Rearview::Dashboard.find(params[:dashboard_id])
      end
      @dashboard.save!
      render 'rearview/dashboards/show'
    end
  end
end

