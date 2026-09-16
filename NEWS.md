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
