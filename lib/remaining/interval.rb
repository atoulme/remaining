class Interval
  
  attr_reader :start_date, :end_date
  
  def initialize(start_date, end_date, changes)
    @start_date = start_date
    @end_date = end_date
    @changes = changes
  end
  
  def total_changed
    @changes.map { |change| change.total_changed(@start_date, @end_date) }.inject(&:+) || 0
  end
  
end