module Dentaku
  class FlatHash
    def self.from_hash(h, key = [], acc = {})
      return acc.update(key => h)  unless h.is_a? Hash
      h.each { |k, v| from_hash(v, key + [k], acc) }
      flatten_keys(acc)
    end

    def self.from_hash_with_intermediates(h, key = [], acc = {})
      acc.update(key => h) unless key.empty?
      return unless h.is_a? Hash
      h.each { |k, v| from_hash_with_intermediates(v, key + [k], acc) }
      flatten_keys(acc)
    end

    def self.flatten_keys(hash)
      hash.each_with_object({}) do |(k, v), h|
        h[flatten_key(k)] = v
      end
    end

    def self.flatten_key(segments)
      return segments.first if segments.length == 1
      key = segments.join('.')
      key = key.to_sym if segments.first.is_a?(Symbol)
      key
    end

    def self.expand(hash)
      hash.each_with_object({}) do |(k, v), r|
        hash_levels = k.to_s.split('.')
        hash_levels = hash_levels.map(&:to_sym) if k.is_a?(Symbol)
        child_hash = hash_levels[0...-1].reduce(r) { |h, n| h[n] ||= {} }
        child_hash[hash_levels.last] = v
      end
    end
  end
end
