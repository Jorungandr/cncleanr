# Numeric subset indices implementation plan

**Goal:** Prevent silent empty/manufactured rows when numeric S3 indices use
storage different from their converted values.

**Approved design:** Convert classed numeric `rows` using `as.double()` once,
before missingness, bounds, integer checks and base indexing. Reuse existing
selection/remapping; ordinary integer/double/logical indices are unchanged.
Reject malformed conversion results rather than inventing rows. No C changes,
new runtime dependency or general class adapter. Rejecting all classed numeric
indices was considered but would unnecessarily discard usable numeric methods.

**Execution:** Existing checkout, direct execution under writing-plans/Code;
user requested one complete GitHub workflow. CRAN is excluded.

1. Add dependency-free synthetic numeric S3 regressions for reordering, negative
   selection, duplicates, missing/nonfinite/fractional/oversized converted values,
   preserved diagnostic indices, one conversion and malformed method results.
   Demonstrate failure against installed 0.2.15.
2. Repair only `cn_subset` numeric selection entry in `R/problems.R`, update Rd,
   run focused/full tests, and check actual bit64 4.8.6 in a task-local library.
3. Repeat generated consistency corpus, all retained-data audits, snapshot hashes,
   and complete tests after repair. Record unsupported/unavailable types honestly.
4. Update bilingual README, NEWS and version to 0.2.16. Build from committed clean
   source and check exact archive locally and on all five existing CI platforms.
5. Publish only the checked archive at a fixed tag; publicly download, compare
   SHA-256, install in an isolated library and repeat tests/verifier. Record limits
   and results; do not claim exhaustive absence of all future software bugs.
