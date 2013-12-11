require 'dentaku/calculator'

describe Dentaku::Calculator do
  describe 'functions' do
    describe 'external functions' do

      let(:with_external_funcs) do
        c = described_class.new

        rule = { :name => :now, :tokens => [], :body => ->(*args) { Dentaku::Token.new(:string, Time.now.to_s) } }
        c.add_rule rule

        new_rules = [
          {
            :name => :exp,
            :tokens => [ :non_group_star, :comma, :non_group_star ],
            :body => ->(*args) do
              ## first one is function name
              ## second one is open parenthesis
              ## last one is close parenthesis
              ## all others are commas
              _, _, mantissa, _, exponent, _ = args
              Dentaku::Token.new(:numeric, (mantissa.value ** exponent.value))
            end
          },
        ]

        c.add_rules new_rules
      end

      it 'should include NOW' do
        now = with_external_funcs.evaluate('NOW()')
        now.should_not be_nil
        now.should_not be_empty
      end

      it 'should include EXP' do
        with_external_funcs.evaluate('EXP(2,3)').should eq(8)
        with_external_funcs.evaluate('EXP(3,2)').should eq(9)
        with_external_funcs.evaluate('EXP(mantissa,exponent)', :mantissa => 2, :exponent => 4).should eq(16)
      end
    end
  end
end
