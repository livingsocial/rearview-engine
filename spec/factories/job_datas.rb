# Read about factories at https://github.com/thoughtbot/factory_girl

d = { "status" => "success" }
FactoryGirl.define do
  factory :job_data,class: Rearview::JobData do
    job
    created_at                    Time.now.utc
    updated_at                    Time.now.utc
    data({ "status" => "success", "output" => "yo", "graph_data" => {"stats_counts.cupcake.web_traffic.impression" => [[1368035700,66.0],[1368035710,76.0],[1368035720,86.0],[1368035730,63.0],[1368035740,70.0],[1368035750,56.0],[1368035760,nil]]} })
  end
end

