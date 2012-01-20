Dentaku
=======

http://github.com/rubysolo/dentaku

DESCRIPTION
-----------

Dentaku is a parser and evaluator for a mathematical and logical formula
language that allows run-time binding of values to variables referenced in the
formulas.

EXAMPLE
-------

This is probably simplest to illustrate in code:

    calculator = Dentaku::Calculator.new
    calculator.evaluate('10 * 2')
    => 20

Okay, not terribly exciting.  But what if you want to have a reference to a
variable, and evaluate it at run-time?  Here's how that would look:

    calculator.evaluate('kiwi + 5', :kiwi => 2)
    => 7

You can also store the variable values in the calculator's memory and then
evaluate expressions against those stored values:

    calculator.store(:peaches => 15)
    calculator.evaluate('peaches - 5')
    => 10
    calculator.evaluate('peaches >= 15')
    => true

For maximum CS geekery, `bind` is an alias of `store`.

If you're too lazy to be building calculator objects, there's a module-method
shortcut just for you:

    Dentaku['plums * 1.5', {:plums => 2}]
    => 3.0


SUPPORTED OPERATORS
-------------------

Math: `+ - * /`
Logic: `< > <= >= <> != = AND OR`

THANKS
------

Big thanks to [ElkStone Basements](http://www.elkstonebasements.com/) for
allowing me to extract and open source this code.

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

