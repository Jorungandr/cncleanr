# Explicit header units

Approved scope: add `unit = NULL` after `strict` in `parse_cn_number()`.
Keep existing callers and default behavior unchanged. Apply a single supported
header unit to bare values; accept matching explicit units without rescaling;
report incompatible explicit units or percentages through existing problems.
Use the existing parser rather than a wrapper that concatenates suffixes
(which would hide conflicts). Do not infer headers or read spreadsheets.

Supported units: 元, 千元, 万, 万元, 亿, 亿元, 万亿, 万亿元.
Numeric input with an explicit unit is parsed like character input; missing
numeric values remain missing and non-finite numbers are reported as problems.
Validate arguments even for empty vectors. Test conflicts, overflow, missing
values, names, factors, and unchanged positional calls; document both languages.
