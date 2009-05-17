class CreateTasks < ActiveRecord::Migration
  
  def self.up
    create_table :tasks do |t|
      t.column :name, :string
      t.column :class_name, :string
      t.column :method_name, :string
      t.column :is_running, :boolean, :default => false
    end
  
    add_index :tasks, [:name], :unique => true, :name => :uq_tasks_name
  end
  
  def self.down
    drop_table :tasks
  end 
  
end