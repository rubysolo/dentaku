require 'tsort'

module Dentaku
  class DependencyResolver
    include TSort

    def self.find_resolve_order(vars_to_dependencies_hash)
      self.new(vars_to_dependencies_hash).tsort
    end

    def initialize(vars_to_dependencies_hash)
      # ensure variables are strings
      @vars_to_deps = Hash[vars_to_dependencies_hash.map { |k, v| [k.to_s, v]}]
    end

    def tsort_each_node(&block)
      @vars_to_deps.each_key(&block)
    end

    def tsort_each_child(node, &block)
      @vars_to_deps.fetch(node.to_s, []).each(&block)
    end
  end
end
