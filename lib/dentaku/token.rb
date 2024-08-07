module Dentaku
  class Token
    attr_reader :category, :raw_value, :value

    def initialize(category, value, raw_value = nil)
      @category  = category
      @value     = value
      @raw_value = raw_value
    end

    def to_s
      raw_value || value
    end

    def length
      raw_value.to_s.length
    end

    def empty?
      length.zero?
    end

    def operator?
      is?(:operator)
    end

    def grouping?
      is?(:grouping)
    end

    def open?
      grouping? && value == :open
    end

    def close?
      grouping? && value == :close
    end

    def is?(c)
      category == c
    end

    def ==(other)
      (category.nil? || other.category.nil? || category == other.category) &&
      (value.nil?    || other.value.nil?    || value    == other.value)
    end
  end
end
