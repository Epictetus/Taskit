class Task < ActiveRecord::Base
  has_many :scheduled_tasks
  
  # instance method to set task running if it isn't already.
  def set_running_if_not_already
    # Note that connection.update returns the number of rows affected.
    # In this way, we can tell whether it was already running.  
    rows_affected = connection.update("
      UPDATE tasks 
      set is_running = 1
      WHERE id = #{id}
      AND is_running = 0
    ")
    
    if rows_affected > 0 
        self.reload
      true
    else
      false
    end
  end
end