# pick up the models in the main rails app.
%w{ models }.each do |dir| 
  path = File.join(File.dirname(__FILE__), 'app', dir)  
  $LOAD_PATH << path 
  ActiveSupport::Dependencies.load_paths << path 
  ActiveSupport::Dependencies.load_once_paths.delete(path) 
end 

class Taskit
  
  # note: we can send output to the standard output (puts) and the cron job should 
  # send it to the scheduled_tasks.log file :)

  def self.run_scheduled_tasks 

    now = Time.now.utc
    
    puts "**** Starting processing scheduled tasks at: " +  now.to_s + " ****" 
    scheduled_tasks = ScheduledTask.find(:all)  
    scheduled_tasks.each do |scheduled_task|
      self.run_scheduled_task(scheduled_task, now)
    end  
  end

  private 
  
  # the current time is passed in, so the method uses the same time throughout,
  # (and so we can test it more easily!)
  def self.run_scheduled_task(scheduled_task, time_now)
    puts "** Processing scheduled task id: " + scheduled_task.id.to_s + " **"  
    task = scheduled_task.task    
    puts "Task name: " + task.name
    puts "Time now: " + time_now.to_s 
    
    # find the last run-time
    last_log = scheduled_task.scheduled_task_logs.find(:first, :order => "id desc")
    if last_log
      last_run = last_log.start
    end
       
    if ( last_run )
      puts "Task last ran at: " +  last_run.to_s
    else
      puts "Task never been run"
      # if task has never run, give it a time at the epoch (1970) 
      last_run = Time.at(0)
    end
    
    frequency_id = scheduled_task.frequency_id
        
    if determine_whether_to_run( frequency_id, scheduled_task.time_of_day, last_run, time_now )
                    
      # The method on the task object tries to set the task to running and will return true if rows are affected by the update.
      # If no rows are updated it means that it was already running. 
      # We don't want to have two instances of same task running at the same time 
      # Without this check this may have happenned if run_scheduled_tasks (all tasks) takes longer than the cron schedule interval,
      # causing overlap.
      if (task.set_running_if_not_already())
        
        puts "Running task..."
        
        scheduled_task_log = ScheduledTaskLog.new
        scheduled_task_log.scheduled_task_id = scheduled_task.id
        scheduled_task_log.start = Time.now
        scheduled_task_log.save
    
        begin    
          # call the task using ruby reflection. 
          Class.const_get(task.class_name).send(task.method_name)
          scheduled_task_log.success = true
          puts "success"
        rescue Exception => e
          scheduled_task_log.end = Time.now
          scheduled_task_log.success = false
          scheduled_task_log.info = e.to_s
          scheduled_task_log.save
          puts "Error: " + e.to_s
        ensure
          scheduled_task_log.end = Time.now
          scheduled_task_log.save
          # set to not running anymore
          task.is_running = false
          task.save     
          puts "Task completed at: " + scheduled_task_log.end.to_s
        end
          
      else
        puts "Task is still running from a previous time!"
        # still running.  
        # TODO: alert someone?
      end
    
    else
        puts "Not running task this time."
    end
  end
  
  
  # work out whether to run a task, given its frequency, last run date and time of day (in mins past midnight)
  def self.determine_whether_to_run( frequency_id, time_of_day_to_run, last_run, time_now )    
    
    # if it is set to run asap, just let it run,
    # otherwise, do some calculations...
            
    if (frequency_id == Frequency::ASAP)
      puts "running asap"
      return true
    else       
      return compare_times(frequency_id, time_of_day_to_run, last_run, time_now)                     
    end
    
  end
    
  def self.compare_times( frequency_id, time_of_day_to_run, last_run, time_now )
    
    if frequency_id >= Frequency::DAILY
      
      # For these frequencies, we compare to midnight on the last run date, to try to honour the 
      # time of day to run...
      seconds_since_midnight_last_run = ( (last_run.hour*60*60) + (last_run.min*60) + (last_run.sec) )  
      last_run_midnight = last_run - seconds_since_midnight_last_run
      puts "Comparing time now to: " + last_run_midnight.to_s
       
      case frequency_id
        when Frequency::DAILY
          puts "Frequency: daily"
          return (last_run_midnight < time_now - (1.day)) && check_minutes_past_midnight(time_of_day_to_run, time_now)
        when Frequency::WEEKLY
          puts "Frequency: weekly"
          return (last_run_midnight < time_now - (1.week)) && check_minutes_past_midnight(time_of_day_to_run, time_now)
        when Frequency::FORTNIGHTLY
          puts "Frequency: fortnightly"
          return (last_run_midnight < time_now - (2.weeks)) && check_minutes_past_midnight(time_of_day_to_run, time_now)
        when Frequency::MONTHLY
          puts "Frequency: monthly"
          return (last_run_midnight < time_now - (30.days)) && check_minutes_past_midnight(time_of_day_to_run, time_now)
        else 
          puts "UNKNOWN FREQUENCY!"
          return false
      end        
        
    else # i.e. more frequent than daily.
    
      case frequency_id
         when Frequency::HALF_HOURLY
            puts "Frequency: half hourly"
            return (last_run < time_now - (30.minutes))
          when Frequency::HOURLY
            puts "Frequency: hourly"
            return (last_run < time_now - (1.hour))
          when Frequency::FOUR_TIMES_A_DAY
            puts "Frequency: four times a day"
            return (last_run < time_now - (6.hours))
          when Frequency::TWICE_A_DAY
            puts "Frequency:twice a day"
            return (last_run < time_now - (12.hours))
          else 
            puts "UNKNOWN FREQUENCY!"
            return false
      end # end case
      
    end # end if-else
  end # method

  def self.check_minutes_past_midnight(time_of_day_to_run, time_now)
    current_mins_past_midnight = calculate_current_minutes_past_midnight(time_now)   
    puts "Current minutes past midnight: " + current_mins_past_midnight.to_s
    puts "Minutes past midnight to run: " + time_of_day_to_run.to_s
    return current_mins_past_midnight > time_of_day_to_run
  end
  
  def self.calculate_current_minutes_past_midnight(time_now)
    (time_now.hour*60) + time_now.min
  end
  
  
end