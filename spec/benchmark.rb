#!/usr/bin/env ruby

require 'dentaku'
require 'allocation_stats'
require 'benchmark'

puts "Dentaku version #{Dentaku::VERSION}"
puts "Ruby version #{RUBY_VERSION}"

with_duplicate_variables = [
  "R1+R2+R3+R4+R5+R6",
  {"R1"=>100000, "R2"=>0, "R3"=>200000, "R4"=>0, "R5"=>500000, "R6"=>0, "r1"=>100000, "r2"=>0, "r3"=>200000, "r4"=>0, "r5"=>500000, "r6"=>0}
]

without_duplicate_variables = [
  "R1+R2+R3+R4+R5+R6",
  {"R1"=>100000, "R2"=>0, "R3"=>200000, "R4"=>0, "R5"=>500000, "R6"=>0}
]

def test(args, custom_function: true)
  calls = [ args ] * 100

  10.times do |i|

    stats = nil
    bm = Benchmark.measure do
      stats = AllocationStats.trace do

        calls.each do |formula, bound|

          calculator = Dentaku::Calculator.new

          if custom_function
            calculator.add_function(
              :sum,
              :numeric,
              ->(numbers) { numbers.inject(:+) }
            )
          end

          calculator.evaluate(formula, bound)
        end
      end
    end

    puts "  run #{i}: #{bm.total}"
    puts stats.allocations(alias_paths: true).group_by(:sourcefile, :class).to_text
  end
end

case ARGV[0]
when '1'
  puts "with duplicate (downcased) variables, with a custom function:"
  test(with_duplicate_variables, custom_function: true)

when '2'
  puts "with duplicate (downcased) variables, without a custom function:"
  test(with_duplicate_variables, custom_function: false)

when '3'
  puts "without duplicate (downcased) variables, with a custom function:"
  test(without_duplicate_variables, custom_function: true)

when '4'
  puts "with duplicate (downcased) variables, without a custom function:"
  test(without_duplicate_variables, custom_function: false)

else
  puts "select a run option (1-4)"
end
