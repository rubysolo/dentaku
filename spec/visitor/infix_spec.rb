require 'spec_helper'

require 'dentaku/visitor/infix'

class ArrayProcessor
  attr_reader :expression
  include Dentaku::Visitor::Infix

  def initialize
    @expression = []
  end

  def process(node)
    @expression << node.to_s
  end
end

RSpec.describe Dentaku::Visitor::Infix do
  it 'generates array representation of operation' do
    processor = ArrayProcessor.new
    processor.visit(ast('5 + 3'))
    expect(processor.expression).to eq ['5', '+', '3']
  end

  private

  def ast(expression)
    tokens = Dentaku::Tokenizer.new.tokenize(expression)
    Dentaku::Parser.new(tokens).parse
  end
end