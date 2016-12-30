require_relative '../function'

module Dentaku
  module AST
    module StringFunctions
      class Left < Function
        def initialize(*args)
          super
          @string, @length = *@args
        end

        def value(context={})
          string = @string.value(context).to_s
          length = @length.value(context)
          string[0, length]
        end
      end

      class Right < Function
        def initialize(*args)
          super
          @string, @length = *@args
        end

        def value(context={})
          string = @string.value(context).to_s
          length = @length.value(context)
          string[length * -1, length] || string
        end
      end

      class Mid < Function
        def initialize(*args)
          super
          @string, @offset, @length = *@args
        end

        def value(context={})
          string = @string.value(context).to_s
          offset = @offset.value(context)
          length = @length.value(context)
          string[offset - 1, length].to_s
        end
      end

      class Len < Function
        def initialize(*args)
          super
          @string = @args[0]
        end

        def value(context={})
          string = @string.value(context).to_s
          string.length
        end
      end

      class Find < Function
        def initialize(*args)
          super
          @needle, @haystack = *@args
        end

        def value(context={})
          needle = @needle.value(context)
          needle = needle.to_s unless needle.is_a?(Regexp)
          haystack = @haystack.value(context).to_s
          pos = haystack.index(needle)
          pos && pos + 1
        end
      end

      class Substitute < Function
        def initialize(*args)
          super
          @original, @search, @replacement = *@args
        end

        def value(context={})
          original = @original.value(context).to_s
          search = @search.value(context)
          search = search.to_s unless search.is_a?(Regexp)
          replacement = @replacement.value(context).to_s
          original.sub(search, replacement)
        end
      end

      class Concat < Function
        def initialize(*args)
          super
          @left, @right = *@args
        end

        def value(context={})
          left = @left.value(context).to_s
          right = @right.value(context).to_s
          left + right
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
