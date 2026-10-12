# Native Stability Implementation Plan

> Execution: complete this approved plan in the current session; no subagents
> or repeated ordinary-step confirmations. Use the available executing-plans skill.

**Goal:** Verify native parsing and normalization against the R reference,
fix demonstrated correctness defects, and check native memory safety.

**Architecture:** Reuse the existing parser and testthat suite. A test-only
reference environment replaces both native entry points with original R
transformations and unhandled numeric results; all parser callers and recursive
calls resolve through that environment. No new public API or runtime dependency.

**Tech Stack:** R, registered C routines, testthat, existing GitHub/R-hub workflows.

## Approved scope

Fixed-seed valid/invalid differential tests for all three parsers, complete
diagnostics and strict errors; long/short strings, numeric boundaries, encodings,
empty inputs and native argument validation. Use existing R-hub clang-ASAN,
clang-UBSAN and valgrind configurations rather than writing a custom checker.
No performance tuning, new syntax, or CRAN submission. Publish a new version
only if a runtime fix is needed; otherwise commit testing/documentation updates.

## Tasks

1. Inspect native routines, every caller and existing tests. Add a test-only
   independent R reference and fixed-seed corpus in
   `tests/testthat/test-native-stability.R`. Run through `docs/run-r.ps1` against
   the current installed package; record any failing cases before fixing.
2. Reproduce each mismatch with a minimal regression, fix its common root in
   `src/simple-number.c` or the shared R parser, and rerun focused/full tests.
   Check result attributes, warning/strict messages, names and negative zero.
3. Commit tests/fixes and dispatch `.github/workflows/rhub.yaml` with
   `config=clang-asan,clang-ubsan,valgrind`. Verify actual check logs, not just
   workflow completion; preserve diagnostics if external checks fail.
4. Run final isolated `R CMD build`/`R CMD check`, five normal CI jobs and
   retained correctness audits. Record reproducible results and limitations in
   `docs/native-stability.md`; update both READMEs with verified facts only.
5. If fixes require a version bump, update DESCRIPTION/NEWS and bilingual
   release notes, verify final source bundle and fixed commit, publish GitHub
   tag/source asset, then download, hash-check and independently install it.
   Otherwise push the verified maintenance commit without a new release.

## Acceptance

No unexplained native/reference differences on tested inputs; full local and
cross-platform tests pass; native checker results inspected and documented.
No moving existing release tags, no loss of source rows or diagnostic detail,
no edits to user-owned `.vscode/` or historical `outputs/`.

Completed: the demonstrated UTF-8 fix was released as GitHub v0.2.9; full
validation and publication evidence is recorded in `docs/native-stability.md`.
