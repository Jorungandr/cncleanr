# Numeric conversion contract implementation plan

**Goal:** Reject malformed numeric S3 conversions consistently.
**Architecture:** One checked conversion helper used by all parser numeric
branches and numeric SPSS preparation; existing ordinary conversions remain.
**Tech stack:** base R, existing testthat, existing GitHub CI/release tools.

1. Add `tests/testthat/test-numeric-contract.R`: short/long/empty, wrong storage,
   dimensions and retained class; all parsers, header and SPSS paths. Register
   one task-specific S3 method and restore its registration on exit. Confirm
   failure against the installed 0.2.17 before editing production code.
2. Add `cn_numeric_values()` beside `prepare_cn_parse_input()` in
   `R/parse-cn-quantity.R`, checking `is.double`, `is.object`, `dim`, length
   after one `as.double` call. Route the four numeric conversion sites through it.
   Run focused tests, real optional-type audit and complete suite.
3. Update DESCRIPTION, NEWS, bilingual README/Rd and release notes to 0.2.18.
   Compare ordinary-input paired timing with installed 0.2.17; no C changes.
4. Build clean committed source, run local R CMD check and all five CI jobs.
   Publish the fixed tag/checked archive, publicly download, compare SHA256,
   install into isolated library and repeat tests and release verification.
5. Commit validation evidence; verify remote main and a clean working tree.

Execution is in the existing authorized checkout, without subagents. This
continues the user's requested single-session workflow, not a new session.

## Completion

Source commit `83fb6069d2c5b0cba078eb44d6340d3f4125485d` published as v0.2.18.
Local source check and all five CI jobs passed 1,181 assertions. Regression timing,
real third-party and data audits, public download/install evidence and limitations
are recorded in [numeric-contract.md](../numeric-contract.md). No CRAN submission.
