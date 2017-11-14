require_relative './operation'

module Dentaku
  module AST
    class Comparator < Operation
      def self.precedence
        5
      end

      def type
        :logical
      end

      def operator
        raise NotImplementedError
      end
    end

    class LessThan < Comparator
      def value(context = {})
        left.value(context) < right.value(context)
      end

      def operator
        return :<
      end
    end

    class LessThanOrEqual < Comparator
      def value(context = {})
        left.value(context) <= right.value(context)
      end

      def operator
        return :<=
      end
    end

    class GreaterThan < Comparator
      def value(context = {})
        left.value(context) > right.value(context)
      end

      def operator
        return :>
      end
    end

    class GreaterThanOrEqual < Comparator
      def value(context = {})
        left.value(context) >= right.value(context)
      end

      def operator
        return :>=
      end
    end

    class NotEqual < Comparator
      def value(context = {})
        left.value(context) != right.value(context)
      end

      def operator
        return :!=
      end
    end

    class Equal < Comparator
      def value(context = {})
        left.value(context) == right.value(context)
      end

      def operator
        return :==
      end
    end
  end
end
