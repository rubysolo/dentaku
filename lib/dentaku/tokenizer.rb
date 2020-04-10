require 'dentaku/token'
require 'dentaku/token_matcher'
require 'dentaku/token_scanner'

module Dentaku
  class Tokenizer
    attr_reader :case_sensitive, :aliases

    LPAREN = TokenMatcher.new(:grouping, :open)
    RPAREN = TokenMatcher.new(:grouping, :close)

    def tokenize(string, options = {})
      @nesting = 0
      @tokens  = []
      @aliases = options.fetch(:aliases, global_aliases)
      input    = strip_comments(string.to_s.dup)
      input    = replace_aliases(input)
      @case_sensitive = options.fetch(:case_sensitive, false)

      until input.empty?
        scanned = TokenScanner.scanners(case_sensitive: case_sensitive).any? do |scanner|
          scanned, input = scan(input, scanner)
          scanned
        end

        unless scanned
          fail! :parse_error, at: input
        end
      end

      fail! :too_many_opening_parentheses if @nesting > 0

      @tokens
    end

    def last_token
      @tokens.last
    end

    def scan(string, scanner)
      if tokens = scanner.scan(string, last_token)
        tokens.each do |token|
          if token.empty?
            fail! :unexpected_zero_width_match,
                  token_category: token.category, at: string
          end

          @nesting += 1 if LPAREN == token
          @nesting -= 1 if RPAREN == token
          fail! :too_many_closing_parentheses if @nesting < 0

          @tokens << token unless token.is?(:whitespace)
        end

        match_length = tokens.map(&:length).reduce(:+)
        [true, string[match_length..-1]]
      else
        [false, string]
      end
    end

    def strip_comments(input)
      input.gsub(/\/\*[^*]*\*+(?:[^*\/][^*]*\*+)*\//, '')
    end

    def replace_aliases(string)
      return string unless @aliases.any?

      string.gsub!(alias_regex) do |match|
        match_regex = /^#{Regexp.escape(match)}$/i

        @aliases.detect do |(_key, aliases)|
          !aliases.grep(match_regex).empty?
        end.first
      end

      string
    end

    def alias_regex
      values = @aliases.values.flatten.join('|')
      /(?<=\p{Punct}|[[:space:]]|\A)(#{values})(?=\()/i
    end

    private

    def global_aliases
      return {} unless Dentaku.respond_to?(:aliases)
      Dentaku.aliases
    end

    def fail!(reason, **meta)
      message =
        case reason
        when :parse_error
          "parse error at: '#{meta.fetch(:at)}'"
        when :too_many_opening_parentheses
          "too many opening parentheses"
        when :too_many_closing_parentheses
          "too many closing parentheses"
        when :unexpected_zero_width_match
          "unexpected zero-width match (:#{meta.fetch(:category)}) at '#{meta.fetch(:at)}'"
        else
          raise ::ArgumentError, "Unhandled #{reason}"
        end

      raise TokenizerError.for(reason, **meta), message
    end
  end
end
