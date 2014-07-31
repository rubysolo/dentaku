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
=> 20
```

Okay, not terribly exciting.  But what if you want to have a reference to a
variable, and evaluate it at run-time?  Here's how that would look:

```ruby
calculator.evaluate('kiwi + 5', kiwi: 2)
=> 7
```

You can also store the variable values in the calculator's memory and then
evaluate expressions against those stored values:

```ruby
calculator.store(peaches: 15)
calculator.evaluate('peaches - 5')
=> 10
calculator.evaluate('peaches >= 15')
=> true
```

For maximum CS geekery, `bind` is an alias of `store`.

Dentaku understands precedence order and using parentheses to group expressions
to ensure proper evaluation:

```ruby
calculator.evaluate('5 + 3 * 2')
=> 11
calculator.evaluate('(5 + 3) * 2')
=> 16
```

A number of functions are also supported.  Okay, the number is currently five,
but more will be added soon.  The current functions are
`if`, `not`, `round`, `rounddown`, and `roundup`, and they work like their counterparts in Excel:

```ruby
calculator.evaluate('if (pears < 10, 10, 20)', pears: 5)
=> 10
calculator.evaluate('if (pears < 10, 10, 20)', pears: 15)
=> 20
```

`round`, `rounddown`, and `roundup` can be called with or without the number of decimal places:

```ruby
calculator.evaluate('round(8.2)')
=> 8
calculator.evaluate('round(8.2759, 2)')
=> 8.28
```

`round` and `rounddown` round down, while `roundup` rounds up.

If you're too lazy to be building calculator objects, there's a shortcut just
for you:

```ruby
Dentaku('plums * 1.5', plums: 2)
=> 3.0
```


BUILT-IN OPERATORS AND FUNCTIONS
---------------------------------

Math: `+ - * / %`

Logic: `< > <= >= <> != = AND OR`

Functions: `IF NOT ROUND ROUNDDOWN ROUNDUP`


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
list could be defined as: `[:non_close_plus]` (one or more tokens that are not
closing parentheses).  See the
[rules definitions](https://github.com/rubysolo/dentaku/blob/master/lib/dentaku/token_matcher.rb#L61)
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
=> 9
> c.evaluate('EXP(2,3)')
=> 8
```

Here's an example of adding the `max` function:

```ruby
> c = Dentaku::Calculator.new
> c.add_function(
    name: :max,
    type: :numeric,
    signature: [:non_close_plus],
    body: ->(*args) { args.max }
  )
> c.evaluate 'MAX(5,3,9,6,2)'
=> 9
```


THANKS
------

Big thanks to [ElkStone Basements](http://www.elkstonebasements.com/) for
allowing me to extract and open source this code.  Thanks also to all the
contributors:

* [CraigCottingham](https://github.com/CraigCottingham)
* [arnaudl](https://github.com/arnaudl)
* [thbar](https://github.com/thbar) / [BoxCar](https://www.boxcar.io)
* [antonversal](https://github.com/antonversal)
* [mvbrocato](https://github.com/mvbrocato)
* [brixen](https://github.com/brixen)
* [0xCCD](https://github.com/0xCCD)


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

