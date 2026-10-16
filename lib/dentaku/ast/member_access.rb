require_relative "../exceptions"
require_relative "./node"

module Dentaku
  module AST
    # Reads a named attribute from a hash-valued expression: `a[0].name`,
    # `FILTER(items, i, i.x > 1)[0].name`, `(item).name`.
    #
    # Member access is nil-safe: `NULL.name` is NULL, so a lookup such as
    # `FILTER(...)[0].name` is NULL when nothing matches.
    #
    # Plain dotted identifiers such as `item.name` are still resolved as a
    # single identifier; member access only applies after `]` or `)`.
    class MemberAccess < Node
      attr_reader :structure, :member, :case_sensitive

      def initialize(structure, member, case_sensitive: false)
        @structure = structure
        @member = member
        @case_sensitive = case_sensitive
      end

      def value(context = {})
        structure = @structure.value(context)
        return nil if structure.nil?

        unless structure.is_a?(::Hash)
          raise Dentaku::ArgumentError.for(:incompatible_type, actual: structure),
                "#{self.class} requires a hash, but got #{structure.class}"
        end

        key = find_key(structure)

        if key.nil?
          raise Dentaku::ArgumentError.for(:invalid_value, actual: member),
                "no key '#{member}' in #{structure.keys.inspect}"
        end

        structure[key]
      end

      def dependencies(context = {})
        @structure.dependencies(context)
      end

      def type
        nil
      end

      def accept(visitor)
        visitor.visit_member_access(self)
      end

      private

      # string and symbol keys are both accepted; outside case-sensitive mode
      # an exact match wins over a case-insensitive one
      def find_key(hash)
        return member if hash.key?(member)
        return member.to_sym if hash.key?(member.to_sym)
        return nil if case_sensitive

        hash.each_key.find { |key| key.to_s.casecmp?(member) }
      end

      def compute_pure?
        @structure.pure?
      end
    end
  end
end
