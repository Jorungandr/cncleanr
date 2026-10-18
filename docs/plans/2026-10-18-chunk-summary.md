# Chunked summary implementation plan

Approved design: demonstrate incremental `cn_summary()` accumulation in the
existing cleaning example. Keep only double count totals and a named numeric
reason-frequency vector between batches. Preserve first occurrence order with
`setdiff()` and ordinary named indexing; no API/dependency/parser/C changes.

1. Extend existing workflow regressions to expect mixed, empty, missing-only,
   failed-only, reordered/repeated and numeric-nonfinite summary scenarios from
   the same executable example. Run against the current example to show failure.
2. Add a local example-only accumulator; discard each report after accumulating.
   Compare each scenario against whole-input `cn_summary()` in the example's
   validation code, not inside the production accumulator. Do not imply the
   entire existing demonstration streams disk data or has constant memory.
3. Update Chinese/English workflow guides and README links. State double counts
   are exact only through 2^53, per-row details are not retained, and overlapping
   batches count occurrences rather than unique source rows. No manual `gc()`.
4. Build from clean committed source, run local package check and all five CI
   jobs; rerun literal README and imported-type/system audits. Record evidence.
   This example/test update stays on main at 0.2.19; do not replace existing
   tag/assets or upload CRAN. New example changes ship with a future release.

Alternatives: retain all batch summaries then bind (memory grows with batches),
or introduce another public merge API (not needed). Use existing base R tools.
Execution stays in the authorized checkout, without delegated agents.
