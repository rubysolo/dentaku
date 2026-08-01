require 'tsort'

module Dentaku
  class DependencyResolver
    include TSort

    def self.find_resolve_order(vars_to_dependencies_hash, case_sensitive = false)
      self.new(vars_to_dependencies_hash, case_sensitive).sort
    end

    def initialize(vars_to_dependencies_hash, case_sensitive = false)
      @case_sensitive = case_sensitive
      @key_mapping = Hash[vars_to_dependencies_hash.keys.map { |k| [normalized_name(k), k] }]
      # normalize variables and their dependencies alike so child lookups match
      @vars_to_deps = Hash[vars_to_dependencies_hash.map { |k, v| [normalized_name(k), v.map { |d| normalized_name(d) }] }]
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

    private

    def normalized_name(variable_name)
      @case_sensitive ? variable_name.to_s : variable_name.to_s.downcase
    end
  end
end
