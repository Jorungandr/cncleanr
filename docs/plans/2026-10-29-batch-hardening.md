# Batch correctness hardening implementation plan

**Goal:** Audit six public APIs, count reproducible defects by root cause and fix
the confirmed batch, preserving vector success performance and six function names.

**Architecture:** Reuse suffix propagation, shared input preparation and existing
explicit summary scan. No new grammar, public parameters, dependencies or C code.

**Tech Stack:** R/testthat/roxygen2, existing registered C conversion fast path.

User authorized a systematic review and one combined repair on 2026-10-29.
Avoid speculative additions; no agents/worktrees needed for this existing checkout.

## Confirmed root causes (initial audit: three)

1. Accounting endpoints: trailing units inside parentheses are not recognized,
   while inferred suffixes are appended outside parentheses. This rejects valid
   ranges and can silently give the opposite bare endpoint the wrong scale.
2. Dimensioned inputs: numeric/character matrices and arrays silently flatten
   although parsers document a vector API. Missing-marker arguments also need
   the documented dimension-free vector check.
3. Summary integrity: obviously malformed quantity/range results (unknown or
   inconsistent qualifiers, reversed bounds, inconsistent inclusivity) count as
   successful. Reject them in cn_summary's existing explicit result scan, not
   through new per-row scans in parsers/cn_subset.

## Approved implementation and verification sequence

1. Audit R parser/compound/diagnostic/subset/summary code and native conversion;
   generate independently computed signed/accounting/unit intervals. Record
   confirmed failures separately from unsupported syntax/provenance limitations.
2. Add failing regression tests: 8748 arithmetic gold interval cases; targeted
   accounting/header/missing/compound/percent/grouping tests; dimensioned inputs;
   summary shape/semantic guards. Confirm failures on installed 0.2.23.
3. Fix accounting by examining inner text for suffix detection, adding shared
   units inside wrappers, retaining original marker checks and compound guards.
   Keep ordinary non-parenthesized path batch-based. Reject dim(x) in shared
   preparation and dim(na) at argument validation. Extend summary-only validation.
4. Repeat independent gold tests, six-API full regression, imported-type/system
   and existing real-data audits. Inspect any remaining failures and repair
   confirmed root causes, then repeat. Count by root, not failed case count.
5. Update 0.2.24 NEWS/Rd, bilingual README and release notes. Commit/push source;
   clean source check and five-platform CI, ordinary success timing smoke.
6. Fixed GitHub tag/exact archive, unauthenticated public download/hash,
   isolated install/full tests, final README pins and audit report. No CRAN.

Known limits stay explicit: compound scales are not inferred; plain R objects do
not prove diagnostic provenance; finite testing cannot establish absence of all
possible bugs. This task does not reopen routine speed optimization.
