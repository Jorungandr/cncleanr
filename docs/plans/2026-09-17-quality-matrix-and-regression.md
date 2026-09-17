# Quality Matrix and Regression Corpus Implementation Plan

**Goal:** Strengthen the released parser behavior with multi-version R checks, auditable real-world fixtures, and cross-parser invariants without adding public API.

**Architecture:** Expand the existing GitHub Actions matrix using the current r-lib standard layout. Store UTF-8 cases in plain TSV fixtures and exercise them through the public parsers. Add invariant tests that independently verify output shape, failure visibility, strict-mode consistency, and finite successful values.

**Tech Stack:** Base R, testthat 3, GitHub Actions, r-lib/actions v2.

---

### Task 1: Expand the R compatibility matrix

**Files:**
- Modify: `.github/workflows/R-CMD-check.yaml`

**Steps:**
1. Add Ubuntu R devel and Ubuntu R oldrel-1 to the existing three OS jobs.
2. Pass the official release HTTP user agent for the devel job.
3. Keep fail-fast disabled so every platform reports independently.
4. Retain the extended testthat step before `R CMD check`.

### Task 2: Add auditable real-world fixtures

**Files:**
- Create: `tests/testthat/fixtures/number-cases.tsv`
- Create: `tests/testthat/fixtures/quantity-cases.tsv`
- Create: `tests/testthat/fixtures/range-cases.tsv`
- Create: `tests/testthat/helper-fixtures.R`
- Create: `tests/testthat/test-real-world-fixtures.R`

**Steps:**
1. Record representative PDF, spreadsheet, and web values as UTF-8 text.
2. Include both successful and deliberately rejected number inputs.
3. Include exact, approximate, strict, inclusive, plus, and `余` quantity forms.
4. Include closed ranges, open bounds, exponent ranges, negative ranges, and invalid ranges.
5. Load fixtures without third-party data-reading dependencies.
6. Assert outputs and structured problems against every fixture row.

### Task 3: Add parser invariants

**Files:**
- Create: `tests/testthat/test-parser-invariants.R`
- Modify: `R/parse-cn-quantity.R`

**Steps:**
1. Assert every parser returns one result row or value per input element.
2. Assert every invalid non-missing value is `NA` and appears in `cn_problems()`.
3. Assert successful exact-number outputs are finite.
4. Assert strict mode reports the same failure positions as non-strict mode.
5. Make invalid quantity qualifiers missing instead of incorrectly retaining `exact`.

### Task 4: Mark the development cycle

**Files:**
- Modify: `DESCRIPTION`
- Modify: `NEWS.md`

**Steps:**
1. Set the development version to `0.2.2.9000`.
2. Record CI matrix and regression-corpus improvements under a development heading.

### Task 5: Verify and push

**Files:**
- Modify: `.Rbuildignore`
- Verify: all modified package files

**Steps:**
1. Exclude local editor, output, build, and translated README files from the
   source package without removing them from the repository.
2. Run all testthat and dependency-free tests.
3. Install and build the package; validate Rd files and examples.
4. Run `git diff --check` and verify unrelated untracked files remain untouched.
5. Commit and push to `main` without creating a release tag.
6. Require all five GitHub Actions jobs to pass.
