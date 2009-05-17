ActiveRecord::Schema.define(:version => 0) do  
  
  create_table :tasks, :force => true do |t| 
    t.column :name, :string
    t.column :class_name, :string
    t.column :method_name, :string
    t.column :is_running, :boolean, :default => false
  end
  
  create_table :scheduled_tasks, :force => true do |t| 
    t.column :task_id, :integer
    t.column :frequency_id, :integer
    t.column :time_of_day, :integer, :null => false, :default => 0 
  end
  
  create_table :scheduled_task_logs, :force => true do |t| 
    t.column :scheduled_task_id, :integer
    t.column :start, :datetime
    t.column :end, :datetime
    t.column :success, :boolean
    t.column :info, :string
  end
  
end
