class ScheduledTask < ActiveRecord::Base
  belongs_to :task
  has_many :scheduled_task_logs
end