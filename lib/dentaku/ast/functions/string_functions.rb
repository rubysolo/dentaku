require_relative '../function'

module Dentaku
  module AST
    module StringFunctions
      class Base < Function
        def type
          :string
        end

        def negative_argument_failure(fun, arg = 'length')
          raise Dentaku::ArgumentError.for(
            :invalid_value,
            function_name: "#{fun}()"
          ), "#{fun}() requires #{arg} to be positive"
        end
      end

      class Left < Base
        def self.min_param_count
          2
        end

        def self.max_param_count
          2
        end

        def initialize(*args)
          super
          @string, @length = *@args
        end

        def value(context = {})
          string = @string.value(context).to_s
          length = Dentaku::AST::Function.numeric(@length.value(context)).to_i
          negative_argument_failure('LEFT') if length < 0
          string[0, length]
        end
      end

      class Right < Base
        def self.min_param_count
          2
        end

        def self.max_param_count
          2
        end

        def initialize(*args)
          super
          @string, @length = *@args
        end

        def value(context = {})
          string = @string.value(context).to_s
          length = Dentaku::AST::Function.numeric(@length.value(context)).to_i
          negative_argument_failure('RIGHT') if length < 0
          string[length * -1, length] || string
        end
      end

      class Mid < Base
        def self.min_param_count
          3
        end

        def self.max_param_count
          3
        end

        def initialize(*args)
          super
          @string, @offset, @length = *@args
        end

        def value(context = {})
          string = @string.value(context).to_s
          offset = Dentaku::AST::Function.numeric(@offset.value(context)).to_i
          negative_argument_failure('MID', 'offset') if offset < 0
          length = Dentaku::AST::Function.numeric(@length.value(context)).to_i
          negative_argument_failure('MID') if length < 0
          string[offset - 1, length].to_s
        end
      end

      class Len < Base
        def self.min_param_count
          1
        end

        def self.max_param_count
          1
        end

        def initialize(*args)
          super
          @string = @args[0]
        end

        def value(context = {})
          string = @string.value(context).to_s
          string.length
        end

        def type
          :numeric
        end
      end

      class Find < Base
        def self.min_param_count
          2
        end

        def self.max_param_count
          2
        end

        def initialize(*args)
          super
          @needle, @haystack = *@args
        end

        def value(context = {})
          needle = @needle.value(context)
          needle = needle.to_s unless needle.is_a?(Regexp)
          haystack = @haystack.value(context).to_s
          pos = haystack.index(needle)
          pos && pos + 1
        end

        def type
          :numeric
        end
      end

      class Substitute < Base
        def self.min_param_count
          3
        end

        def self.max_param_count
          3
        end

        def initialize(*args)
          super
          @original, @search, @replacement = *@args
        end

        def value(context = {})
          original = @original.value(context).to_s
          search = @search.value(context)
          search = search.to_s unless search.is_a?(Regexp)
          replacement = @replacement.value(context).to_s
          original.sub(search, replacement)
        end
      end

      class Concat < Base
        def self.min_param_count
          1
        end

        def self.max_param_count
          Float::INFINITY
        end

        def initialize(*args)
          super
        end

        def value(context = {})
          @args.map { |arg| arg.value(context).to_s }.join
        end
      end

      class Contains < Base
        def self.min_param_count
          2
        end

        def self.max_param_count
          2
        end

        def initialize(*args)
          super
          @needle, @haystack = *args
        end

        def value(context = {})
          @haystack.value(context).to_s.include? @needle.value(context).to_s
        end

        def type
          :logical
        end
      end
    end
  end
end

Dentaku::AST::Function.register_class(:left,       Dentaku::AST::StringFunctions::Left)
Dentaku::AST::Function.register_class(:right,      Dentaku::AST::StringFunctions::Right)
Dentaku::AST::Function.register_class(:mid,        Dentaku::AST::StringFunctions::Mid)
Dentaku::AST::Function.register_class(:len,        Dentaku::AST::StringFunctions::Len)
Dentaku::AST::Function.register_class(:find,       Dentaku::AST::StringFunctions::Find)
Dentaku::AST::Function.register_class(:substitute, Dentaku::AST::StringFunctions::Substitute)
Dentaku::AST::Function.register_class(:concat,     Dentaku::AST::StringFunctions::Concat)
Dentaku::AST::Function.register_class(:contains,   Dentaku::AST::StringFunctions::Contains)
