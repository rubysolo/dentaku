module Dentaku
  class DateArithmetic
    def initialize(date)
      if date.respond_to?(:strftime)
        @base = date
      else
        @base = Time.parse(date).to_datetime
      end
    end

    def add(duration)
      case duration
      when Numeric
        @base + duration
      when Dentaku::AST::Duration::Value
        case @base
        when Time
          change_datetime(@base.to_datetime, duration.unit, duration.value).to_time
        else
          change_datetime(@base, duration.unit, duration.value)
        end
      else
        raise Dentaku::ArgumentError.for(:incompatible_type, value: duration, for: Numeric),
          "'#{duration || duration.class}' is not coercible for date arithmetic"
      end
    end

    def sub(duration)
      case duration
      when Date, DateTime, Numeric, Time
        @base - duration
      when Dentaku::AST::Duration::Value
        case @base
        when Time
          change_datetime(@base.to_datetime, duration.unit, -duration.value).to_time
        else
          change_datetime(@base, duration.unit, -duration.value)
        end
      when Dentaku::TokenScanner::DATE_TIME_REGEXP
        @base - Time.parse(duration).to_datetime
      else
        raise Dentaku::ArgumentError.for(:incompatible_type, value: duration, for: Numeric),
          "'#{duration || duration.class}' is not coercible for date arithmetic"
      end
    end

    private

    def change_datetime(base, unit, value)
      case unit
      when :year
        base >> (value * 12)
      when :month
        base >> value
      when :day
        base + value
      end
    end
  end
end
