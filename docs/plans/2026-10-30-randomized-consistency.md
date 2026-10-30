# Randomized consistency implementation plan

**Goal:** Add reproducible independent arithmetic and diagnostic workflow tests.

**Architecture:** Fixed seeds generate bounded decimal coefficients and supported
format variants. Expectations come from coefficient arithmetic and explicit
qualifier tables, never another cncleanr parser. A second comparison disables
the native number shortcut and compares complete outputs and diagnostics.
No new public API, dependency or successful-path runtime work is planned.

**Tech stack:** R, testthat, existing registered C routines and release tooling.

1. Add tests/testthat/test-randomized-consistency.R: independent scalar,
   qualified quantity, ordered accounting interval and subset/summary oracles.
2. Compare native-enabled and R-only number parsing on mixed valid/invalid,
   full-width, missing, boundary and header-unit batches. Restore RNG state.
3. Reproduce any discrepancy separately; change production logic only for a
   confirmed supported-behavior defect, with a minimal permanent regression.
4. Run focused and complete tests, clean-source package check and README checks.
5. Record actual case/assertion counts and limitations in a bilingual report.
   Complete GitHub publication and public artifact verification for the tested
   release; do not submit CRAN or imply new sanitizer results.

User approved this scope on 2026-10-30. Existing six functions and performance
policy remain unchanged. Finite randomized tests cannot establish zero defects.
