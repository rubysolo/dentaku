require 'spec_helper'
require 'open3'
require 'rbconfig'

# The function specs require their own files, so a function that
# `require 'dentaku'` never loads still passes them. Load the gem in a
# fresh process to see what users actually get.
describe 'built-in functions' do
  it 'are all loaded by requiring dentaku' do
    lib = File.expand_path('../lib', __dir__)
    script = <<~RUBY
      require 'dentaku'
      loaded = $LOADED_FEATURES.map { |f| File.expand_path(f) }
      puts Dir[File.join(#{lib.inspect}, 'dentaku/ast/functions/*.rb')].reject { |f| loaded.include?(f) }
    RUBY

    output, status = Open3.capture2e(RbConfig.ruby, '-I', lib, '-e', script)

    expect(status).to be_success, output
    expect(output.lines.map { |f| File.basename(f.chomp) }).to eq([])
  end

  it 'include MUL' do
    expect(Dentaku::Calculator.new.evaluate!('MUL(2, 3, 4)')).to eq(24)
  end
end
