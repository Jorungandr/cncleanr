# Combined correctness audit — 2026-10-29

Baseline: public/installed v0.2.23. Scope: all six public functions, shared input
validation, number/quantity/compound/range paths, diagnostic selection/summary,
and native conversion source. Findings are counted by root cause, not failing
examples, and do not imply an exhaustive proof over all R objects or strings.

## Defect inventory: three confirmed families

| ID | Root cause | Reproduction on 0.2.23 | Repair |
|---|---|---|---|
| B1 | Accounting suffix detection/insertion | `(3万)-5万` and `(3)-5万` rejected | Recognize inner suffixes; insert inferred units before closing parenthesis |
| B2 | Dimensioned inputs bypass vector contract | A 2x2 numeric/character matrix silently becomes four values in all three parsers | Reject dimensioned x/na; request explicit column selection |
| B3 | Summary result-integrity checks incomplete | Reversed bounds or qualifier `nonsense` counted as successful | Validate qualifier/missingness and bounds/inclusivity in explicit summary only |

This is **one parsing defect plus two validation gaps**, not three separate
algorithm failures. B1 was already identified; B2/B3 were additional findings.
The batch also resolves the previously deferred accounting inheritance policy:
`(3万)-5` now means -30000 to 50000 rather than -30000 to 5. The historical
system-audit note deliberately left that semantic choice open; it is not counted
as a fourth defect or silently retroactively relabelled as an old bug.

## Audit / repair / re-audit

1. Read current R parsers, compound conversion, diagnostics/subsetting/summary
   and native code. Excluded documented unsupported grammar, precision limits,
   and unprovable provenance after ordinary R transformations from defect counts.
2. Reproduced all three families against the installed released package. Added
   regression tests before production edits; failures confirmed the gaps.
3. Fixed the shared root paths with no new public functions, parameters,
   dependencies or C changes. Existing units-object rejection and numeric
   conversion contracts stay intact. No extra summary scan inside parsers or
   cn_subset; no per-cell repair/reparsing layer.
4. Independent accounting interval oracle covers 8748 signed/unit/separator
   combinations. The baseline disagreed with 1728 cases under the new unified
   accounting policy (not 1728 distinct defects). The repaired code matches the
   complete oracle, including reversed/dimension-conflicting rejections.
5. Expanded tests after the first repair: grouped Unicode whitespace, currency,
   full-width wrappers, missing markers before/after inference, invalid signs,
   nested wrappers, compounds, vector shape and summary integrity. These passed;
   no fourth root cause was reproduced in this bounded second pass.
6. A separate arithmetic oracle checks 7392 scalar/parser combinations across
   magnitudes, signs, currency, accounting, percentages and six qualifier forms,
   plus summary/subset counts. These are permanent regressions in
   tests/testthat/test-batch-hardening.R, not only temporary audit scripts.

## Compatibility and limits

* Valid non-accounting vector behavior and six API names remain unchanged.
* Accounting inheritance is explicitly unified as above; explicit mixed scales
  remain distinct, percentages/currency conflicts reject, compound ambiguity
  still rejects. Original textual missing markers are not resurrected.
* Matrices/arrays must be reduced explicitly (for example `x[, 1]`); shaped
  missing markers must be supplied as an intentional character vector.
* Mutated invalid result frames can now error in cn_summary. Valid native parser
  results, numeric infinities/NaNs and textual open bounds remain supported.
* Plain R objects cannot establish provenance; arbitrary stale metadata after
  transformations is still not fully detectable. No promise of zero possible
  remaining defects. No new native sanitizer result or fresh data-source claim.

Release/package/platform evidence is appended after final verification. No CRAN.
