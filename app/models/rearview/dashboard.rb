module Rearview
  class Dashboard < ActiveRecord::Base
    self.table_name='applications'
    attr_accessible :created, :deleted_at, :name, :user, :user_id, :modified,:description
    belongs_to :user
    has_many :jobs, dependent: :destroy, foreign_key: :app_id

    has_ancestry
    validates :name, :user_id, presence: true
  end
end
