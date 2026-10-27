# Qualified Header Units Implementation Plan

**Goal:** Extend parse_cn_quantity() and parse_cn_range() with trailing unit=NULL,
using the approved number-parser table-header semantics without breaking defaults.

**Architecture:** Extract existing header validation/mapping into one private R
function. Forward unit through quantity parsing and both range endpoint paths.
Numeric header input uses parse_cn_number() rather than independent multiplication;
retain its diagnostics on the result frame. No native changes or dependencies.

**Tech Stack:** Existing R, registered C fast path, testthat, roxygen2.

## Approved design and alternatives

User approved quantity/range header support on 2026-10-27. Prefer propagation
through existing parser over multiplying finished results (double scaling risk)
or adding separate new public functions (unneeded API). Preserve six exports,
positional argument compatibility and default numeric infinity/NaN behavior.
Header numeric infinity/overflow follows number parser; open interval infinities
created by textual bounds remain valid. Conflicting/compound/percent units fail.

## Execution

1. Add tests/testthat/test-qualified-header-unit.R with literal quantity/range
   examples, every header unit, numeric/factor/empty/missing inputs, conflicts,
   reversed bounds, grouped spacing retry, duplicates and original diagnostics.
   Run against installed 0.2.21: expect unused unit argument failures.
2. Modify R/parse-cn-number.R shared validator, R/parse-cn-quantity.R and
   R/parse-cn-range.R propagation/numeric branches. Test focused then full suite.
3. Update DESCRIPTION/NEWS to 0.2.22, roxygen Rd and bilingual matching README
   examples, docs/verify-release.R smoke checks and release notes. No C changes.
4. Commit/push source; clean source build and local no-manual check, regular
   five-platform CI, literal README/imported-type/system audits and focused
   default/header performance comparison. Existing native .21 checks remain
   applicable only to unchanged C; no new native checks claimed.
5. Publish fixed v0.2.22 tag/exact checked archive. Independently download public
   asset without credentials, verify SHA256, compile/install and full tests.
   Update bilingual release install pin and verification record, push evidence.
   Do not submit to CRAN. Continue current authorized checkout without agents.
