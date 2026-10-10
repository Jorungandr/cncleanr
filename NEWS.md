# Development changes (unreleased)

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
