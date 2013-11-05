
module Rearview
  class JobData < ActiveRecord::Base

    self.table_name = "job_data"

    attr_accessible :created_at, :updated_at, :job_id, :data
    belongs_to :job
    serialize :data, JSON

    validates :job_id, :data, :presence => true
  end
end
