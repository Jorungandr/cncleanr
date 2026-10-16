# Long Decimal Implementation Plan

> Execution: follow the executing-plans skill task by task in this existing
> checkout, as requested by the user; no delegated agents or additional checkout.

**Goal:** Parse long representable decimals correctly without changing ordinary
conversion or materially regressing normal-data performance.

**Architecture:** Bound only the significand in the existing extreme-value
fallback, preserving a sticky tail for binary64 rounding. All three public
parsers reuse the shared correction.

**Tech Stack:** Existing R, registered C fast path, testthat, GitHub Actions.

---

1. Add failing tests to `tests/testthat/test-systematic-hardening.R`; run against
   installed 0.2.13 to reproduce long mantissas and exact midpoint tails.
2. Update `convert_cn_scaled_boundary()` in `R/parse-cn-number.R` with a
   1,100-digit prefix and sticky tail. Validation required a private bounded C
   conversion with exact midpoint correction in `src/simple-number.c`, plus a
   constant-time length guard in the existing fast path. Run focused and full
   tests after install. Ordinary conversion semantics remain unchanged.
3. Add a reproducible same-process old/new timing and correctness script under
   `docs/`; ordinary numeric, formatted, qualified and range datasets must retain
   identical complete results. Do not impose flaky timing assertions in CI.
4. Update `DESCRIPTION`, `NEWS.md`, both READMEs and bilingual release notes for
   0.2.14. Build a clean committed-source archive and run R CMD check locally.
5. Push the fixed source, verify all existing CI jobs, tag the verified commit,
   publish the exact checked archive, download it publicly, compare SHA-256 and
   install/test the downloaded archive. Record measured results and limitations.

Commands use `docs/run-r.ps1` with explicit local R executable and task-local
compiler environment; outputs live under `outputs/long-decimal/`. Expected local
check: Status OK (no manual / incoming check locally). Linux CI checks the manual.

## Completion

Source `a172958c6384cb70d16273cfebef90150662993d` passed the local exact-archive
check, all five platform jobs (38763569044), and ASAN/UBSAN/Valgrind (38763677021):
833 assertions each. Independent Python comparison matched 1,500 long-decimal
cases. Alternating old/new performance runs and their variation are retained in
`docs/long-decimal.md`; no stable ordinary-data regression or new speedup is
claimed. GitHub 0.2.14 published after these checks; CRAN was not submitted.
The public unauthenticated asset download matched the checked SHA-256, installed
in a separate library and passed source/version, 833-assertion and base-regression
verification. Follow-up records modify excluded docs only, not the fixed tag or
its checked source archive.
