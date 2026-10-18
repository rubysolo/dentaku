require_relative "../exceptions"
require_relative "../token"
require_relative "./access"
require_relative "./string"

module Dentaku
  module AST
    # `a[0].name`: reads a hash value by name; the name is the access index
    class MemberAccess < Access
      attr_reader :member, :case_sensitive

      def initialize(structure, member, case_sensitive: false)
        super(structure, AST::String.new(Token.new(:string, member, member)))
        @member = member
        @case_sensitive = case_sensitive
      end

      def accept(visitor)
        visitor.visit_member_access(self)
      end

      private

      def read(structure, _index)
        unless structure.is_a?(::Hash)
          raise Dentaku::ArgumentError.for(:incompatible_type, actual: structure),
                "#{self.class} requires a hash, but got #{structure.class}"
        end

        key = find_key(structure)
        return structure[key] unless key.nil?

        raise Dentaku::ArgumentError.for(:invalid_value, actual: member), missing_key_message(structure)
      end

      # string and symbol keys are both accepted; outside case-sensitive mode
      # an exact match wins over a case-insensitive one
      def find_key(hash)
        return member if hash.key?(member)
        return member.to_sym if hash.key?(member.to_sym)
        return nil if case_sensitive

        hash.each_key.find { |key| key.to_s.casecmp?(member) }
      end

      def missing_key_message(hash)
        message = "no key '#{member}' in #{hash.keys.inspect}"
        dotted = hash.keys.find { |key| key.to_s.start_with?("#{member}.") }
        return message if dotted.nil?

        "#{message}; member access only reads keys that look like identifiers, " \
          "use brackets for '#{dotted}'"
      end
    end
  end
end
