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
2. Update only `convert_cn_scaled_boundary()` in `R/parse-cn-number.R` with a
   1,100-digit prefix and sticky tail. Run focused and full tests after install.
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
