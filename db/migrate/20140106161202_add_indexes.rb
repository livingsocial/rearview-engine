class AddIndexes < ActiveRecord::Migration
  def change
    add_index :jobs, :status
    add_index :job_errors, :status
    add_index :job_data, :job_id
  end
end
