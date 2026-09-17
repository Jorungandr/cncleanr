# CRAN Readiness and Project Quality Design

## Goal

Bring cncleanr to a CRAN-ready, contributor-friendly state without expanding
the parser API, publishing a new release, submitting to CRAN, or adding a
third-party hosted service.

## Scope

The work covers six related areas:

1. standard R package test discovery;
2. explicit numeric pass-through behavior;
3. source-package documentation integrity;
4. CRAN submission records and checks;
5. lightweight contributor support;
6. quality-tool verification.

The package remains at development version `0.2.3.9000`. A future, separately
approved release may become `0.2.4` after all checks pass.

## Testing architecture

Add the conventional `tests/testthat.R` entry point so `R CMD check`, CRAN, and
local package checks execute the complete testthat suite automatically. Keep
the dependency-free `tests/parser.R` as a second, lightweight safety net.

Once the standard entry point exists, remove the custom GitHub Actions step
that directly calls `testthat::test_dir()`. The existing five-job
`check-r-package` matrix will then exercise both test suites through the same
path CRAN uses, avoiding duplicate execution.

Add regression tests for numeric inputs. Finite numeric values, `Inf`, and
`-Inf` pass through unchanged. `NaN` retains normal R numeric semantics.
Qualified numeric values receive `exact` except missing values; numeric ranges
remain point ranges. Parser-generated infinite range bounds continue to mean an
open-ended interval.

## Documentation and source package

Document numeric pass-through behavior in roxygen comments and regenerate Rd
files. Add concise matching explanations to both READMEs.

`README_EN.md` remains excluded from the CRAN source tarball to avoid a
non-standard top-level-file NOTE. Change the language switch in `README.md` to
an absolute GitHub URL so it remains valid inside the built source package.

Create `cran-comments.md` with the standard test environments, check summary,
and first-submission explanation. Add it to `.Rbuildignore`; it is a submission
record, not installed package content.

## Spelling quality

Use the standard R `spelling` workflow for English package documentation. Add
`Language: en-US`, add `spelling` to `Suggests`, and create `inst/WORDLIST` only
for legitimate project-specific tokens that the checker cannot recognize.
Avoid suppressing ordinary misspellings through an oversized word list.

Spelling is a development check, not a runtime dependency.

## Contributor support

Add `CONTRIBUTING.md` with the local setup, test commands, documentation
generation rule, issue expectations, pull-request scope, and release boundary.
Exclude it from the CRAN source package because it is repository process
documentation.

Add GitHub issue forms for reproducible bug reports and focused feature
requests, plus a configuration file that directs general questions to GitHub
Discussions only if Discussions is already enabled; otherwise keep questions
in Issues. These files are already excluded from source builds through the
existing `.github` rule.

Do not add a Code of Conduct, citation metadata, pkgdown site, Codecov, or other
external service in this iteration. Each introduces policy, identity, or
maintenance decisions beyond CRAN readiness.

## Error handling and compatibility

No parsing behavior changes. The existing warnings, strict-mode errors, and
structured `cn_problems()` records remain unchanged. Documentation must not
claim that all numeric values are finite because numeric pass-through
intentionally preserves R's `Inf`, `-Inf`, and `NaN` values.

## Verification

Verification will include:

- focused tests for numeric pass-through;
- the complete standard `R CMD check` path, confirming both `parser.R` and
  `testthat.R` execute;
- all five GitHub Actions matrix jobs;
- `urlchecker::url_check()`;
- `spelling::spell_check_package()`;
- `lintr::lint_package()`, treating existing regex and Unicode line-length
  findings as non-blocking unless edited lines add avoidable violations;
- source archive inspection for excluded repository-only files;
- `R CMD check --as-cran`, separating genuine package findings from transient
  network URL failures and the expected first-submission NOTE;
- a coverage report if `covr` can be installed cleanly, without adding a hosted
  coverage service.

## Non-goals

- No new parser syntax.
- No breaking API change.
- No CRAN upload or email confirmation.
- No `v0.2.4` tag or GitHub Release.
- No modification of unrelated local files such as `.vscode/`.
