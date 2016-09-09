Dentaku
=======

[![Join the chat at https://gitter.im/rubysolo/dentaku](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/rubysolo/dentaku?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Gem Version](https://badge.fury.io/rb/dentaku.png)](http://badge.fury.io/rb/dentaku)
[![Build Status](https://travis-ci.org/rubysolo/dentaku.png?branch=master)](https://travis-ci.org/rubysolo/dentaku)
[![Code Climate](https://codeclimate.com/github/rubysolo/dentaku.png)](https://codeclimate.com/github/rubysolo/dentaku)
[![Hakiri](https://hakiri.io/github/rubysolo/dentaku/master.svg)](https://hakiri.io/github/rubysolo/dentaku)

DESCRIPTION
-----------

Dentaku is a parser and evaluator for a mathematical and logical formula
language that allows run-time binding of values to variables referenced in the
formulas.  It is intended to safely evaluate untrusted expressions without
opening security holes.

EXAMPLE
-------

This is probably simplest to illustrate in code:

```ruby
calculator = Dentaku::Calculator.new
calculator.evaluate('10 * 2')
#=> 20
```

Okay, not terribly exciting.  But what if you want to have a reference to a
variable, and evaluate it at run-time?  Here's how that would look:

```ruby
calculator.evaluate('kiwi + 5', kiwi: 2)
#=> 7
```

You can also store the variable values in the calculator's memory and then
evaluate expressions against those stored values:

```ruby
calculator.store(peaches: 15)
calculator.evaluate('peaches - 5')
#=> 10
calculator.evaluate('peaches >= 15')
#=> true
```

For maximum CS geekery, `bind` is an alias of `store`.

Dentaku understands precedence order and using parentheses to group expressions
to ensure proper evaluation:

```ruby
calculator.evaluate('5 + 3 * 2')
#=> 11
calculator.evaluate('(5 + 3) * 2')
#=> 16
```

The `evaluate` method will return `nil` if there is an error in the formula.
If this is not the desired behavior, use `evaluate!`, which will raise an
exception.

```ruby
calculator.evaluate('10 * x')
#=> nil
calculator.evaluate!('10 * x')
Dentaku::UnboundVariableError: Dentaku::UnboundVariableError
```

Dentaku has built-in functions (including `if`, `not`, `min`, `max`, and
`round`) and the ability to define custom functions (see below). Functions
generally work like their counterparts in Excel:

```ruby
calculator.evaluate('if (pears < 10, 10, 20)', pears: 5)
#=> 10
calculator.evaluate('if (pears < 10, 10, 20)', pears: 15)
#=> 20
```

`round` can be called with or without the number of decimal places:

```ruby
calculator.evaluate('round(8.2)')
#=> 8
calculator.evaluate('round(8.2759, 2)')
#=> 8.28
```

`round` follows rounding rules, while `roundup` and `rounddown` are `ceil` and
`floor`, respectively.

If you're too lazy to be building calculator objects, there's a shortcut just
for you:

```ruby
Dentaku('plums * 1.5', plums: 2)
#=> 3.0
```

PERFORMANCE
-----------

The flexibility and safety of Dentaku don't come without a price.  Tokenizing a
string, parsing to an AST, and then evaluating that AST are about 2 orders of
magnitude slower than doing the same math in pure Ruby!

The good news is that most of the time is spent in the tokenization and parsing
phases, so if performance is a concern, you can enable AST caching:

```ruby
Dentaku.enable_ast_cache!
```

After this, Dentaku will cache the AST of each formula that it evaluates, so
subsequent evaluations (even with different values for variables) will be much
faster -- closer to 4x native Ruby speed.  As usual, these benchmarks should be
considered rough estimates, and you should measure with representative formulas
from your application.  Also, if new formulas are constantly introduced to your
application, AST caching will consume more memory with each new formula.

BUILT-IN OPERATORS AND FUNCTIONS
---------------------------------

Math: `+`, `-`, `*`, `/`, `%`

Logic: `<`, `>`, `<=`, `>=`, `<>`, `!=`, `=`, `AND`, `OR`

Functions: `IF`, `NOT`, `MIN`, `MAX`, `ROUND`, `ROUNDDOWN`, `ROUNDUP`

Selections: `CASE` (syntax see [spec](https://github.com/rubysolo/dentaku/blob/master/spec/calculator_spec.rb#L292))

Math: all functions from Ruby's Math module, including `SIN`, `COS`, `TAN`, etc.

String: `LEFT`, `RIGHT`, `MID`, `LEN`, `FIND`, `SUBSTITUTE`, `CONCAT`

RESOLVING DEPENDENCIES
----------------------

If your formulas rely on one another, they may need to be resolved in a
particular order. For example:

```ruby
calc = Dentaku::Calculator.new
calc.store(monthly_income: 50)
need_to_compute = {
  income_taxes: "annual_income / 5",
  annual_income: "monthly_income * 12"
}
```

In the example, `annual_income` needs to be computed (and stored) before
`income_taxes`.

Dentaku provides two methods to help resolve formulas in order:

#### Calculator.dependencies
Pass a (string) expression to Dependencies and get back a list of variables (as
`:symbols`) that are required for the expression. `Dependencies` also takes
into account variables already (explicitly) stored into the calculator.

```ruby
calc.dependencies("monthly_income * 12")
#=> []
# (since monthly_income is in memory)

calc.dependencies("annual_income / 5")
#=> [:annual_income]
```

#### Calculator.solve! / Calculator.solve
Have Dentaku figure out the order in which your formulas need to be evaluated.

Pass in a hash of `{eventual_variable_name: "expression"}` to `solve!` and
have Dentaku resolve dependencies (using `TSort`) for you.

Raises `TSort::Cyclic` when a valid expression order cannot be found.

```ruby
calc = Dentaku::Calculator.new
calc.store(monthly_income: 50)
need_to_compute = {
  income_taxes:  "annual_income / 5",
  annual_income: "monthly_income * 12"
}
calc.solve!(need_to_compute)
#=> {annual_income: 600, income_taxes: 120}

calc.solve!(
  make_money: "have_money",
  have_money: "make_money"
}
#=> raises TSort::Cyclic
```

`solve!` will also raise an exception if any of the formulas in the set cannot
be evaluated (e.g. raise `ZeroDivisionError`).  The non-bang `solve` method will
find as many solutions as possible and return the symbol `:undefined` for the
problem formulas.

INLINE COMMENTS
---------------------------------

If your expressions grow long or complex, you may add inline comments for future
reference. This is particularly useful if you save your expressions in a model.

```ruby
calculator.evaluate('kiwi + 5 /* This is a comment */', kiwi: 2)
#=> 7
```

Comments can be single or multi-line. The following are also valid.

```
/*
 * This is a multi-line comment
 */

/*
 This is another type of multi-line comment
 */
```

EXTERNAL FUNCTIONS
------------------

I don't know everything, so I might not have implemented all the functions you
need.  Please implement your favorites and send a pull request!  Okay, so maybe
that's not feasible because:

1. You can't be bothered to share
1. You can't wait for me to respond to a pull request, you need it `NOW()`
1. The formula is the secret sauce for your startup

Whatever your reasons, Dentaku supports adding functions at runtime.  To add a
function, you'll need to specify a name, a return type, and a lambda that
accepts all function arguments and returns the result value.

Here's an example of adding a function named `POW` that implements
exponentiation.

```ruby
> c = Dentaku::Calculator.new
> c.add_function(:pow, :numeric, ->(mantissa, exponent) { mantissa ** exponent })
> c.evaluate('POW(3,2)')
#=> 9
> c.evaluate('POW(2,3)')
#=> 8
```

Here's an example of adding a variadic function:

```ruby
> c = Dentaku::Calculator.new
> c.add_function(:max, :numeric, ->(*args) { args.max })
> c.evaluate 'MAX(8,6,7,5,3,0,9)'
#=> 9
```

(However both of these are already built-in -- the `^` operator and the `MAX`
function)

Functions can be added individually using Calculator#add_function, or en masse
using Calculator#add_functions.

THANKS
------

Big thanks to [ElkStone Basements](http://www.elkstonebasements.com/) for
allowing me to extract and open source this code.  Thanks also to all the
[contributors](https://github.com/rubysolo/dentaku/graphs/contributors)!


LICENSE
-------

(The MIT License)

Copyright © 2012-2016 Solomon White

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the ‘Software’), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
