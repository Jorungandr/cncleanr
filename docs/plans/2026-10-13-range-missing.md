# Range Missing-Marker Implementation Plan

**Goal:** Preserve configured endpoint missing markers when shared suffixes are
propagated, as approved by the maintainer; complete the GitHub workflow in one pass.

**Architecture:** Reuse the shared suffix helper for both ordinary and grouped
range paths. Compare character-normalized original endpoints with normalized
markers before appending units; restore marked endpoints as NA afterward.
Keep existing post-propagation marker checks, full-cell missing precedence,
numeric parsing, original diagnostics and the public API. No C changes.

**Tech Stack:** R, existing testthat suite, registered normalization, GitHub CI.

1. Add `tests/testthat/test-range-missing.R`; demonstrate failures on installed
   0.2.10 for numeric, percent, signed/scientific and grouped endpoints.
2. Forward markers to the shared helper, preserve original missing endpoints,
   and run focused/full tests, retained data audits and batch/CSV checks.
3. Update DESCRIPTION/NEWS, bilingual README and generated range help for
   0.2.11. Build/check the exact clean source archive and record its hash.
4. Verify five CI jobs at a fixed commit; publish tag/source asset with bilingual
   notes, then download/hash-check/install the public asset and rerun regressions.
5. Push excluded publication records without moving existing tags. No CRAN
   submission, new syntax, runtime dependency or performance tuning.

Completed as GitHub v0.2.11. Exact-archive checks and five platform CI jobs
passed 592 assertions; public download/hash/install verification and 53 focused
regressions passed. Evidence: `docs/range-missing.md`.
