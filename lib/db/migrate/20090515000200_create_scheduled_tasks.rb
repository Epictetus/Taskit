class CreateScheduledTasks < ActiveRecord::Migration
  
  def self.up
    create_table :scheduled_tasks do |t|
      t.column :task_id, :integer
      t.column :frequency_id, :integer
      # time_of_day is specified in minutes past midnight. 
      # For frequencies more frequent than daily - ignored
      # For frequencies of daily or less - specifies time of day to run at. If omitted = midnight
      t.column :time_of_day, :integer, :null => false, :default => 0 
    end
  end
  
  def self.down
    drop_table :scheduled_tasks
  end 
  
end