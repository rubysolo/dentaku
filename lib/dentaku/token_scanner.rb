require 'dentaku/token'

module Dentaku
  class TokenScanner
    def initialize(category, regexp, converter=nil)
      @category  = category
      @regexp    = %r{\A(#{ regexp })}i
      @converter = converter
    end

    def scan(string)
      if m = @regexp.match(string)
        value = raw = m.to_s
        value = @converter.call(raw) if @converter

        return Token.new(@category, value, raw)
      end

      false
    end
  end
end
