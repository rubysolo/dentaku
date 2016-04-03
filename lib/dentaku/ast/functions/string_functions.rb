require_relative '../function'

module Dentaku
  module AST
    module StringFunctions
      class Left < Function
        def initialize(string, length)
          @string = string
          @length = length
        end

        def value(context={})
          @string.value(context)[0, @length.value(context)]
        end
      end

      class Right < Function
        def initialize(string, length)
          @string = string
          @length = length
        end

        def value(context={})
          string = @string.value(context)
          length = @length.value(context)
          string[length * -1, length] || string
        end
      end

      class Mid < Function
        def initialize(string, offset, length)
          @string = string
          @offset = offset
          @length = length
        end

        def value(context={})
          string = @string.value(context)
          offset = @offset.value(context)
          length = @length.value(context)
          string[offset - 1, length].to_s
        end
      end

      class Len < Function
        def initialize(string)
          @string = string
        end

        def value(context={})
          @string.value(context).length
        end
      end

      class Find < Function
        def initialize(needle, haystack)
          @needle = needle
          @haystack = haystack
        end

        def value(context={})
          needle = @needle.value(context)
          haystack = @haystack.value(context)
          pos = haystack.index(needle)
          pos && pos + 1
        end
      end

      class Substitute < Function
        def initialize(original, search, replacement)
          @original = original
          @search = search
          @replacement = replacement
        end

        def value(context={})
          original = @original.value(context)
          search = @search.value(context)
          replacement = @replacement.value(context)
          original.sub(search, replacement)
        end
      end

      class Concat < Function
        def initialize(left, right)
          @left  = left
          @right = right
        end

        def value(context={})
          @left.value(context) + @right.value(context)
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
