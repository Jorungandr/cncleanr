# Systematic Hardening Implementation Plan

> Execute sequentially in this session; no subagents requested.

**Goal:** Resolve the approved correctness and engineering audit batches.

**Architecture:** Keep the native fast path and R fallback; share boundary
handling and existing range helpers. Do not introduce runtime dependencies.

**Tech Stack:** R, registered C, testthat, PowerShell, GitHub Actions.

## Tasks

1. Add `tests/testthat/test-systematic-hardening.R` with independent expected
   answers for incompatible units, named factor/empty input, extreme scaling,
   fractional grouping, endpoint diagnostics and separator limits. Run against
   installed 0.2.11 and record failures.
2. Repair `R/parse-cn-number.R`, `R/parse-cn-range.R` and
   `src/simple-number.c`; exercise sibling quantity/range and strict paths.
   Remove only unused private arguments and update their callers/tests.
3. Update current audit scripts to load an explicit installed package, retain
   historical benchmark provenance, document snapshot acquisition/checks, add
   a small executable release verifier and ignore local artifacts.
4. Update DESCRIPTION, NEWS, manuals, bilingual README, CONTRIBUTING and CRAN
   draft. Record floating-point/diagnostic limits and unchanged semantic choices.
5. Install into an isolated outputs library with `docs/run-r.ps1`, run all
   development tests and `tests/parser.R`, build/check the source package.
6. Review diff, commit scoped files, push, verify CI, create matching tag/release,
   install the published asset and verify it. Never claim unavailable checks ran.
