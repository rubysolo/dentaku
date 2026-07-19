# Change Log

## [Unreleased]
BREAKING CHANGES
- unify exception metadata naming: the "required vs. received" pair is now
  `expected:` / `actual:` everywhere (previously a mix of `expect:`/`actual:`,
  `for:`/`value:`, `at_least:`/`given:`, and `exact:`/`given:`); arity
  expectations are an Integer or Range (`expected: 1..` means "at least one")
  and `actual:` always carries the offending value itself, not its class
- `meta[:operation]` is now always the AST class and `meta[:operator]` the
  method symbol (previously `ParseError` used `:operator` for the class);
  `NodeError#child` is renamed to `#operand` (it holds the failing operand's
  position, `:left` / `:right` / `:node`) and `NodeError#expect` to `#expected`;
  `function_name:` metadata carries bare names (`'AND'`, not `'AND()'`)
- `Dentaku::Error#recipient_variable` is renamed to `#assigned_to`
- bitwise operations on non-integer operands raise `:incompatible_type`
  (previously `:invalid_operator`) with a descriptive message instead of a
  bare "Dentaku::ArgumentError"

OTHER CHANGES
- `Dentaku::ArgumentError` builds default messages from reason and metadata,
  like `ParseError` and `TokenizerError`
- add `volatile:` option to `add_function` / `add_functions` / function
  registration for functions that read external state or return different
  values across calls; volatile functions are never executed during
  dependency analysis, so a conditional guarded by one reports all branches
  as dependencies (and `evaluate!` requires variables from every branch),
  and the guard is evaluated exactly once per `evaluate!` instead of twice
  (#339, thanks @d-krushinsky)
- add `Calculator#identifiers`, a purely syntactic listing of every
  identifier a formula could reference regardless of branching -- nothing
  is evaluated and stored variables are not subtracted (#197, #339)
- operand type-mismatch parse errors now read as natural English: the parser
  preserves the node-level message ("Dentaku::AST::Addition requires operands
  that are numeric or compatible types, not string") instead of rebuilding a
  misleading one ("requires incompatible operands, but got string"); the
  metadata-derived fallback message says "compatible" rather than
  "incompatible" (idea from #341, thanks @moskvin)

## [v4.0.0.pre] 2026-07-06
BREAKING CHANGES
- require Ruby 3.2 or newer
- `Calculator.new` takes keyword arguments; the AST cache must now be passed
  explicitly via `ast_cache:` instead of as leftover options, unknown options
  raise `ArgumentError`, and the passed values are no longer mutated
- `Dentaku::Error` is now a module included by all Dentaku exceptions, so
  `rescue Dentaku::Error` also catches `Dentaku::ArgumentError` and
  `Dentaku::ZeroDivisionError`; exceptions that previously subclassed
  `Dentaku::Error` now subclass `Dentaku::BaseError`
- `TokenMatcher` no longer builds function matchers via `method_missing`; use
  `TokenMatcher.function(name)` (the unused `math_neg_pow` / `math_neg_mul`
  matcher symbols were removed)
- remove Travis CI configuration
- `AND` / `OR` short-circuit: an unbound variable no longer raises when the
  bound operand already decides the result (#234); formulas are documented
  as pure, and misspelled identifiers on never-taken branches are no longer
  reported at evaluation time (use `dependencies` for static validation)
- indexing into a non-indexable value (e.g. `a[0]` where `a` is a number,
  `NULL`, or a boolean) now raises `Dentaku::ArgumentError` instead of
  silently returning a bit-reference result or leaking a raw Ruby
  `NoMethodError`; an incompatible index type (e.g. a string index into an
  array) raises `Dentaku::ArgumentError` instead of a raw `TypeError`

OTHER CHANGES
- document Ruby compatibility policy
- cache flags can be set per calculator (`cache_ast:`,
  `cache_dependency_order:`), defaulting to the module-level settings
- module-level `Dentaku.aliases` is resolved lazily, so aliases set after a
  calculator was created (including the implicit top-level calculator) apply
- `CASE` expressions only report dependencies for the branch that would be
  taken when the switch value is resolvable
- fix parsing of `CASE` statements with an unparenthesized operation as the
  switch expression (`CASE a % 5 WHEN ...`), which also makes `PrintVisitor`
  output for such statements re-parseable
- fix `recipient_variable` being nil inside `solve` blocks, a regression
  introduced in 3.5.4 (#333)
- declare `tsort` as an explicit dependency for Ruby 4.1 (#334, thanks @david942j)
- fix alias function calls with whitespace before the opening parenthesis
  (#335, thanks @DirkDoes)
- modernize low-risk Ruby syntax
- unify numeric matching and parsing
- fix frozen-string-literal warning
- `ParseError` and `TokenizerError` now build their own default messages from
  `reason` and `meta` (message text is unchanged); `Parser#fail!` and
  `Tokenizer#fail!` reduce to one-liners
- fix crashes on two error paths: the parser's unbalanced-parenthesis report
  raised a Ruby `ArgumentError` instead of a `ParseError`, and the tokenizer's
  zero-width-match report raised a `KeyError` instead of a `TokenizerError`

## [v3.5.7] 2025-12-16
- fix misclassification of unary minus as subtraction
- fix parsing empty function call

## [v3.5.6] 2025-10-20
- fix comparison of Hash with integer
- refactor case parsing
- remove input mutation
- fix bug with arithmetic node validation

## [v3.5.5] 2025-08-20
- fix percentages in print visitor
- repo cleanup
- fix modulo zero
- fix array arithmetic
- refactor parser

## [v3.5.4] 2024-08-13
- add support for default value for PLUCK function
- improve error handling for MAP/ANY/ALL functions
- fix modulo / percentage operator determination
- fix string casing bug with bulk expressions
- add explicit gem dependency for BigDecimal

## [v3.5.3] 2024-07-04
- add support for empty array literals
- add support for quoted identifiers
- add REDUCE function
- add INTERCEPT function
- improve date/time parsing an arithmetic
- improve custom class arithmetic
- fix IF dependency

## [v3.5.2] 2023-12-06
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

## [v3.5.1] 2022-10-24
- add bitwise shift left and shift right operators
- improve numeric conversions
- improve parse exceptions
- improve bitwise exceptions
- include variable name in bulk expression exceptions

## [v3.5.0] 2022-03-17
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

## [v3.4.2] 2021-07-14
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

[UNRELEASED]: https://github.com/rubysolo/dentaku/compare/v3.5.7...HEAD
[v3.5.7]: https://github.com/rubysolo/dentaku/compare/v3.5.6...v3.5.7
[v3.5.6]: https://github.com/rubysolo/dentaku/compare/v3.5.5...v3.5.6
[v3.5.5]: https://github.com/rubysolo/dentaku/compare/v3.5.4...v3.5.5
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
