module Remaining::ActAsForecast
  
  # Expects these accessors to be present:
  # changes
  # An array of changes of objects using the ActAsChange mixin
  
  def calculate(target_value = 0)
    return nil if changes.nil? || changes.empty?
    amount = intervals.first.total_changed
    new_amount = nil
    intervals[0..-1].each do |interval|
      if new_amount.nil?
        new_amount = amount
      else
        new_amount = amount + interval.total_changed
      end
      if new_amount > amount
        return interval.start_date if target_value <= new_amount && target_value >= amount
      else
        return interval.start_date if target_value >= new_amount && target_value <= amount
      end
      amount = new_amount
    end
    nil
  end
  
  def least_squares
    sorted_changes = intervals
    value_changes = sorted_changes.map(&:total_changed)
    values = (value_changes.size).times.collect do |index|
      value_changes[0..(index)].inject(&:+)
    end
    regression sorted_changes.map {|interval| interval.start_date - intervals.first.start_date }, values, 1
  end
  
  private

  def order_changes_by_date
    changes.sort { |a,b| a.start_date <=> b.start_date }
  end
  
  def intervals
    all_dates = changes.inject([]) do |all_dates, change|
      if change.periodicity.nil?
        all_dates + [change.start_date, change.end_date]
      else
        all_dates + (1..((change.end_date - change.start_date)/change.periodicity).floor).map { |i| change.start_date + (change.periodicity * i) }
      end
    end.sort
    all_dates.each_index.collect do |i|
      focused_changes = changes_in(all_dates[i], all_dates[i+1])
      Interval.new(all_dates[i], all_dates[i+1], focused_changes) unless focused_changes.empty?
    end.compact
  end
  
  def changes_in(start_date, end_date = nil)
    changes.select { |change| change.start_date <= start_date && (end_date.nil? ? change.end_date.nil? : end_date <= change.end_date) }
  end
  
  # Copied from https://gist.github.com/990667
  def regression(x, y, degree)
    x_data = x.map {|xi| (0..degree).map{|pow| (xi**pow) }}
    mx = Matrix[*x_data]
    my = Matrix.column_vector y
    ((mx.t * mx).inv * mx.t * my).transpose.to_a[0].reverse
  end
end