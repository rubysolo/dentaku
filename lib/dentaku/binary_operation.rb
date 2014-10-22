require 'bigdecimal'

module Dentaku
  class BinaryOperation
    attr_reader :left, :right

    def initialize(left, right)
      @left = left
      @right = right
    end

    def pow;      [:numeric, left ** right]; end
    def add;      [:numeric, left + right];  end
    def subtract; [:numeric, left - right];  end
    def multiply; [:numeric, left * right];  end

    def divide
      quotient, remainder = left.divmod(right)
      return [:numeric, quotient] if remainder == 0
      [:numeric, BigDecimal.new(left.to_s) / BigDecimal.new(right.to_s)]
    end

    def mod;      [:numeric, left % right]; end

    def le;       [:logical, left <= right]; end
    def ge;       [:logical, left >= right]; end
    def lt;       [:logical, left <  right]; end
    def gt;       [:logical, left >  right]; end
    def ne;       [:logical, left != right]; end
    def eq;       [:logical, left == right]; end

    def and;      [:logical, left && right]; end
    def or;       [:logical, left || right]; end
  end
end
