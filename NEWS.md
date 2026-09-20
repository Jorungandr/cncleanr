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
