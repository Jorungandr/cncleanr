# cncleanr 0.2.15

* Converts numeric input with `as.double()` once before header-unit scaling and
  missing-value detection. Numeric S3 conversion methods are now respected with
  a header just as they already were without a header and in quantity/range
  parsing. Original names and established nonfinite-value policies are retained.
* Adds dependency-free S3 regressions for converted values/missingness, all header
  units, single conversion, names, negative zero and strict diagnostics. No new
  API, runtime dependency or C change.

# cncleanr 0.2.14

* Rescues representable very long decimal significands in the shared extreme
  conversion fallback. A bounded decimal prefix and sticky tail retain rounding
  direction; exact binary64 midpoint comparisons correct platform conversion
  candidates, including subnormal and overflow boundaries.
* Ordinary conversion semantics are unchanged; the native parser only adds a
  constant-time length guard to defer long bodies. No new public
  arguments or runtime dependencies are introduced. Adds independent rounding
  regressions and a same-process old/new performance comparison.
* Includes the documented chunked-cleaning example and workflow regressions
  previously added on main after 0.2.13.

# cncleanr 0.2.13

* Adds `cn_subset()` for explicit filtering/reordering of parser results, including
  duplicated selections and chained subsets. Problems are remapped to selected
  positions without adding result classes or repeating parse warnings.
* Rejects missing, fractional, nonfinite and out-of-range selections; logical
  selections must have exactly the original result length/row count.
* Encoding failures identify the originating argument (`x` or `na`) and first
  original position, including fallback/deduplicated paths and factors. Native
  validation is reused only on failure; malformed text still stops the batch.
* Adds focused regressions, a CI-executable example and bilingual usage guidance.
  Existing ordinary diagnostics, return types, numeric pass-through and C sources
  remain unchanged. Ordinary `[]` and arbitrary mutations still do not track problems.

# cncleanr 0.2.12

* Rejects ranges mixing percentage and non-percentage endpoints while retaining
  shared suffixes and compatible magnitude units. Corrects grouped-endpoint
  diagnostics without changing existing reason spellings.
* Preserves named factor and named empty-vector results. Rejects fractional
  digit grouping consistently with or without a leading zero.
* Rescues representable extreme numbers by applying their decimal scale before
  boundary conversion. Nonzero values that finally round to zero now report
  `nonzero value underflows the double range` rather than silently becoming zero.
  Ordinary conversions and numeric pass-through are unchanged.
* Bounds range candidate expansion for malformed separator floods. Adds
  independent known-answer regressions alongside native/R differential checks.
* Current data audits require the checkout's installed version; adds snapshot
  hash and release archive verification, bilingual usage limits, portable local
  R launcher discovery and HTML validation tooling in Linux CI.

# cncleanr 0.2.11

* Preserves original range endpoint missing markers before shared-unit
  propagation. Configured markers such as `0` can no longer become valid
  endpoints by receiving a magnitude or percentage suffix. Existing checks
  after propagation and whole-cell missing precedence are retained.
* Adds regression coverage for normalized, signed/scientific, grouped and
  repeated endpoints, textual marker matching, factor inputs and strict errors.
  Public APIs, numeric pass-through and native C sources are unchanged.

# cncleanr 0.2.10

* Fixes closed ranges with valid whitespace-grouped endpoints being rejected
  by whole-string grouping validation. Each endpoint now retains its original
  digit spacing during validation, including shared units and scientific signs.
  Malformed groups remain invalid, and reversed grouped bounds report the
  existing reversed-range reason. Number/quantity syntax is unchanged.
* Adds known-answer regressions for grouping/separator variants, spaced units,
  duplicate/factor inputs, missing whole cells and complete original diagnostics.

# cncleanr 0.2.9

* Rejects malformed UTF-8 in shared native normalization, including truncated
  sequences, overlong encodings, surrogate code points and values above U+10FFFF.
  All three parsers now fail explicitly instead of passing malformed bytes to
  downstream text operations. Valid UTF-8 and Latin-1 conversion are unchanged.
* Adds fixed-seed native/R differential tests for complete results, diagnostics,
  warnings and strict errors, plus short/long strings and native argument checks.

# cncleanr 0.2.8

## User-facing summary

* Keeps the existing R API, supported syntax and complete structured diagnostics.
  Native routines accelerate numeric parsing and character normalization;
  unsupported numeric formats retain the complete R fallback.
* Improves mixed and repeated batches, qualifier matching, and closed-range
  processing without discarding source rows or changing strict error precedence.
  Performance varies by input format and repetition; no universal latency target
  is promised. See `docs/performance-final.md` for reproducible measurements.
* Source installation now requires a compatible C compiler and build tools.
  Windows users need matching Rtools; macOS and Linux users need their platform's
  R-compatible toolchain. No additional runtime R dependency is introduced.
* The parser-source checkpoint `2d97758` passed five cross-platform CI jobs with
  339 assertions each. Linux R-release also passed PDF manual generation; its
  only NOTE was skipped HTML validation because `tidy` was unavailable.

## Development history

* Closes the current performance-tuning round with conditional deduplication of
  large repeated numeric fallback batches and reduced grouping-regex backtracking.
  Complete diagnostics, original indices, names and strict errors are retained.
  Benchmarks cover distinct/repeated inputs across all three parsers.

* Batches single-separator range splitting and shared-suffix propagation, stores
  endpoint results in a matrix, and counts valid candidates without per-source
  lists. Signed/scientific multi-separator cases retain complete validation.

* Filters number-syntax failures before extracting captures and converting
  numeric fields. Syntax, grouping and validation errors retain complete
  original-order diagnostics, including entirely invalid batches.

* Handles ASCII bytes directly during native normalization and reuses unchanged
  ASCII/UTF-8 string objects instead of rebuilding them. Other encodings still
  receive UTF-8 conversion; grouping checks and diagnostics are unchanged.

* Removes supported whitespace in the existing native normalization scan,
  avoiding a separate regex replacement. Digit-grouping validation still runs
  before whitespace removal, preserving diagnostics and missing-marker rules.

* Normalizes full-width characters and PDF minus signs in a shared native pass
  for numbers, quantities and ranges. Preserves names and missing values;
  retains whitespace-grouping validation in R.

* Reuses normalized missing markers across native and fallback number parsing,
  avoiding duplicate normalization without changing missing-value precedence.

* Excludes known digit-grouping failures from capture extraction and numeric
  conversion. Grouping and syntax failures merge in original source order;
  all-grouping-error batches retain their original diagnostics.

* Skips native retries for unchanged text, missing markers and invalid digit
  grouping. Known grouping failures avoid full syntax matching while retaining
  the original text, source indices and error precedence.

* Accelerates existing currency prefixes and accounting parentheses in the
  conservative C path. Normalized unresolved cells retry native parsing after
  missing-marker and digit-spacing checks; original R errors remain unchanged.

* Retains native results in mixed numeric batches and runs the complete R parser
  only on unresolved rows, preserving original problem indices, missing-value
  precedence, names and strict errors.

* Expands native-parser regression checks at floating-point overflow, underflow,
  subnormal and signed-zero boundaries, comparing accepted values with the full
  R fallback across supported header units.

* Adds a local Windows R launcher that supplies a missing architecture environment
  variable to avoid the cli 3.6.6 shutdown crash, preserves native exit codes,
  and restores the calling environment. Parsing behavior is unchanged.

* Matches qualifier groups once and reuses captured lengths for stripping.
  Character normalization is shared with digit-spacing validation, and grouping
  checks only inspect inputs that actually contain spaces between digits.

* Adds a registered C fast path for completely supported simple-number batches.
  Unsupported formats retain the complete R parser and its structured errors.
  Source installations now require a C compiler; the public R API is unchanged.

* Extracts numeric captures and validates/converts them in batches, avoiding
  per-value match lists and conversions while preserving first-error precedence.

* Deduplicates original quantity text and batches qualifier matching, restoring
  every source row and its structured parsing problems after processing.

* Fills range output columns in batches rather than repeatedly updating
  data-frame rows. Parsing rules and structured problems are unchanged.
* Preallocates range separator candidates and groups valid candidates by
  source input instead of repeatedly scanning the complete candidate vector.

# cncleanr 0.2.7

* Accepts one approximation prefix combined with the suffix meaning
  "approximately", retaining `approx`. Mixed inequalities and repeated
  prefixes or suffixes remain invalid.

# cncleanr 0.2.6

* Adds an explicit `unit` argument to `parse_cn_number()` for table-header
  units. Bare values inherit the unit; matching explicit units are not scaled
  twice, and conflicting units or percentages are reported as problems.
* Supports thousand-yuan amounts (`千元`), including shared range suffixes.
* Recognizes the shorthand qualifier `超` as greater than the stated value.
* Reports qualifiers without a valid quantity instead of treating them as
  missing values after stripping the qualifier.
* Adds reproducible real-data validation using the MIT-licensed CFQA dataset.

# cncleanr 0.2.5

* Rejects malformed whitespace grouping consistently in quantity and range
  parsing instead of silently joining separated digits.
* Reports missing range endpoints such as `3-NA` and `NA-3` as structured
  parsing problems instead of raising a base R error.
* Batches and deduplicates range parsing work, substantially improving
  performance for repeated and distinct inputs without adding native code.
* Improves CRAN metadata, license discovery, installation documentation, and
  continuous integration coverage for PDF manual generation.

# cncleanr 0.2.4

* Documents numeric pass-through behavior for finite values, infinities,
  `NA`, and `NaN` across all three parsers.
* Runs the complete testthat suite through the standard `R CMD check` entry
  point, with 108 tests covering parser behavior and failure reporting.
* Adds package spelling checks, CRAN submission records, contributor guidance,
  and structured bug-report and feature-request forms.
* Checks release candidates on R-devel, R-release, and R-oldrel-1 across Linux,
  macOS, and Windows.

# cncleanr 0.2.3

* Expands continuous integration to R devel, release, and oldrel-1 across a
  five-job operating-system and R-version matrix.
* Adds auditable UTF-8 fixtures based on representative PDF, spreadsheet, and
  web inputs.
* Adds cross-parser invariants for output shape, failure visibility, strict
  mode consistency, and finite successful values.
* Marks qualifiers as missing when a qualified quantity cannot be parsed.
* Adds matching Chinese and English end-to-end cleaning examples, return-value
  references, qualifier semantics, and troubleshooting guidance.

# cncleanr 0.2.2

* Normalizes common PDF minus characters and full-width exponent letters.
* Supports regular, non-breaking, narrow no-break, and ideographic spaces in
  valid three-digit number grouping.
* Rejects malformed whitespace grouping instead of silently concatenating
  digits.
* Supports `余` before magnitude and currency suffixes, including `50余万`,
  `50余元`, and `50余万元`.
* Expands regression coverage for copied PDF, spreadsheet, and web text.

# cncleanr 0.2.1

* Fixes `parse_cn_range()` so minus signs in scientific notation and negative
  endpoints are not mistaken for range separators.
* Supports strict and inclusive inequality phrases including `大于`, `小于`,
  `不大于`, and `不小于`, plus comparison symbols.
* Interprets a trailing `+` as `at_least` and `余` as `greater_than`.
* Adds the first concrete failure reason to batch warnings and strict errors.
* Expands regression coverage for exact values, bounds, and signed ranges.

# cncleanr 0.2.0

* Adds `parse_cn_quantity()` to retain approximate and inequality semantics.
* Adds `parse_cn_range()` for closed ranges and open-ended bounds.
* Adds `cn_problems()` for stable access to structured parsing failures.
* Supports currency prefixes and suffixes, colloquial currency units, and
  scientific notation in `parse_cn_number()`.
* Provides separate Chinese and English README files.

# cncleanr 0.1.0

* Adds `parse_cn_number()` for compact Chinese numeric values.
* Supports `万`, `亿`, and `万亿` suffixes, percentages, full-width input,
  financial negatives, and configurable missing-value markers.
* Reports invalid values through warnings and a structured `problems`
  attribute, with an optional strict error mode.
