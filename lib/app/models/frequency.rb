class Frequency < ActiveRecord::Base
  
  # consts for the different frequencies
  ASAP = 1
  HALF_HOURLY = 2
  HOURLY = 3
  FOUR_TIMES_A_DAY = 4
  TWICE_A_DAY = 5
  DAILY = 6
  WEEKLY = 7
  FORTNIGHTLY = 8
  MONTHLY = 9
  
  has_many :scheduled_tasks
  
end