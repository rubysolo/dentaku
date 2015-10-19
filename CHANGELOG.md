# Change Log

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
