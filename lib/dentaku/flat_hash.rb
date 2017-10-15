module Dentaku
  class FlatHash
    def self.from_hash(h, key=[], acc={})
      return acc.update({ key => h })  unless h.is_a? Hash
      h.each { |k, v| from_hash(v, key+[k], acc) }
      flatten_keys(acc)
    end

    def self.flatten_keys(hash)
      hash.each_with_object({}) { |(k, v), h| h[flatten_key(k)] = v }
    end

    def self.flatten_key(segments)
      return segments[0] if segments.length == 1
      segments.join('.')
    end
  end
end