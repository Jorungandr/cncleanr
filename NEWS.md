# cncleanr 0.1.0

* Adds `parse_cn_number()` for compact Chinese numeric values.
* Supports `万`, `亿`, and `万亿` suffixes, percentages, full-width input,
  financial negatives, and configurable missing-value markers.
* Reports invalid values through warnings and a structured `problems`
  attribute, with an optional strict error mode.
