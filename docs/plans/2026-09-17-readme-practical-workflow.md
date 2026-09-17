# README Practical Workflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a bilingual, copy-and-run enterprise revenue cleaning workflow plus concise API and troubleshooting references without changing parser behavior.

**Architecture:** Keep all user-facing guidance in the two existing README files with matching section order and executable base R code. Protect the showcased transformation with one testthat regression test so future parser changes cannot silently invalidate the documentation.

**Tech Stack:** Markdown, base R, testthat 3, existing cncleanr public API.

---

### Task 1: Lock the practical workflow behavior

**Files:**
- Create: `tests/testthat/test-readme-workflow.R`

**Step 1: Add the regression test**

Create a small enterprise table containing `3.2亿元`, `约5万`, `10万+`,
`暂无`, and `3万abc`. Parse the source column and assert:

```r
expect_equal(cleaned$value, c(3.2e8, 5e4, 1e5, NA, NA))
expect_equal(
  cleaned$qualifier,
  c("exact", "approx", "at_least", NA, NA)
)
expect_equal(problems$index, 5L)
expect_equal(problem_rows$company, "戊公司")
```

**Step 2: Run the focused test**

Run:

```powershell
& 'D:\R\R-4.6.1\bin\R.exe' --vanilla -q -e "devtools::test(filter = 'readme-workflow')"
```

Expected: all new expectations pass because the test documents existing public
behavior.

**Step 3: Commit**

```powershell
git add tests/testthat/test-readme-workflow.R
git commit -m "test: lock README cleaning workflow"
```

### Task 2: Add the Chinese practical guide

**Files:**
- Modify: `README.md`

**Step 1: Add the end-to-end workflow**

Insert a section after installation that:

1. creates the five-row enterprise revenue table;
2. calls `parse_cn_quantity()` with warnings suppressed only because the next
   line inspects structured problems;
3. combines the original and parsed columns;
4. maps `cn_problems()` indices back to the source companies;
5. shows `write.csv(..., fileEncoding = "UTF-8")` as the export step.

Keep the original source text in the cleaned output.

**Step 2: Add the API contract reference**

Add a compact Markdown table covering:

| Function | Result |
| --- | --- |
| `parse_cn_number()` | numeric vector, one value per input |
| `parse_cn_quantity()` | `value` and `qualifier` columns |
| `parse_cn_range()` | bounds and inclusivity columns |
| `cn_problems()` | `index`, `value`, and `reason` columns |

Add a second table for the six qualifier values and inclusive/exclusive
semantics.

**Step 3: Add troubleshooting guidance**

Document the stable reasons demonstrated by the fixture corpus: unsupported
syntax, invalid digit spacing, conflicting qualifiers, reversed ranges,
invalid endpoints, and non-finite overflow. Explain that ordinary mode returns
partial results with warnings, while `strict = TRUE` stops immediately.

**Step 4: Commit**

```powershell
git add README.md
git commit -m "docs: add Chinese practical cleaning guide"
```

### Task 3: Mirror the guide in English

**Files:**
- Modify: `README_EN.md`

**Step 1: Translate the workflow and references**

Add the same sections in the same locations and order as the Chinese README.
Translate prose and table descriptions, but keep all R code, Chinese sample
inputs, output values, and stable API tokens identical.

**Step 2: Check structural parity**

Compare headings and fenced R blocks:

```powershell
rg '^## |^```r$' README.md README_EN.md
```

Expected: both files have corresponding practical workflow, return-value,
qualifier, troubleshooting, problem-inspection, and strict-mode material.

**Step 3: Commit**

```powershell
git add README_EN.md
git commit -m "docs: mirror practical guide in English"
```

### Task 4: Verify and publish the documentation update

**Files:**
- Verify: `README.md`
- Verify: `README_EN.md`
- Verify: `tests/testthat/test-readme-workflow.R`

**Step 1: Run all testthat tests**

Run:

```powershell
& 'D:\R\R-4.6.1\bin\R.exe' --vanilla -q -e "devtools::test()"
```

Expected: zero failed tests and zero warnings from testthat.

**Step 2: Run dependency-free tests**

Run:

```powershell
& 'D:\R\R-4.6.1\bin\Rscript.exe' --vanilla tests/parser.R
```

Expected: exit status 0.

**Step 3: Run package check**

Build the source package in a unique temporary directory and run
`R CMD check --no-manual` on the archive.

Expected: `Status: OK`.

**Step 4: Review repository scope**

Run:

```powershell
git diff --check
git status --short
```

Expected: no whitespace errors; unrelated `$build/`, `.vscode/`, `outputs/`,
and cloud-assignment files remain untracked and untouched.

**Step 5: Push and verify CI**

Push `main` and require all five R-CMD-check jobs to pass. Do not create a tag
or GitHub Release for this documentation-only development update.
