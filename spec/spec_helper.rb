require "rubygems"
require 'rspec'

require File.expand_path("../lib/remaining", File.dirname(__FILE__))

module Remaining::ObjectMother
  
  class MyForecast
    attr_reader :changes
    include Remaining::ActAsForecast
    
    def initialize
      @changes = []
    end
  end
  
  class MyChange
    attr_accessor :amount
    attr_reader :start_date, :end_date, :periodicity
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
    now + 86400 * number_of_days
  end
  
  def now
    @base_time ||= Time.now
  end
  
end

RSpec.configure do |config|
  include Remaining::ObjectMother
end