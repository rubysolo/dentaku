require 'dentaku/token'
require 'dentaku/token_matcher'
require 'dentaku/token_scanner'

module Dentaku
  class Tokenizer
    LPAREN = TokenMatcher.new(:grouping, :open)
    RPAREN = TokenMatcher.new(:grouping, :close)

    def tokenize(string)
      @nesting = 0
      @tokens  = []
      input    = string.dup

      until input.empty?
        raise "parse error at: '#{ input }'" unless TokenScanner.scanners.any? do |scanner|
          scanned, input = scan(input, scanner)
          scanned
        end
      end

      raise "too many opening parentheses" if @nesting > 0

      @tokens
    end

    def scan(string, scanner)
      if token = scanner.scan(string)
        raise "unexpected zero-width match (:#{ token.category }) at '#{ string }'" if token.length == 0

        @nesting += 1 if LPAREN == token
        @nesting -= 1 if RPAREN == token
        raise "too many closing parentheses" if @nesting < 0

        @tokens << token unless token.is?(:whitespace)

        [true, string[token.length..-1]]
      else
        [false, string]
      end
    end
  end
end
