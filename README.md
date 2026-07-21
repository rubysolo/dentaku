Dentaku
=======

[![Join the chat at https://gitter.im/rubysolo/dentaku](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/rubysolo/dentaku?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Gem Version](https://badge.fury.io/rb/dentaku.png)](http://badge.fury.io/rb/dentaku)


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

To enter a case sensitive mode, just pass an option to the calculator instance:

```ruby
calculator.evaluate('Kiwi + 5', Kiwi: -2, kiwi: 2)
#=> 7
calculator = Dentaku::Calculator.new(case_sensitive: true)
calculator.evaluate('Kiwi + 5', Kiwi: -2, kiwi: 2)
#=> 3
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

Dentaku has built-in functions (including `if`, `not`, `min`, `max`, `sum`, and
`round`) and the ability to define custom functions (see below). Functions
generally work like their counterparts in Excel:

```ruby
calculator.evaluate('SUM(1, 1, 2, 3, 5, 8)')
#=> 20

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

LITERALS
--------

Literal keywords are case-insensitive, all following are valid: `null`, `TRUE`, `False`.

Date/time literals take an optional time (separated by a space, `T` or `|`), optional fractional seconds, and an optional timezone (`Z` or `±HH:MM`). Pass `raw_date_literals: false` to disable them.

String literals don't support escape sequences.

| Type      | Syntax                                                        | Examples                                                                                                     |
|-----------|---------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| Number    | Integer, decimal, scientific or hexadecimal                   | `42`<br>`3.14`<br>`1.5e3`<br>`.1`<br>`0xff` => `255`                                                         |
| String    | Single or double quotes                                       | `"hello"`<br>`'world'`                                                                                       |
| Boolean   | `true` / `false`                                              | `true`<br>`false`                                                                                            |
| Null      | `null` — evaluates to Ruby `nil`                              | `null`                                                                                                       |
| Date/time | ISO-style date with optional time and zone, on by default     | `2020-01-01`<br>`20-1-1`<br>`2020-01-01T13:00:00`<br>`2020-01-01\|13:00:00Z`<br>`2020-01-01 13:00:00 +02:00` |
| Array     | Braces, comma-separated (see Arrays and collection functions) | `{1, 2, 3}`<br>`{{1, 2}, {3, 4}}`                                                                            |

BUILT-IN OPERATORS AND FUNCTIONS
---------------------------------

Operator, function, and keyword names are case-insensitive, you can use `AND`, `and`, and `And`; `SUM`, `sum`, and `Sum`; `CASE`, `case`, and `Case`.

### Math operators

| Operator | Description         | Precedence | Examples                                                                                  |
|----------|---------------------|:----------:|-------------------------------------------------------------------------------------------|
| `+`      | Addition            |     10     | `1 + 2` => `3`<br>`{1} + {2}` => `[1, 2]`<br>`2022-02-24 + 3` => `2022-02-27`             |
| `-`      | Subtraction         |     10     | `5 - 2` => `3`<br>`2022-02-24 - 3` => `2022-02-21`<br>`2026-02-24 - 2022-02-24` => `1461` |
| `-`      | Unary negation      |     40     | `-x` negates `x`                                                                          |
| `*`      | Multiplication      |     20     | `4 * 3` => `12`                                                                           |
| `/`      | Division            |     20     | `9 / 3` => `3.0`<br>`10 / 4` => `2.5`                                                     |
| `%`      | Modulo              |     20     | `7 % 3` => `1`                                                                            |
| `%`      | Percentage          |     30     | `7 + 1%` => `7.01`                                                                        |
| `^`      | Exponentiation      |     30     | `9 ^ 0.5` => `3.0`<br>`2 ^ 3 ^ 2` => `64`                                                 |
| `&`      | Bitwise AND         |     0      | `6 & 3` => `2`                                                                            |
| `\|`     | Bitwise OR          |     0      | `5 \| 2` => `7`                                                                           |
| `<<`     | Bitwise shift left  |     0      | `1 << 4` => `16`                                                                          |
| `>>`     | Bitwise shift right |     0      | `32 >> 2` => `8`                                                                          |

### Numeric functions

| Name        | Description                                                             | Examples                                                                                  |
|-------------|-------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| `ABS`       | Absolute value                                                          | `ABS(-5)` => `5`<br>`ABS(5)` => `5`                                                       |
| `AVG`       | Arithmetic mean of arguments                                            | `AVG(1, 2)` => `1.5`<br>`AVG({1, 2})` => `1.5`                                            |
| `COUNT`     | Length of a single array/string argument, otherwise number of arguments | `COUNT(1, 2, 3)` => `3`<br>`COUNT({4, 5})` => `2`<br>`COUNT("foo")` => `3`                |
| `INTERCEPT` | y-intercept of the linear regression of two equal-length arrays         | `INTERCEPT({1, 2, 3, 4, 5}, {3, 4, 6, 7, 9})` => `1.3`                                    |
| `MAX`       | Largest argument                                                        | `MAX(3, 1, 2)` => `3`<br>`MAX({3, 1, 2})` => `3`                                          |
| `MIN`       | Smallest argument                                                       | `MIN(3, 1, 2)` => `1`<br>`MIN({3, 1, 2})` => `1`                                          |
| `ROUND`     | Round to 0 or specified number of decimals                              | `ROUND(1.5)` => `2`<br>`ROUND(-1.5)` => `-2`<br>`ROUND(3.14159, 3)` => `3.142`            |
| `ROUNDDOWN` | Round down to 0 or specified number of decimals                         | `ROUNDDOWN(1.5)` => `1`<br>`ROUNDDOWN(-1.5)` => `-2`<br>`ROUNDDOWN(0.9999, 3)` => `0.999` |
| `ROUNDUP`   | Round up to 0 or specified number of decimals                           | `ROUNDUP(1.5)` => `2`<br>`ROUNDUP(-1.5)` => `-1`<br>`ROUNDUP(1.0001, 3)` => `1.001`       |
| `SUM`       | Sum of arguments                                                        | `SUM(1, 2, 3)` => `6`<br>`SUM({1, 2, 3})` => `6`                                          |

### Math functions

Every method from Ruby's `Math` module is available as a function. All angles are in radians.

| Name     | Description                                           | Examples                                         |
|----------|-------------------------------------------------------|--------------------------------------------------|
| `ACOS`   | Arc cosine                                            | `ACOS(-1)` => `3.14159…`                         |
| `ACOSH`  | Inverse hyperbolic cosine                             | `ACOSH(2)` => `1.31695…`                         |
| `ASIN`   | Arc sine                                              | `ASIN(1)` => `1.57079…`                          |
| `ASINH`  | Inverse hyperbolic sine                               | `ASINH(1)` => `0.88137…`                         |
| `ATAN`   | Arc tangent                                           | `ATAN(1)` => `0.78539…`                          |
| `ATAN2`  | Arc tangent of `y / x`                                | `ATAN2(1, 1)` => `0.78539…`                      |
| `ATANH`  | Inverse hyperbolic tangent                            | `ATANH(0.5)` => `0.54930…`                       |
| `CBRT`   | Cube root                                             | `CBRT(8)` => `2.0`                               |
| `COS`    | Cosine                                                | `COS(1)` => `0.54030…`                           |
| `COSH`   | Hyperbolic cosine                                     | `COSH(1)` => `1.54308…`                          |
| `ERF`    | Gauss error function                                  | `ERF(1)` => `0.84270…`                           |
| `ERFC`   | Complementary error function (`1 - ERF`)              | `ERFC(1)` => `0.15729…`                          |
| `EXP`    | e raised to the given power                           | `EXP(1)` => `2.71828…`                           |
| `FREXP`  | Normalized signed float fraction and integer exponent | `FREXP(8)` => `[0.5, 4]`                         |
| `GAMMA`  | Gamma function                                        | `GAMMA(5)` => `24.0`                             |
| `HYPOT`  | Hypotenuse (`√(x² + y²)`)                             | `HYPOT(3, 4)` => `5.0`                           |
| `LDEXP`  | Inverse of `FREXP`                                    | `LDEXP(0.5, 4)` => `8.0`                         |
| `LGAMMA` | Log gamma and its sign                                | `LGAMMA(1)` => `[0.0, 1]`                        |
| `LOG`    | Natural logarithm, or to a given base                 | `LOG(81)` => `4.39444…`<br>`LOG(81, 3)` => `4.0` |
| `LOG2`   | Base-2 logarithm                                      | `LOG2(8)` => `3.0`                               |
| `LOG10`  | Base-10 logarithm                                     | `LOG10(1000)` => `3.0`                           |
| `SIN`    | Sine                                                  | `SIN(1)` => `0.84147…`                           |
| `SINH`   | Hyperbolic sine                                       | `SINH(1)` => `1.17520…`                          |
| `SQRT`   | Square root                                           | `SQRT(16)` => `4.0`                              |
| `TAN`    | Tangent                                               | `TAN(1)` => `1.55740…`                           |
| `TANH`   | Hyperbolic tangent                                    | `TANH(1)` => `0.76159…`                          |

### Comparison operators

| Operator     | Description           | Precedence | Examples                                  |
|--------------|-----------------------|:----------:|-------------------------------------------|
| `<`          | Less than             |     5      | `1 < 2` => `true`<br>`2 < 2` => `false`   |
| `>`          | Greater than          |     5      | `2 > 1` => `true`<br>`2 > 2` => `false`   |
| `<=`         | Less than or equal    |     5      | `2 <= 2` => `true`<br>`3 <= 2` => `false` |
| `>=`         | Greater than or equal |     5      | `2 >= 2` => `true`<br>`2 >= 3` => `false` |
| `<>` or `!=` | Not equal             |     5      | `1 != 2` => `true`<br>`1 != 1` => `false` |
| `=` or `==`  | Equal                 |     5      | `2 = 2` => `true`<br>`2 = 1` => `false`   |

### Logical operators and functions

`AND` and `OR` are available both as operators and functions. `XOR` and `NOT` are functions only. All arguments must be logical or `null`.

| Name           | Description                               | Examples                                                                                                         |
|----------------|-------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| `AND` or `&&`  | True when all operands/arguments are true | `true && true && false` => `false`<br>`AND(true, true, true)` => `true`                                          |
| `NOT`          | Logical negation                          | `NOT(true)` => `false`<br>`NOT(false)` => `true`                                                                 |
| `OR` or `\|\|` | True when any operand/argument is true    | `false \|\| false \|\| true` => `true`<br>`OR(false, false, false)` => `false`                                   |
| `XOR`          | True when exactly one argument is true    | `XOR(true, false, false)` => `true`<br>`XOR(true, false, true)` => `false`<br>`XOR(true, true, true)` => `false` |

### Conditionals

`IF(condition, when_true, when_false)` returns one of two branches based on a boolean condition:

`IF(1 > 2, 123, 456)` => `456`

`IF(2 > 1, "big", "small")` => `"big"`

`SWITCH(value, candidate1, result1, candidate2, result2, ..., default)` compares `value` against each candidate and returns the matching result, or the trailing `default` (`nil` if omitted and nothing matches):

`SWITCH("banana", "apple", 1, "banana", 2, 3)` => `2`

`SWITCH(4, 1, "a", 2, "b", "c")` => `"c"`

`CASE` provides similar behaviour using keyword form. If no branch matches and there is no `ELSE`, it raises an error:

`CASE "banana" WHEN "apple" THEN 1 WHEN "banana" THEN 2 ELSE 3 END` => `2`

`CASE 4 WHEN 1 THEN "a" WHEN 2 THEN "b" ELSE "c" END` => `"c"`

### String functions

`FIND` and `SUBSTITUTE` also accept a regular expression from a variable.

| Name         | Description                                           | Examples                                                                       |
|--------------|-------------------------------------------------------|--------------------------------------------------------------------------------|
| `CONCAT`     | Concatenates all arguments                            | `CONCAT("ABC", "DEF", "G", "HI")` => `"ABCDEFGHI"`                             |
| `CONTAINS`   | True when the substring is in the string              | `CONTAINS("app", "apple")` => `true`<br>`CONTAINS("app", "orange")` => `false` |
| `FIND`       | 1-based position of the substring, or `nil` if absent | `FIND("DE", "ABCDEFG")` => `4`<br>`FIND("X", "ABCDEFG")` => `nil`              |
| `LEFT`       | First count characters                                | `LEFT("ABCDEFG", 4)` => `"ABCD"`<br>`LEFT("AB", 4)` => `"AB"`                  |
| `LEN`        | Number of characters                                  | `LEN("ABCDEFG")` => `7`                                                        |
| `MID`        | Starting at 1-based offset take count characters      | `MID("ABCDEFG", 4, 2)` => `"DE"`                                               |
| `RIGHT`      | Last count characters                                 | `RIGHT("ABCDEFG", 4)` => `"DEFG"`<br>`RIGHT("AB", 4)` => `"AB"`                |
| `SUBSTITUTE` | Replace the first occurrence of the substring         | `SUBSTITUTE("ABCDEFG", "ABC", "x")` => `"xDEFG"`                               |

### Date functions

| Name       | Description                     | Examples                                                                                                                                                   |
|------------|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DURATION` | Amount of days, months or years | `2022-02-24 + DURATION(3, days)` => `2022-02-27`<br>`2022-02-24 - DURATION(1, month)` => `2022-01-24`<br>`2022-02-24 + DURATION(4, years)` => `2026-02-24` |

### Arrays and collection functions

| Name     | Description                                                                           | Examples                                                                                                                                  |
|----------|---------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| `{}`     | Create array                                                                          | `{10, 20, 30}` => `[10, 20, 30]`<br>`{"a", "b"}` => `["a", "b"]`<br>`{{1, 2}, {3, 4}}` => `[[1, 2], [3, 4]]`                              |
| `[]`     | Get array element at index (0-based, negative - -1 based from the end) or hash at key | `{10, 20, 30}[0]` => `10`<br>`{10, 20, 30}[-1]` => `30`<br>`hash["b"]` => `42`<br>`hash[1]` => `"a"`<br>`hash` is `{1 => "a", "b" => 42}` |
| `ALL`    | True if the expression is true for every element                                      | `ALL({1, 2, 3}, x, x > 0)` => `true`                                                                                                      |
| `ANY`    | True if the expression is true for any element                                        | `ANY({1, 2, 3}, x, x > 2)` => `true`                                                                                                      |
| `FILTER` | Get elements for which the expression is true                                         | `FILTER({1, 2, 3, 4}, x, x % 2 = 0)` => `[2, 4]`                                                                                          |
| `MAP`    | Apply the expression to every element                                                 | `MAP({1, 2, 3}, x, x ^ 3)` => `[1, 8, 27]`                                                                                                |
| `PLUCK`  | Collect one key from an array of hashes with optional default                         | `PLUCK(hashes, a)` => `[30, 40]`<br>`PLUCK(hashes, b, -1)` => `[42, -1]`<br>`hashes` is `[{a: 30, b: 42}, {a: 40}]`                       |
| `REDUCE` | Fold elements into an accumulator with optional initial value                         | `REDUCE({1, 2, 3, 4}, acc, x, acc + x, 0)` => `10`                                                                                        |

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

FUNCTION ALIASES
----------------

Every function can be aliased by synonyms. For example, it can be useful if
your application is multilingual.

```ruby
Dentaku.aliases = {
  round: ['rrrrround!', 'округлить']
}

Dentaku('rrrrround!(8.2) + округлить(8.4)') # the same as round(8.2) + round(8.4)
# 16
```

Also, if you need thread-safe aliases you can pass them to `Dentaku::Calculator`
initializer:

```ruby
aliases = {
  round: ['rrrrround!', 'округлить']
}
c = Dentaku::Calculator.new(aliases: aliases)
c.evaluate('rrrrround!(8.2) + округлить(8.4)')
# 16
```

THANKS
------

Big thanks to [ElkStone Basements](http://www.elkstonebasements.com/) for
allowing me to extract and open source this code.  Thanks also to all the
[contributors](https://github.com/rubysolo/dentaku/graphs/contributors)!


LICENSE
-------

(The MIT License)

Copyright © 2012-2022 Solomon White

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
