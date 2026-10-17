# Numeric Conversion Consistency Implementation Plan

> Execute with the executing-plans skill in this existing checkout; the user
> approved the design and end-to-end GitHub workflow. No delegated agents.

**Goal:** Respect numeric S3 conversion before applying a table-header unit.

**Architecture:** Reuse the existing `as.double()` conversion at entry to the
numeric branch of `parse_cn_number()`. Both unit/no-unit paths consume that same
plain double vector; retain original names and use converted missingness. No
change to quantity/range parsing, C sources, numeric syntax or new dependency.

**Tech Stack:** R, existing testthat regressions, GitHub Actions.

---

Approved design: prefer a shared base-R conversion over rejecting classed
numeric input. The latter would unnecessarily remove behavior already supported
without a header and by quantity/range parsers. Test with a minimal numeric S3
object whose storage and converted value differ; no external package is needed.

1. Add a failing regression to `tests/testthat/test-header-unit.R`: converted
   30,000 must become 300,000,000 under unit 万, rather than the storage-derived
   value. Cover names, empty input, NA/NaN/Inf, strict diagnostics, conversion
   count, ordinary integer/double values and quantity/range consistency.
2. In `R/parse-cn-number.R`, convert once before either numeric branch and use
   that result for missing detection and `sprintf`. Update roxygen/Rd wording.
3. Install and run focused/full tests. Compare old/new header-unit timings on
   100,000 integers/doubles with exact output equality; no flaky timing gates.
4. Update version to 0.2.15, NEWS and bilingual README/release notes. Build a
   clean committed-source archive, check locally and run all five platform jobs.
5. Tag the verified source, publish the exact checked archive, download it
   publicly without authentication, compare SHA-256, install and rerun tests.
   Record evidence in docs; do not submit CRAN or modify existing release assets.

## Completed

- Source: `993fb773fac1f82df3b270fd1db13bacee03404b`; only the numeric entry branch
  changed, with no C changes or new dependencies. Added 25 assertions, total 858.
- Both local exact-archive checks and all five platform jobs (39021796845) passed;
  the local repository-index timeout and offline rerun limits are recorded in
  `docs/numeric-conversion.md`, along with ordinary-input timing medians.
- Published v0.2.15 at the fixed annotated tag. The public unauthenticated asset
  download matched the checked SHA-256 and passed isolated install, source/version,
  all 858 assertions and dependency-free regression. No CRAN submission.
