# Range Failure Reasons Implementation Plan

**Goal:** Preserve specific scalar failures and identify failed endpoints without
changing accepted inputs, numeric results, public arguments or default fast paths.

**Architecture:** Reuse quantity/number problem tables already produced inside
R/parse-cn-range.R. Restore specific scalar reasons only over generic range
fallback failures. Add left/right reasons only for a unique split candidate;
do not mistake an exponent minus for a range separator. Keep existing grouping,
missing-endpoint, incompatible/reversed/ambiguous-range priority. No new parsing.

**Tech Stack:** Existing R, testthat and roxygen2; C and dependencies unchanged.

User approved this diagnostic-only design on 2026-10-27. Alternatives (reparse
each failed cell, or always attach endpoint guesses) add cost or misleading
diagnostics. Reuse existing batched failures instead. Continue current checkout
without agents or separate sessions, as authorized for this project.

1. Add tests/testthat/test-range-failure-reasons.R. Confirm old 0.2.22 fails the
   new reason assertions. Include signed/exponent bounds, both endpoints, grouped
   retry, duplicates/factors, strict errors and cn_subset/cn_summary.
2. Retain quantity problem table; restore specific reasons over generic fallback.
   Within endpoint parser, format labels only in the existing failure branch for
   unique non-exponent candidates. Preserve other established reason priorities.
3. Run focused and full tests; update intentionally improved fixture reasons.
   Compare accepted results against installed 0.2.22 over generated mixed cases;
   verify parser invocation counts do not increase and benchmark default success.
4. Update version 0.2.23, NEWS, Rd, matching bilingual README and release notes.
   Push source, clean build/local no-manual check, all five CI platforms and
   README/import/system/existing-data audits. Record environment NOTE honestly.
5. Fixed GitHub tag/checked source asset, unauthenticated public download/hash,
   isolated compile/install/full tests; update bilingual install pins and push
   validation record. No CRAN submission or new native-tool claims.
