require 'spec_helper'
require 'dentaku/expression'

describe Dentaku::Expression do
  describe 'an all literal expression' do
    it 'is fully bound' do
      static = described_class.new('1 + 1')
      expect(static).not_to be_unbound
    end
  end

  describe 'an expression with variable identifiers' do
    it 'is unbound' do
      dynamic = described_class.new('a > 5')
      expect(dynamic).to be_unbound
    end

    describe 'with values set for all variables' do
      it 'is fully bound' do
        dynamic = described_class.new('a > 5', {a: 7})
        expect(dynamic).not_to be_unbound
      end
    end
  end
end
