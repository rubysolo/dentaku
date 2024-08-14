# Change Log

## [v3.5.4]
- add support for default value for PLUCK function
- improve error handling for MAP/ANY/ALL functions
- fix modulo / percentage operator determination
- fix string casing bug with bulk expressions
- add explicit gem dependency for BigDecimal

## [v3.5.3]
- add support for empty array literals
- add support for quoted identifiers
- add REDUCE function
- add INTERCEPT function
- improve date/time parsing an arithmetic
- improve custom class arithmetic
- fix IF dependency

## [v3.5.2]
- add ABS function
- add array support for AST visitors
- add support for function callbacks
- improve support for date / time values
- improve error messaging for invalid arity
- improve AVG function accuracy
- validate enum arguments at parse time
- support adding multiple functions at once to global registry
- fix bug in print visitor precedence checking
- fix handling of Math::DomainError
- fix invalid cast

## [v3.5.1]
- add bitwise shift left and shift right operators
- improve numeric conversions
- improve parse exceptions
- improve bitwise exceptions
- include variable name in bulk expression exceptions

## [v3.5.0]
- fix bug with function argument count
- add XOR operator
- make function args publicly accessible
- better argument handling for collection functions
- better dependency reporting for collection functions
- allow ruby math-backed functions to be serialized
- improve scientific notation handling
- improve comparator argument errors
- respect case sensitivity in nested case statments
- add visitor pattern

## [v3.4.2]
- add FILTER function
- add concurrent-ruby dependency to make global calculator object thread safe
- add Ruby 3 support
- allow formulas to access intermediate context values
- fix incorrect Ruby Math function return type
- fix context mutation bug
- fix dependency resolution bug

## [v3.4.1] 2020-12-12
- prevent extra evaluations in bulk expression solver

## [v3.4.0] 2020-12-07
- allow access to intermediate values of flattened hashes
- catch invalid array syntax in the parse phase
- drop support for Ruby < 2.5, add support for Ruby 2.7
- add support for subtracting date literals
- improve error handling
- improve math function implementation
- add caching for calculated variable values
- allow custom unbound variable handling block at Dentaku module level
- add enum functions `ANY`, `ALL`, `MAP` and `PLUCK`
- allow self-referential formulas in bulk expression solver
- misc internal fixes and enhancements

## [v3.3.4] 2019-11-21
- bugfix release

## [v3.3.3] 2019-11-20
- date / duration addition and subtraction
- validate arity for custom functions with variable arity
- make AST serializable with Marshal.dump
- performance optimization for arithmetic node validation
- support lazy evaluation for expensive values
- short-circuit IF function
- better error when empty string is used in arithmetic operation

## [v3.3.2] 2019-06-10
- add ability to pre-load AST cache
- fix negation node bug

## [v3.3.1] 2019-03-26
- better errors for parse failures and exceptions in internal functions
- fix Ruby 2.6.0 deprecation warnings
- fix issue with functions in nested case statements

## [v3.3.0] 2018-12-04
- add array literal syntax
- return correct type from string function AST nodes

## [v3.2.1] 2018-10-24
- make `evaluate` rescue more exceptions

## [v3.2.0] 2018-03-14
- add `COUNT` and `AVG` functions
- add unicode support 😎
- fix CASE parsing bug
- allow dependency filtering based on context
- add variadic MUL function
- performance optimization

## [v3.1.0] 2018-01-10
- allow decimals with no leading zero
- nested hash and array support in bulk expression solver
- add a variadic SUM function
- support array arguments to min, max, sum, and Math functions
- add case-sensitive variable support
- allow opt-out of nested data for performance boost

## [v3.0.0] 2017-10-11
- add && and || as aliases for AND and OR
- add hexadecimal literal support
- add the SWITCH function
- add AND and OR functions
- add array access
- make UnboundVariableError show all missing values
- cast inputs to numeric function to numeric
- fix issue with zero-arity functions used as function args
- fix division when context values contain one or more strings
- drop Ruby 1.9 support

## [v2.0.11] 2017-05-08
- fix dependency checking for logical AST nodes
- make `CONCAT` variadic
- fix casting strings to numeric in negation operations
- add date/time support
- add `&` (bitwise and) and `|` (bitwise or) operators
- fix incompatibility with 'mathn' module
- add `CONTAINS` string function
- allow storage of nested hashes in calculator memory
- allow duck type arithmetic
- fix error handling code to work with Ruby 2.4.0
- allow calculators to store own registry of functions
- add timezone support to time literals
- optimizations

## [v2.0.10] 2016-12-30
- fix string function initialization bug
- fix issues with CASE statements
- allow injecting AST cache

## [v2.0.9] 2016-09-19
- namespace tokenization errors
- automatically coerce arguments to string functions as strings
- selectively disable or clear AST cache

## [v2.0.8] 2016-05-10
- numeric input validations
- fail with gem-specific error for invalid arithmetic operands
- add `LEFT`, `RIGHT`, `MID`, `LEN`, `FIND`, `SUBSTITUTE`, and `CONCAT` string functions

## [v2.0.7] 2016-02-25
- fail with gem-specific error for parsing issues
- support NULL literals and nil variables
- keep reference to variable that caused failure when bulk-solving

## [v2.0.6] 2016-01-26
- support array parameters for external functions
- support case statements
- support precision for `ROUNDUP` and `ROUNDDOWN` functions
- prevent errors from corrupting calculator memory

## [v2.0.5] 2015-09-03
- fix bug with detecting unbound nodes
- silence warnings
- allow registration of custom token scanners

## [v2.0.4] 2015-09-03
- fix BigDecimal conversion bug
- add caching for bulk expression solving dependency order
- allow for custom configuration for token scanners

## [v2.0.3] 2015-08-25
- bug fixes
- performance enhancements
- code cleanup

## [v2.0.1] 2015-08-15
- add support for boolean literals
- implement basic parse-time type checking

## [v2.0.0] 2015-08-07
- shunting-yard parser for performance enhancement and AST generation
- AST caching for performance enhancement
- support comments in formulas
- support all functions from the Ruby Math module

## [v1.2.6] 2015-05-30
- support custom error handlers for systems of formulas

## [v1.2.5] 2015-05-23
- fix memory leak

## [v1.2.2] 2014-12-19
- performance enhancements
- unary minus bug fixes
- preserve provided hash keys for systems of formulas

## [v1.2.0] 2014-10-21
- add dependency resolution to automatically solve systems of formulas

## [v1.1.0] 2014-07-30
- add strict evaluation mode to raise `UnboundVariableError` if not all variable values are provided
- return division results as `BigDecimal` values

## [v1.0.0] 2014-03-06
- cleanup and 1.0 release

## [v0.2.14] 2014-01-24
- add modulo operator
- add unary percentage operator
- support registration of custom functions at runtime

## [v0.2.10] 2012-12-10
- return integer result for exact division, decimal otherwise

## [v0.2.9] 2012-10-17
- add `ROUNDUP` / `ROUNDDOWN` functions

## [v0.2.8] 2012-09-30
- make function name matching case-insensitive

## [v0.2.7] 2012-09-26
- support passing arbitrary expressions as function arguments

## [v0.2.6] 2012-09-19
- add `NOT` function

## [v0.2.5] 2012-06-20
- add exponent operator
- add support for digits in variable identifiers

## [v0.2.4] 2012-02-29
- add support for `min < x < max` syntax for inequality ranges

## [v0.2.2] 2012-02-22
- support `ROUND` to arbitrary decimal place on older Rubies
- ensure case is preserved for string values

## [v0.2.1] 2012-02-12
- add `ROUND` function

## [v0.1.3] 2012-01-31
- add support for string datatype

## [v0.1.1] 2012-01-24
- change from square bracket to parentheses for top-level evaluation
- add `IF` function

## [v0.1.0] 2012-01-20
- initial release

[v3.5.4]: https://github.com/rubysolo/dentaku/compare/v3.5.3...v3.5.4
[v3.5.3]: https://github.com/rubysolo/dentaku/compare/v3.5.2...v3.5.3
[v3.5.2]: https://github.com/rubysolo/dentaku/compare/v3.5.1...v3.5.2
[v3.5.1]: https://github.com/rubysolo/dentaku/compare/v3.5.0...v3.5.1
[v3.5.0]:  https://github.com/rubysolo/dentaku/compare/v3.4.2...v3.5.0
[v3.4.2]:  https://github.com/rubysolo/dentaku/compare/v3.4.1...v3.4.2
[v3.4.1]:  https://github.com/rubysolo/dentaku/compare/v3.4.0...v3.4.1
[v3.4.0]:  https://github.com/rubysolo/dentaku/compare/v3.3.4...v3.4.0
[v3.3.4]:  https://github.com/rubysolo/dentaku/compare/v3.3.3...v3.3.4
[v3.3.3]:  https://github.com/rubysolo/dentaku/compare/v3.3.2...v3.3.3
[v3.3.2]:  https://github.com/rubysolo/dentaku/compare/v3.3.1...v3.3.2
[v3.3.1]:  https://github.com/rubysolo/dentaku/compare/v3.3.0...v3.3.1
[v3.3.0]:  https://github.com/rubysolo/dentaku/compare/v3.2.1...v3.3.0
[v3.2.1]:  https://github.com/rubysolo/dentaku/compare/v3.2.0...v3.2.1
[v3.2.0]:  https://github.com/rubysolo/dentaku/compare/v3.1.0...v3.2.0
[v3.1.0]:  https://github.com/rubysolo/dentaku/compare/v3.0.0...v3.1.0
[v3.0.0]:  https://github.com/rubysolo/dentaku/compare/v2.0.11...v3.0.0
[v2.0.11]:  https://github.com/rubysolo/dentaku/compare/v2.0.10...v2.0.11
[v2.0.10]:  https://github.com/rubysolo/dentaku/compare/v2.0.9...v2.0.10
[v2.0.9]:  https://github.com/rubysolo/dentaku/compare/v2.0.8...v2.0.9
[v2.0.8]:  https://github.com/rubysolo/dentaku/compare/v2.0.7...v2.0.8
[v2.0.7]:  https://github.com/rubysolo/dentaku/compare/v2.0.6...v2.0.7
[v2.0.6]:  https://github.com/rubysolo/dentaku/compare/v2.0.5...v2.0.6
[v2.0.5]:  https://github.com/rubysolo/dentaku/compare/v2.0.4...v2.0.5
[v2.0.4]:  https://github.com/rubysolo/dentaku/compare/v2.0.3...v2.0.4
[v2.0.3]:  https://github.com/rubysolo/dentaku/compare/v2.0.1...v2.0.3
[v2.0.1]:  https://github.com/rubysolo/dentaku/compare/v2.0.0...v2.0.1
[v2.0.0]:  https://github.com/rubysolo/dentaku/compare/v1.2.6...v2.0.0
[v1.2.6]:  https://github.com/rubysolo/dentaku/compare/v1.2.5...v1.2.6
[v1.2.5]:  https://github.com/rubysolo/dentaku/compare/v1.2.2...v1.2.5
[v1.2.2]:  https://github.com/rubysolo/dentaku/compare/v1.2.0...v1.2.2
[v1.2.0]:  https://github.com/rubysolo/dentaku/compare/v1.1.0...v1.2.0
[v1.1.0]:  https://github.com/rubysolo/dentaku/compare/v1.0.0...v1.1.0
[v1.0.0]:  https://github.com/rubysolo/dentaku/compare/v0.2.14...v1.0.0
[v0.2.14]: https://github.com/rubysolo/dentaku/compare/v0.2.10...v0.2.14
[v0.2.10]: https://github.com/rubysolo/dentaku/compare/v0.2.9...v0.2.10
[v0.2.9]:  https://github.com/rubysolo/dentaku/compare/v0.2.8...v0.2.9
[v0.2.8]:  https://github.com/rubysolo/dentaku/compare/v0.2.7...v0.2.8
[v0.2.7]:  https://github.com/rubysolo/dentaku/compare/v0.2.6...v0.2.7
[v0.2.6]:  https://github.com/rubysolo/dentaku/compare/v0.2.5...v0.2.6
[v0.2.5]:  https://github.com/rubysolo/dentaku/compare/v0.2.4...v0.2.5
[v0.2.4]:  https://github.com/rubysolo/dentaku/compare/v0.2.2...v0.2.4
[v0.2.2]:  https://github.com/rubysolo/dentaku/compare/v0.2.1...v0.2.2
[v0.2.1]:  https://github.com/rubysolo/dentaku/compare/v0.1.3...v0.2.1
[v0.1.3]:  https://github.com/rubysolo/dentaku/compare/v0.1.1...v0.1.3
[v0.1.1]:  https://github.com/rubysolo/dentaku/compare/v0.1.0...v0.1.1
[v0.1.0]:  https://github.com/rubysolo/dentaku/commit/68724fd9c8fa637baf7b9d5515df0caa31e226bd
