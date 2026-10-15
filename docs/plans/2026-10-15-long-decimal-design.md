# Long decimal conversion design

Approved scope: repair representable long decimal values without slowing ordinary
inputs; test all three parsers and complete the GitHub release workflow. CRAN is
out of scope.

Reuse `convert_cn_scaled_boundary()` in `R/parse-cn-number.R`. Leave the native
fast path and ordinary R conversion unchanged. Only its already-selected extreme
inputs receive bounded significand conversion: keep 1,100 significant decimal
digits, plus a sticky nonzero digit if any discarded digit is nonzero. Continue
to account for decimal position, exponent and unit before conversion.

Why not simply keep 17 digits: a discarded tail can change rounding at an exact
binary64 midpoint. Every finite binary64 rounding boundary is a dyadic rational
whose normalized exact decimal significand fits within 1,100 digits (including
the midpoint at 2^-1075). Retaining that prefix and tail direction preserves which
side of the boundary the full decimal occupies. The bounded conversion stays
below the observed R long-significand failure; no arbitrary cell-length limit,
new dependency, public API or C backend is needed.

Alternative: replace conversion with another C library. Rejected here because it
adds locale/platform concerns and changes a larger surface than this concrete
fallback defect requires.

Validate independent known values, ties and just-above/below ties, subnormals,
overflow, zero, units, qualifiers, ranges, factors and repeated fallback inputs.
Compare pre/post functions in the same warmed R session on ordinary and fallback
datasets; report medians, not universal timing promises. Publish only after local
package checks and the existing cross-platform CI pass.
