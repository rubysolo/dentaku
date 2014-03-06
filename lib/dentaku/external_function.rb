class ExternalFunction < Struct.new(:name, :type, :signature, :body)
  def initialize(*)
    super
    self.name = self.name.to_sym
  end

  def tokens
    signature.flat_map { |t| [t, :comma] }[0...-1]
  end
end
