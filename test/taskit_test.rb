require File.dirname(__FILE__) + '/test_helper.rb' 

# some example tasks for this test.
require File.dirname(__FILE__) + '/test_tasks/fail.rb'
require File.dirname(__FILE__) + '/test_tasks/success_1.rb'
require File.dirname(__FILE__) + '/test_tasks/success_2.rb'


class TaskitTest < ActiveSupport::TestCase
    
  load_schema 
    
  Fixtures.create_fixtures(File.dirname(__FILE__) + '/fixtures', ActiveRecord::Base.connection.tables)
  
  fixtures :tasks, :scheduled_tasks
  
  def test_determine_whether_to_run_times_half_hourly  
    # negative case
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::HALF_HOURLY,  0, 15.minutes.ago, Time.now) 
    # border negative case
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::HALF_HOURLY,  0, 29.minutes.ago, Time.now) 
    # border positive case
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::HALF_HOURLY,  0, 30.minutes.ago, Time.now)   
    # positive case 
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::HALF_HOURLY,  0, 45.minutes.ago, Time.now)  
  end
  
  def test_determine_whether_to_run_hourly   
    # negative case
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::HOURLY,  0, 30.minutes.ago, Time.now)   
    # border negative case
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::HOURLY,  0, 59.minutes.ago, Time.now)   
    # border positive case
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::HOURLY,  0, 60.minutes.ago, Time.now)     
    # positive case 
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::HOURLY,  0, 90.minutes.ago, Time.now)  
  end
  
  def test_compare_four_times_a_day    
    # negative case
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::FOUR_TIMES_A_DAY,  0, 4.hours.ago, Time.now)    
    # border negative case
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::FOUR_TIMES_A_DAY,  0, ((60*5) + 59).minutes.ago, Time.now)     
    # border positive case
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::FOUR_TIMES_A_DAY,  0, 6.hours.ago, Time.now)      
    # positive case 
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::FOUR_TIMES_A_DAY,  0, 8.hours.ago, Time.now)   
  end
  
  def test_determine_whether_to_run_twice_a_day    
    # negative case
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::TWICE_A_DAY,  0, 8.hours.ago, Time.now)    
    # border negative case
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::TWICE_A_DAY,  0, ((60*11) + 59).minutes.ago, Time.now)     
    # border positive case
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::TWICE_A_DAY,  0, 12.hours.ago, Time.now)      
    # positive case 
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::TWICE_A_DAY,  0, 18.hours.ago, Time.now)  
  end
  
  def test_determine_whether_to_run_daily
    
    # For the task to run, must be next calendar day, and be after the 'time of day to run'
    
    # negative case - run daily at 2am, last run yesterday at 2am and time now is 1:55
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::DAILY,  120, Time.local(2007, "sep", 1, 2, 0), Time.local(2007, "sep", 2, 1, 55) )
    # another negative case - run daily at 2am, last run today at 2am and time now is 4am
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::DAILY,  120, Time.local(2007, "sep", 1, 2, 0), Time.local(2007, "sep", 1, 4, 00) )
    # another negative case - run daily at 2am, last run yesterday at 1am and time now is 1:55
    # even though is more than 24 hours since last run, wont run as not past time.
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::DAILY, 120, Time.local(2007, "sep", 1, 1, 0), Time.local(2007, "sep", 2, 1, 55) )
    # another negative case - run daily at 2am, last run 5 days ago at 5pm and time now is 1:55
    # even though is days since last run, wont run as not past time.
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::DAILY, 120, Time.local(2007, "sep", 1, 17, 0), Time.local(2007, "sep", 6, 1, 55) )
    
    # positive case - run daily at 2am, last run yesterday at 2am and time now is 2:05
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::DAILY, 120, Time.local(2007, "sep", 1, 2, 0), Time.local(2007, "sep", 2, 2, 05) )
    # another positive case - run daily at 2am, last run yesterday at 3am and time now is 2:45
    # even though not yet 24 hours since last run, will run as next calendar day and is past time
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::DAILY,  120, Time.local(2007, "sep", 1, 3, 0), Time.local(2007, "sep", 2, 2, 45) )
    # another positive case - run daily at 2am, last run 2 days ago at 2am and time now is 2:01
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::DAILY,  120, Time.local(2007, "sep", 1, 3, 0), Time.local(2007, "sep", 3, 2, 01) )
        
  end
  
  def test_determine_whether_to_run_weekly
    # For the task to run, must be a week later, and be after the 'time of day to run'
    
    # negative case - run weekly at 6pm, last run 7 days ago at 6pm and time now is 5:55
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::WEEKLY,  1080, Time.local(2007, "sep", 1, 18, 0), Time.local(2007, "sep", 8, 15, 55) )
    # another negative case - run weekly at 6pm, last run 6 days ago at 6pm and time now is 7pm
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::WEEKLY,  1080, Time.local(2007, "sep", 1, 18, 0), Time.local(2007, "sep", 7, 17, 00) )
    # another negative case - run weekly at 6pm, last run 8 days ago at 6pm and time now is 4pm
    # even though is more than 7 days since last run, wont run as not past time.
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::WEEKLY, 1080, Time.local(2007, "sep", 1, 18, 0), Time.local(2007, "sep", 9, 16, 00) )
    # another negative case - run weekly at 6pm, last run a month ago at 5pm and time now is 5:58
    # even though is days since last run, wont run as not past time.
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::WEEKLY, 1080, Time.local(2007, "aug", 1, 17, 0), Time.local(2007, "sep", 1, 17, 58) )
    
    # positive case - run weekly at 6pm, last run 7 days ago at 6pm and time now is 6:05
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::WEEKLY, 1080, Time.local(2007, "sep", 1, 18, 0), Time.local(2007, "sep", 8, 18, 05) )
    # another positive case - run weekly at 6pm, last run 7 days ago at 8pm and time now is 6:15
    # even though not yet a full 7 days since last run, will run as is a week later (to the day) and time is past.
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::WEEKLY,  1080, Time.local(2007, "sep", 1, 20, 0), Time.local(2007, "sep", 8, 18, 15) )
    # another positive case - run weekly at 6pm, last run 14 days ago at 7pm and time now is 6:01
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::WEEKLY,  1080, Time.local(2007, "sep", 1, 19, 0), Time.local(2007, "sep", 15, 18, 01) )
  end
  
  def test_determine_whether_to_run_fortnightly
    # For the task to run, must be 2 weeks later, and be after the 'time of day to run'
    
    # negative case - run fortnightly at 3pm, last run 14 days ago at 3pm and time now is 2:55
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::FORTNIGHTLY,  900, Time.local(2007, "sep", 1, 15, 0), Time.local(2007, "sep", 15, 14, 55) )
    # another negative case - run fortnightly at 3pm, last run 13 days ago at 3pm and time now is 4pm
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::FORTNIGHTLY,  900, Time.local(2007, "sep", 1, 15, 0), Time.local(2007, "sep", 14, 16, 00) )
    # another negative case - run fortnightly at 3pm, last run 15 days ago at 3pm and time now is 2pm
    # even though is more than 7 days since last run, wont run as not past time.
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::FORTNIGHTLY, 900, Time.local(2007, "sep", 1, 15, 0), Time.local(2007, "sep", 16, 14, 00) )
    # another negative case - run fortnightly at 3pm, last run a month ago at 3pm and time now is 2:58
    # even though is days since last run, wont run as not past time.
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::FORTNIGHTLY, 900, Time.local(2007, "aug", 1, 15, 0), Time.local(2007, "sep", 1, 14, 58) )
    
    # positive case - run fortnightly at 3pm, last run 14 days ago at 3pm and time now is 3:05
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::FORTNIGHTLY, 900, Time.local(2007, "sep", 1, 15, 0), Time.local(2007, "sep", 15, 15, 05) )
    # another positive case - run fortnightly at 3pm, last run 14 days ago at 8pm and time now is 3:15
    # even though not yet a full 14 days since last run, will run as is a fortnight later (to the day) and time is past.
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::FORTNIGHTLY,  900, Time.local(2007, "sep", 1, 20, 0), Time.local(2007, "sep", 15, 15, 15) )
    # another positive case - run fortnightly at 3pm, last run 30 days ago at 3pm and time now is 3:01
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::FORTNIGHTLY,  900, Time.local(2007, "sep", 1, 15, 0), Time.local(2007, "oct", 1, 15, 01) )
  end
  
  def test_determine_whether_to_run_monthly
    # For the task to run, must be a 30 days later, and be after the 'time of day to run'
    
    # negative case - run monthly at 11am, last run a month ago at 11am and time now is 10:55
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::MONTHLY,  660, Time.local(2007, "sep", 1, 11, 0), Time.local(2007, "oct", 1, 10, 55) )
    # another negative case - run monthly at 11am, last run 29 days ago at 11am and time now is 12pm
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::MONTHLY,  660, Time.local(2007, "sep", 2, 11, 0), Time.local(2007, "oct", 1, 12, 00) )
    # another negative case - run monthly at 11am, last run 31 days ago at 11am and time now is 9am
    # even though is more than a month since last run, wont run as not past time.
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::MONTHLY, 660, Time.local(2007, "sep", 1, 11, 0), Time.local(2007, "oct", 2, 9, 00) )
    # another negative case - run monthly at 11am, last run 2 months ago at 11am and time now is 9:59am
    # even though is months since last run, wont run as not past time.
    assert_equal false, Taskit.send(:determine_whether_to_run, Frequency::MONTHLY, 660, Time.local(2007, "aug", 1, 11, 0), Time.local(2007, "oct", 1, 9, 58) )
    
    # positive case - run monthly at 11am, last run 1 month ago at 11am and time now is 11:10
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::MONTHLY, 660, Time.local(2007, "sep", 1, 11, 0), Time.local(2007, "oct", 1, 11, 10) )
    # another positive case - run monthly at 11am, last run a month ago at 3pm and time now is 11:15
    # even though not yet a full month since last run, will run as is a month later (to the day) and time is past.
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::MONTHLY,  660, Time.local(2007, "sep", 1, 15, 0), Time.local(2007, "oct", 1, 11, 15) )
    # another positive case - run monthly at 11am, last run 2 months ago at 11am and time now is 11:01
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::MONTHLY,  660, Time.local(2007, "sep", 1, 11, 0), Time.local(2007, "nov", 1, 11, 01) )
  end
  
  def test_run_asap
    # can't really test - always returns true! just test one random case.
    assert_equal true, Taskit.send(:determine_whether_to_run, Frequency::ASAP, 660, Time.local(2007, "sep", 1, 11, 0), Time.local(2007, "oct", 1, 11, 10) )
  end
  
  # test the run scheduled task method
  def test_run_scheduled_task_success_never_run
    
    # make sure that there is nothing in the task log
    ScheduledTaskLog.destroy_all
    
    # verify that the task is not running at the mo
    assert_equal false, tasks(:success_1_task).is_running
    
    # call the task
    Taskit.send(:run_scheduled_task, scheduled_tasks(:success_1_scheduled_task), Time.now)
    
    # this should run, because it never has, and it's scheduled to run every half an hour
    logs = ScheduledTaskLog.find(:all)
    
    assert_equal 1, logs.length
    log = logs[0]
    assert scheduled_tasks(:success_1_scheduled_task).id, log.scheduled_task_id
    assert_not_nil log.start
    assert_not_nil log.end
    assert_equal true, log.success
    assert_nil log.info
    
    # check the task is still not running.
    assert_equal false, Task.find_by_name("success 1").is_running
    
  end
  
  # test the run scheduled task method
  def test_run_scheduled_task_success_run_already_1
    
    # make sure that there is nothing in the task log
    ScheduledTaskLog.destroy_all
    
    # add a log for the task, a while ago, so it will run again (this one runs every 1/2 hour)
    scheduled_task_log = ScheduledTaskLog.new
    scheduled_task_log.scheduled_task_id = scheduled_tasks(:success_1_scheduled_task).id
    scheduled_task_log.start = 31.minutes.ago
    scheduled_task_log.save
      
    # verify that the task is not running at the mo
    assert_equal false, tasks(:success_1_task).is_running
    
    # call the task
    Taskit.send(:run_scheduled_task, scheduled_tasks(:success_1_scheduled_task), Time.now)
    
    # this should run, because it never has, and it's scheduled to run every half an hour
    logs = ScheduledTaskLog.find(:all, :order => "id desc")
    
    assert_equal 2, logs.length
    log = logs[0] # get the most recent one (the new one)
    assert scheduled_tasks(:success_1_scheduled_task).id, log.scheduled_task_id
    assert_not_nil log.start
    assert_not_nil log.end
    assert_equal true, log.success
    assert_nil log.info
    
    # check the task is still not running.
    assert_equal false, Task.find_by_name("success 1").is_running
    
  end
  
  # test the run scheduled task method
  def test_run_scheduled_task_success_run_already_2
    
    # make sure that there is nothing in the task log
    ScheduledTaskLog.destroy_all
    
    # add a log for the task, a while ago, so it will not run again (this one runs every 1/2 hour)
    scheduled_task_log = ScheduledTaskLog.new
    scheduled_task_log.scheduled_task_id = scheduled_tasks(:success_1_scheduled_task).id
    scheduled_task_log.start = 28.minutes.ago
    scheduled_task_log.save
      
    # verify that the task is not running at the mo
    assert_equal false, tasks(:success_1_task).is_running
    
    # call the task
    Taskit.send(:run_scheduled_task, scheduled_tasks(:success_1_scheduled_task), Time.now)
    
    # this should not run, because it's not time to run again yet.
    logs = ScheduledTaskLog.find(:all, :order => "id desc")
    
    # still only 1 log.
    assert_equal 1, logs.length
        
    # check the task is still not running.
    assert_equal false, Task.find_by_name("success 1").is_running
    
  end
  
  def test_run_scheduled_task_already_running
    
    # make sure that there is nothing in the task log
    ScheduledTaskLog.destroy_all
    
    # verify that the task is not running at the mo
    task = tasks(:success_1_task)
    task.is_running = true
    task.save 
    
    # call the task
    Taskit.send(:run_scheduled_task, scheduled_tasks(:success_1_scheduled_task), Time.now)
    
    # this should not run because it already is
    logs = ScheduledTaskLog.find(:all)
    
    assert_equal 0, logs.length
      
    # check the task is still running
    assert_equal true, Task.find_by_name("success 1").is_running
    
  end
  
  # test the run scheduled task method with a task that we know will fail.
  def test_run_scheduled_task_fail
    
    # make sure that there is nothing in the task log
    ScheduledTaskLog.destroy_all
    
    # verify that the task is not running at the mo
    assert_equal false, tasks(:failing_task).is_running
    
    # call the task
    Taskit.send(:run_scheduled_task, scheduled_tasks(:failing_scheduled_task), Time.now)
    
    # this should run, because it never has, and it's scheduled to run every half an hour
    logs = ScheduledTaskLog.find(:all)
    
    assert_equal 1, logs.length
    log = logs[0]
    assert scheduled_tasks(:failing_scheduled_task).id, log.scheduled_task_id
    assert_not_nil log.start
    assert_not_nil log.end
    assert_equal false, log.success
    assert_equal "bad task", log.info
    
    # check the task is still not running.
    assert_equal false, Task.find_by_name("fail").is_running
    
  end
  
  # try running the main entry point method for the scheduler
  def test_run_scheduled_tasks
    # don't want to put too much in this test as we will have to keep changing it all the time as we add more tasks!
    
    # make sure that there is nothing in the task log
    ScheduledTaskLog.destroy_all
    
    Taskit.run_scheduled_tasks
    
     # this should run, because it never has, and it's scheduled to run every half an hour
    logs = ScheduledTaskLog.find(:all)
    
    # there's 3 tasks scheuled so there should be 3 logs!
    assert_equal 3, logs.length
      
    
  end
    
end
