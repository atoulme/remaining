module Remaining::ActAsChange
  
  # Those accessors are assumed to be present in the classes this module is mixed in with.
  # TODO move them out to the DSL classes for clarity and document these.
  attr_accessor :amount
  attr_reader :start_date, :end_date, :date, :periodicity
  
  def schedule(start_date = Time.now, end_date = nil)
    raise "Start date cannot be later than end date" if end_date && start_date > end_date
    @start_date = start_date
    @end_date = end_date
  end
  
  def at(date)
    @date = date.is_a?(Time) ? date : Chronic.parse(date)
    raise "Cannot parse #{date} as a date" if @date.nil?
    @start_date = @end_date = @date
  end
  
  def in(duration)
    @date = Time.now + parse_time_string(duration)
    @start_date = @end_date = @date
  end
  
  def every(duration)
    @periodicity = duration.is_a?(Float) || duration.is_a?(Fixnum) ? duration : parse_time_string(duration)
    raise "Cannot parse #{duration}" if periodicity.nil?
  end
  
  def total_changed(other_start_date = start_date, other_end_date = end_date)
    raise "Cannot compute total_changed, schedule missing" if start_date.nil?
    raise "No end of period provided" if other_end_date.nil?
    raise "Cannot compute total_changed, amount missing" if amount.nil?
    return amount if periodicity.nil?
    amount * (other_end_date - other_start_date)/periodicity
  end
  
  private
  
  # Copied from rufus-scheduler
  
  DURATIONS2M = [
    [ 'y', 365 * 24 * 3600 ],
    [ 'M', 30 * 24 * 3600 ],
    [ 'w', 7 * 24 * 3600 ],
    [ 'd', 24 * 3600 ],
    [ 'h', 3600 ],
    [ 'm', 60 ],
    [ 's', 1 ]
  ]
  DURATIONS2 = DURATIONS2M.dup
  DURATIONS2.delete_at(1)

  DURATIONS = DURATIONS2M.inject({}) do |r, (k, v)|
    r[k] = v
    r
  end
  
  # Turns a string like '1m10s' into a float like '70.0', more formally,
  # turns a time duration expressed as a string into a Float instance
  # (millisecond count).
  #
  # w -> week
  # d -> day
  # h -> hour
  # m -> minute
  # s -> second
  # M -> month
  # y -> year
  # 'nada' -> millisecond
  #
  # Some examples :
  #
  #   Rufus.parse_time_string "0.5"    # => 0.5
  #   Rufus.parse_time_string "500"    # => 0.5
  #   Rufus.parse_time_string "1000"   # => 1.0
  #   Rufus.parse_time_string "1h"     # => 3600.0
  #   Rufus.parse_time_string "1h10s"  # => 3610.0
  #   Rufus.parse_time_string "1w2d"   # => 777600.0
  #
  def parse_time_string(string)

    if m = string.match(/^(\d*)\.?(\d*)([A-Za-z])(.*)$/)

      number = "#{m[1]}.#{m[2]}".to_f
      multiplier = DURATIONS[m[3]]

      raise ArgumentError.new("unknown time char '#{m[3]}'") unless multiplier

      return number * multiplier + parse_time_string(m[4])

    else

      return string.to_i / 1000.0 if string.match(/^\d+$/)
      return string.to_f if string.match(/^\d*\.?\d*$/)

      raise ArgumentError.new("cannot parse '#{string}'")
    end
  end
end