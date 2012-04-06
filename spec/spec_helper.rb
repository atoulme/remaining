require "rubygems"
require 'rspec'

require File.expand_path("../lib/remaining", File.dirname(__FILE__))

module Remaining::ObjectMother
  
  class MyForecast
    attr_accessor :changes
    include Remaining::ActAsForecast
  end
  
  class MyChange
    include Remaining::ActAsChange
  end
  
  def create_valid_forecast
    MyForecast.new
  end
  
  def create_valid_change(options = {})
    change = MyChange.new
    change.amount = options[:amount] if options[:amount]
    change.at(options[:date]) if options[:date]
    change.every(options[:periodicity]) if options[:periodicity]
    change.schedule(options[:start_date], options[:end_date]) if options[:start_date]
    change
  end
  
  def tomorrow
    days_from_now(1)
  end
  
  def in_2_days
    days_from_now(2)
  end
  
  def days_from_now(number_of_days)
    Time.now + 86400 * number_of_days
  end
end

RSpec.configure do |config|
  include Remaining::ObjectMother
end