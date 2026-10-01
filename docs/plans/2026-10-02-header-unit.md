# Header Units Implementation Plan

> Execute task-by-task in this session; no delegation is needed.

**Goal:** Support explicit table-header units without duplicate scaling.

**Architecture:** Extend the existing parser and its structured error path.
Preserve `unit = NULL` behavior and all quantity/range callers.

**Tech Stack:** R, existing testthat and roxygen2; no new dependency.

1. Add `tests/testthat/test-header-unit.R`; run `testthat::test_local()`
   and confirm the new tests fail on the unsupported argument.
2. Update `R/parse-cn-number.R`: validate the scalar header unit, calculate
   its multiplier, apply it only to bare values, and reject explicit conflicts.
3. Regenerate `man/parse_cn_number.Rd`, update both READMEs and NEWS.
4. Run the full suite and the real-data audit; build the package and push
   the verified changes for cross-platform CI. Do not resubmit to CRAN.
