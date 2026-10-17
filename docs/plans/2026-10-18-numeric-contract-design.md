# Numeric conversion contract

Approved design: all three parsers reject malformed S3 `as.double()` results
instead of silently changing row counts or returning nonnumeric values. A shared
conversion function requires a plain double vector, no dimensions, with the same
length as the input. Preserve valid conversion methods, names and warnings.
Reuse it for SPSS numeric preparation as well. Ordinary numeric vectors retain
their existing conversion path and receive no element-wise validation scan.

Alternatives: duplicate guards at every caller (drifts over time), or silently
repair malformed output (cannot infer lost rows or intended values). Neither is
safe. No C, dependencies or public parameter changes. No CRAN submission.
