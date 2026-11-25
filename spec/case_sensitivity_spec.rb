require 'spec_helper'
require 'dentaku'
require 'dentaku/calculator'

describe Dentaku::Calculator do
  let(:case_sensitive)   { described_class.new(case_sensitive: true) }
  let(:case_insensitive) { described_class.new }

  it 'honours its own setting regardless of what other instances do' do
    expect(case_sensitive.evaluate('Kiwi + 5', Kiwi: -2, kiwi: 2)).to eq(3)
    expect(case_insensitive.evaluate('Kiwi + 5', Kiwi: -2, kiwi: 2)).to eq(7)

    # same two settings, created and evaluated in the opposite order
    other_sensitive   = described_class.new(case_sensitive: true)
    other_insensitive = described_class.new
    expect(other_insensitive.evaluate('Kiwi + 5', Kiwi: -2, kiwi: 2)).to eq(7)
    expect(other_sensitive.evaluate('Kiwi + 5', Kiwi: -2, kiwi: 2)).to eq(3)
  end

  # Identifier casing used to be applied twice: once by the identifier scanner,
  # reading a class-level flag on TokenScanner that every calculator in the
  # process shared, and again by AST::Identifier using the calculator's own
  # flag. The shared flag meant one instance could overwrite another's mode
  # while the first was still tokenizing -- in practice, whenever two threads
  # evaluated at the same time, identifiers silently folded to the other
  # instance's casing.
  #
  # Reproduce that interleaving deterministically: once this calculator has
  # fetched its scanners (which is when the mode used to be recorded), let a
  # second, case-insensitive calculator tokenize before the first one scans its
  # identifiers. The first calculator must be unaffected.
  it 'is unaffected by another instance tokenizing while it scans' do
    interloped = false
    allow(Dentaku::TokenScanner).to receive(:scanners).and_wrap_original do |original, *args|
      original.call(*args).tap do
        next if interloped

        interloped = true
        case_insensitive.evaluate('Zz', Zz: 1)
      end
    end

    expect(case_sensitive.evaluate('Kiwi', Kiwi: -2, kiwi: 2)).to eq(-2)
    expect(case_insensitive.evaluate('Kiwi', Kiwi: -2, kiwi: 2)).to eq(2)
  end

  # casing is applied in exactly one place, AST::Identifier, which is handed
  # the mode of the calculator that owns the parse -- so the token stream keeps
  # the source casing of every identifier
  it 'leaves identifier casing to the parser' do
    tokens = Dentaku::Tokenizer.new.tokenize('Kiwi + 5')
    expect(tokens.first.value).to eq('Kiwi')
  end
end
