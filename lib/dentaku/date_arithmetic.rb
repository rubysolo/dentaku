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
        case duration.unit
        when :year
          Time.local(@base.year + duration.value, @base.month, @base.day).to_datetime
        when :month
          @base >> duration.value
        when :day
          @base + duration.value
        end
      else
        raise Dentaku::ArgumentError.for(:incompatible_type, value: duration, for: Numeric),
          "'#{duration || duration.class}' is not coercible for date arithmetic"
      end
    end

    def sub(duration)
      case duration
      when Date, DateTime, Numeric
        @base - duration
      when Dentaku::AST::Duration::Value
        case duration.unit
        when :year
          Time.local(@base.year - duration.value, @base.month, @base.day).to_datetime
        when :month
          @base << duration.value
        when :day
          @base - duration.value
        end
      when Dentaku::TokenScanner::DATE_TIME_REGEXP
        @base - Time.parse(duration).to_datetime
      else
        raise Dentaku::ArgumentError.for(:incompatible_type, value: duration, for: Numeric),
          "'#{duration || duration.class}' is not coercible for date arithmetic"
      end
    end
  end
end
