# Chinese Compact Number Parser Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a tested pure-R package that parses common compact numeric values found in Chinese spreadsheets.

**Architecture:** A small exported vectorised function normalizes text, performs a full anchored parse, and applies explicit unit multipliers. Parse failures are never silently truncated: non-strict mode warns and attaches structured diagnostics, while strict mode errors.

**Tech Stack:** R 4.6.1, base R, roxygen2, testthat 3e, devtools.

---

### Task 1: Create the package skeleton

**Files:**
- Create: `DESCRIPTION`
- Create: `LICENSE`
- Create: `.Rbuildignore`
- Create: `.gitignore`
- Create: `README.md`
- Create: `R/cncleanr-package.R`

**Steps:**
1. Add minimal package metadata with testthat 3e configuration.
2. Add package-level documentation and a README usage contract.
3. Run `devtools::document()` and expect generated `NAMESPACE` and `man/cncleanr-package.Rd`.

### Task 2: Specify behavior with failing tests

**Files:**
- Create: `tests/testthat.R`
- Create: `tests/testthat/test-parse-cn-number.R`

**Steps:**
1. Add examples for units, percentages, full-width text, missing values, negatives, input types, failures and strict mode.
2. Run `devtools::test()`.
3. Expect failure because `parse_cn_number()` does not exist.

### Task 3: Implement the parser

**Files:**
- Create: `R/parse-cn-number.R`

**Steps:**
1. Implement base-R normalization and an anchored regular expression.
2. Apply the explicit multipliers `1`, `1e4`, `1e8`, and `1e12`.
3. Preserve names and attach a `problems` data frame after non-strict failures.
4. Run `devtools::test()` and expect all tests to pass.

### Task 4: Generate documentation and run package checks

**Files:**
- Generate: `NAMESPACE`
- Generate: `man/parse_cn_number.Rd`
- Generate: `man/cncleanr-package.Rd`

**Steps:**
1. Run `devtools::document()`.
2. Run `devtools::test()` and expect zero failures.
3. Run `devtools::check(error_on = "never")`.
4. Expect zero errors and zero warnings; review any notes.

