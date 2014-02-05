
module Rearview
  class MonitorController < Rearview::ApplicationController

    before_action only: [:create] do
      clean_empty_array_vals(:metrics)
    end

    #
    # TODO this should be moved to the JobsController#test and the UI changed to push the
    # monitor job model instead of custom params
    #
    def create
      metrics_validator = Rearview::MetricsValidator.new({attributes: [:metrics]})
      @errors = params[:metrics].inject([]) { |a,v| a << "Metrics contains an invalid metric: #{v}" unless(metrics_validator.metric_valid?(v)); a }
      results = if @errors.empty?
                  Rearview::MonitorRunner.run(params[:metrics],params[:monitorExpr],params[:minutes],{},false,params[:toDate],true)
                else
                  { }
                end
      @monitor_output = Rearview::MonitorRunner.normalize_results(results)
    end

  end
end

