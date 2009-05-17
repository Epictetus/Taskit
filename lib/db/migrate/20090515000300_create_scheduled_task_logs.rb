class CreateScheduledTaskLogs < ActiveRecord::Migration
  
  def self.up
    create_table :scheduled_task_logs do |t|
      t.column :scheduled_task_id, :integer
      t.column :start, :datetime
      t.column :end, :datetime
      t.column :success, :boolean
      t.column :info, :string
    end
  end
  
  def self.down
    drop_table :scheduled_task_logs
  end 
  
end