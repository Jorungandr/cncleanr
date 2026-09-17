# CRAN Readiness and Project Quality Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make cncleanr conventionally testable by CRAN, document its complete existing behavior, add submission records and lightweight contributor support, and verify the source package without publishing or submitting it.

**Architecture:** Route all package checks through the standard `tests/testthat.R` entry point while retaining the dependency-free smoke test. Keep repository-only process files out of the source tarball, document numeric pass-through without changing behavior, and use established R quality tools for spelling, URLs, lint, coverage, and CRAN checks.

**Tech Stack:** Base R, testthat 3, roxygen2, spelling, urlchecker, lintr, covr, GitHub Actions, R CMD build/check.

---

### Task 1: Connect the complete tests to R CMD check

**Files:**
- Create: `tests/testthat.R`
- Modify: `.github/workflows/R-CMD-check.yaml`

**Step 1: Add the standard testthat entry point**

Create `tests/testthat.R` containing:

```r
library(testthat)
library(cncleanr)

test_check("cncleanr")
```

**Step 2: Run R CMD check and confirm the new path**

Build the package in a unique temporary directory, run `R CMD check
--no-manual`, and inspect `00check.log`.

Expected: the log lists both `parser.R` and `testthat.R`; all tests pass.

**Step 3: Remove the duplicate CI invocation**

Delete the `Run extended testthat suite` step from
`.github/workflows/R-CMD-check.yaml`. Keep the five-job matrix and
`check-r-package@v2 --as-cran`, which now runs both test files itself.

**Step 4: Commit**

```powershell
git add tests/testthat.R .github/workflows/R-CMD-check.yaml
git commit -m "test: run full suite through R CMD check"
```

### Task 2: Lock and document numeric pass-through

**Files:**
- Modify: `tests/testthat/test-parse-cn-number.R`
- Modify: `tests/testthat/test-parse-cn-quantity.R`
- Modify: `tests/testthat/test-parse-cn-range.R`
- Modify: `R/parse-cn-number.R`
- Modify: `R/parse-cn-quantity.R`
- Modify: `R/parse-cn-range.R`
- Modify: `README.md`
- Modify: `README_EN.md`
- Regenerate: `man/parse_cn_number.Rd`
- Regenerate: `man/parse_cn_quantity.Rd`
- Regenerate: `man/parse_cn_range.Rd`

**Step 1: Add numeric behavior tests**

Add tests asserting:

```r
numeric_input <- c(finite = 3, positive = Inf, negative = -Inf, missing = NA, nan = NaN)

expect_identical(parse_cn_number(numeric_input), as.double(numeric_input))
```

For `parse_cn_quantity()`, assert finite and infinite values have qualifier
`exact`, while `NA` and `NaN` have a missing qualifier. For
`parse_cn_range()`, assert values become inclusive point ranges and `NA`/`NaN`
rows retain missing inclusivity. Check names or row names only where the public
documentation promises them.

**Step 2: Run focused tests**

Run:

```powershell
& 'D:\R\R-4.6.1\bin\R.exe' --vanilla -q -e "devtools::test(filter = 'parse-cn-(number|quantity|range)')"
```

Expected: all existing and new tests pass without changing implementation.

**Step 3: Document numeric input semantics**

Clarify in roxygen documentation that numeric vectors pass through, including
R's `Inf`, `-Inf`, and `NaN` values. Explain that infinite bounds created by
`parse_cn_range()` represent open-ended textual bounds and are separate from
numeric point inputs.

Add matching concise notes to the Chinese and English README return-value
sections.

**Step 4: Regenerate Rd files**

Run:

```powershell
& 'D:\R\R-4.6.1\bin\R.exe' --vanilla -q -e "roxygen2::roxygenise('.', roclets = 'rd')"
```

Expected: only the three parser Rd files change.

**Step 5: Commit**

```powershell
git add R README.md README_EN.md man tests/testthat/test-parse-cn-*.R
git commit -m "docs: define numeric pass-through behavior"
```

### Task 3: Make source-package links and CRAN records complete

**Files:**
- Modify: `README.md`
- Modify: `.Rbuildignore`
- Create: `cran-comments.md`

**Step 1: Fix the language link in built sources**

Change the Chinese README language switch to:

```markdown
[English](https://github.com/Jorungandr/cncleanr/blob/main/README_EN.md) | **中文**
```

Keep `README_EN.md` excluded from the source package to avoid the non-standard
top-level-file NOTE.

**Step 2: Create the CRAN comments record**

Create `cran-comments.md` with sections for test environments, R CMD check
results, first-submission status, and downstream dependencies. Record zero
known downstream dependencies and explain only genuine unavoidable NOTEs.

**Step 3: Exclude the record from package builds**

Add this anchored rule to `.Rbuildignore`:

```text
^cran-comments\.md$
```

**Step 4: Build and inspect the archive**

Expected: the tarball contains `README.md`, does not contain `README_EN.md` or
`cran-comments.md`, and its English link is absolute.

**Step 5: Commit**

```powershell
git add README.md .Rbuildignore cran-comments.md
git commit -m "docs: prepare CRAN submission records"
```

### Task 4: Add standard spelling checks

**Files:**
- Modify: `DESCRIPTION`
- Create: `inst/WORDLIST`

**Step 1: Install the development checker if missing**

Run `install.packages("spelling")` only when `requireNamespace("spelling",
quietly = TRUE)` is false.

**Step 2: Declare spelling metadata**

Add:

```text
Language: en-US
```

and append `spelling` to `Suggests` without removing testthat.

**Step 3: Run the checker before adding exceptions**

Run:

```powershell
& 'D:\R\R-4.6.1\bin\Rscript.exe' --vanilla -e "spelling::spell_check_package()"
```

Review every reported token. Add only correct package names, API identifiers,
Chinese-data terms, and unavoidable technical tokens to `inst/WORDLIST`.

**Step 4: Re-run spelling**

Expected: no unrecognized words remain.

**Step 5: Commit**

```powershell
git add DESCRIPTION inst/WORDLIST
git commit -m "test: add package spelling checks"
```

### Task 5: Add lightweight contributor support

**Files:**
- Create: `CONTRIBUTING.md`
- Create: `.github/ISSUE_TEMPLATE/bug_report.yml`
- Create: `.github/ISSUE_TEMPLATE/feature_request.yml`
- Create: `.github/ISSUE_TEMPLATE/config.yml`
- Modify: `.Rbuildignore`

**Step 1: Add contributor instructions**

Document prerequisites, cloning, dependency installation, test commands,
roxygen regeneration, coding expectations, minimal pull requests, fixture
updates, and the rule that maintainers own versioning and releases.

**Step 2: Add issue forms**

The bug form must request input text, expected result, actual result,
`cn_problems()` output, minimal reproducible R code, package/R/OS versions, and
a confirmation that secrets or private data were removed.

The feature form must request the real source format, expected semantics,
representative examples, alternatives, and scope justification.

Disable blank issues. Do not link to Discussions unless the repository has
Discussions enabled.

**Step 3: Exclude contributor instructions from source builds**

Add:

```text
^CONTRIBUTING\.md$
```

to `.Rbuildignore`. `.github` is already excluded.

**Step 4: Validate YAML and archive contents**

Parse all issue forms as YAML using an available parser and confirm the source
tarball contains none of the repository-only contributor files.

**Step 5: Commit**

```powershell
git add CONTRIBUTING.md .github/ISSUE_TEMPLATE .Rbuildignore
git commit -m "docs: add contributor and issue guidance"
```

### Task 6: Run the complete quality and CRAN audit

**Files:**
- Update: `cran-comments.md`
- Verify: all package and repository files changed above

**Step 1: Run package tests through the standard path**

Run full testthat tests, `tests/parser.R`, build the source archive, and run
`R CMD check --no-manual`.

Expected: zero failures, warnings, or notes; the check log runs both test files.

**Step 2: Run auxiliary quality tools**

Run:

```r
urlchecker::url_check()
spelling::spell_check_package()
lintr::lint_package()
covr::package_coverage()
```

Install `covr` only if absent and installation succeeds without altering the
package dependency fields. Record the measured coverage; do not add a hosted
coverage service or invent a threshold after seeing the result.

Existing unavoidable line-length findings in regex and Unicode literals are
non-blocking. Fix ordinary newly introduced lint findings.

**Step 3: Run the CRAN-mode check**

Run `R CMD check --as-cran --no-manual` on the built source tarball. Separate
the expected new-submission NOTE and local network URL failures from package
defects. Any package-controlled ERROR, WARNING, or NOTE blocks completion.

**Step 4: Finalize cran-comments**

Record the actual local and GitHub environments and the final check counts.
Do not claim checks that were not performed.

**Step 5: Inspect repository scope**

Run `git diff --check` and `git status --short`. Confirm `.vscode/` remains
untracked and untouched.

**Step 6: Commit the finalized record**

```powershell
git add cran-comments.md
git commit -m "docs: finalize CRAN check summary"
```

### Task 7: Push and verify the development branch

**Files:**
- Verify: Git history and GitHub Actions only

**Step 1: Push main**

Push the completed commits to `origin/main` without creating a version tag or
release.

**Step 2: Require all CI jobs to pass**

Wait for Ubuntu R devel/release/oldrel-1, Windows release, and macOS release.
Confirm that `R CMD check` now executes both `parser.R` and `testthat.R`.

**Step 3: Report the remaining human actions**

List only tasks that require user authority or external confirmation, such as
R-hub/win-builder submission, choosing `0.2.4`, CRAN form upload, and maintainer
email confirmation.
