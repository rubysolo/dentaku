Dentaku
=======

[![Gem Version](https://badge.fury.io/rb/dentaku.png)](http://badge.fury.io/rb/dentaku)
[![Build Status](https://travis-ci.org/rubysolo/dentaku.png?branch=master)](https://travis-ci.org/rubysolo/dentaku)
[![Code Climate](https://codeclimate.com/github/rubysolo/dentaku.png)](https://codeclimate.com/github/rubysolo/dentaku)

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

The `evalutate` method will return `nil` if there is an error in the formula.
If this is not the desired behavior, use `evaluate!`, which will raise an
exception.

```ruby
calculator.evaluate('10 * x')
#=> nil
calculator.evaluate!('10 * x')
Dentaku::UnboundVariableError: Dentaku::UnboundVariableError
```

A number of functions are also supported.  Okay, the number is currently five,
but more will be added soon.  The current functions are
`if`, `not`, `round`, `rounddown`, and `roundup`, and they work like their
counterparts in Excel:

```ruby
calculator.evaluate('if (pears < 10, 10, 20)', pears: 5)
#=> 10
calculator.evaluate('if (pears < 10, 10, 20)', pears: 15)
#=> 20
```

`round`, `rounddown`, and `roundup` can be called with or without the number of decimal places:

```ruby
calculator.evaluate('round(8.2)')
#=> 8
calculator.evaluate('round(8.2759, 2)')
#=> 8.28
```

`round` and `rounddown` round down, while `roundup` rounds up.

If you're too lazy to be building calculator objects, there's a shortcut just
for you:

```ruby
Dentaku('plums * 1.5', plums: 2)
#=> 3.0
```


BUILT-IN OPERATORS AND FUNCTIONS
---------------------------------

Math: `+ - * / %`

Logic: `< > <= >= <> != = AND OR`

Functions: `IF NOT ROUND ROUNDDOWN ROUNDUP`

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

Dentaku provides two methods to help resolve formulas in order`:

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

#### Calculator.solve!
Have Dentaku figure out the order in which your formulas need to be evaluated.

Pass in a hash of {eventual_variable_name: "expression"} to `solve!` and
have Dentaku figure out dependencies (using `TSort`) for you.

Raises `TSort::Cyclic` when a valid expression order cannot be found.

```ruby
calc = Dentaku::Calculator.new
calc.store(monthly_income: 50)
need_to_compute = {
  income_taxes: "annual_income / 5",
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

EXTERNAL FUNCTIONS
------------------

I don't know everything, so I might not have implemented all the functions you
need.  Please implement your favorites and send a pull request!  Okay, so maybe
that's not feasible because:

1. You can't be bothered to share
2. You can't wait for me to respond to a pull request, you need it `NOW()`
3. The formula is the secret sauce for your startup

Whatever your reasons, Dentaku supports adding functions at runtime.  To add a
function, you'll need to specify:

* Name
* Return type
* Signature
* Body

Naming can be the hardest part, so you're on your own for that.

`:type` specifies the type of value that will be returned, most likely
`:numeric`, `:string`, or `:logical`.

`:signature` specifies the types and order of the parameters for your function.

`:body` is a lambda that implements your function.  It is passed the arguments
and should return the calculated value.

As an example, the exponentiation function takes two parameters, the mantissa
and the exponent, so the token list could be defined as: `[:numeric,
:numeric]`.  Other functions might be variadic -- consider `max`, a function
that takes any number of numeric inputs and returns the largest one.  Its token
list could be defined as: `[:arguments]` (one or more numeric, string, or logical
values, separated by commas).  See the
[rules definitions](https://github.com/rubysolo/dentaku/blob/master/lib/dentaku/token_matcher.rb#L87)
for the names of token patterns you can use.

Functions can be added individually using Calculator#add_function, or en masse using
Calculator#add_functions.

Here's an example of adding the `exp` function:

```ruby
> c = Dentaku::Calculator.new
> c.add_function(
    name: :exp,
    type: :numeric,
    signature: [:numeric, :numeric],
    body: ->(mantissa, exponent) { mantissa ** exponent }
  )
> c.evaluate('EXP(3,2)')
#=> 9
> c.evaluate('EXP(2,3)')
#=> 8
```

Here's an example of adding the `max` function:

```ruby
> c = Dentaku::Calculator.new
> c.add_function(
    name: :max,
    type: :numeric,
    signature: [:arguments],
    body: ->(*args) { args.max }
  )
> c.evaluate 'MAX(8,6,7,5,3,0,9)'
#=> 9
```


THANKS
------

Big thanks to [ElkStone Basements](http://www.elkstonebasements.com/) for
allowing me to extract and open source this code.  Thanks also to all the
contributors:

* [0xCCD](https://github.com/0xCCD)
* [AlexeyMK](https://github.com/AlexeyMK)
* [CraigCottingham](https://github.com/CraigCottingham)
* [antonversal](https://github.com/antonversal)
* [arnaudl](https://github.com/arnaudl)
* [bernardofire](https://github.com/bernardofire)
* [brixen](https://github.com/brixen)
* [jasonhutchens](https://github.com/jasonhutchens)
* [jmangs](https://github.com/jmangs)
* [mvbrocato](https://github.com/mvbrocato)
* [schneidmaster](https://github.com/schneidmaster)
* [thbar](https://github.com/thbar) / [BoxCar](https://www.boxcar.io)


LICENSE
-------

(The MIT License)

Copyright © 2012 Solomon White

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

