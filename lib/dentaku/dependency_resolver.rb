require 'tsort'

module Dentaku
  class DependencyResolver
    include TSort

    def self.find_resolve_order(vars_to_dependencies_hash, case_sensitive = false)
      self.new(vars_to_dependencies_hash).sort
    end

    def initialize(vars_to_dependencies_hash)
      @key_mapping = Hash[vars_to_dependencies_hash.keys.map { |k| [k.downcase, k] }]
      # ensure variables are normalized strings
      @vars_to_deps = Hash[vars_to_dependencies_hash.map { |k, v| [k.downcase.to_s, v] }]
    end

    def sort
      tsort.map { |k| @key_mapping.fetch(k, k) }
    end

    def tsort_each_node(&block)
      @vars_to_deps.each_key(&block)
    end

    def tsort_each_child(node, &block)
      @vars_to_deps.fetch(node.to_s, []).each(&block)
    end
  end
end
