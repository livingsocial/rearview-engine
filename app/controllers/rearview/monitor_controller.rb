
module Rearview
  class MonitorController < ApplicationController

    def create
      results = Rearview::MonitorRunner.run(params[:metrics],params[:monitorExpr],params[:minutes],{},false,params[:toDate],true)
      @monitor_output = Rearview::MonitorRunner.normalize_results(results)
    end

  end
end

