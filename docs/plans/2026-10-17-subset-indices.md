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

## Completion

Source d709e07412be75f852cfca67a0e1614aab36091c passed local exact-archive and
all five CI jobs (39023007179), 924 assertions each. Repeated full regression,
2,454 consistency comparisons, 28 actual bit64 checks and 600 further randomized
selector comparisons passed, as did all retained-data audits and snapshot hashes.
Plain-selector timing medians were unchanged in the measured sample. No further
reproduced defect remained in that scope; haven/units were not successfully
installed and are not certified.

GitHub v0.2.16 published at its fixed annotated tag. The public unauthenticated
download hash matched; isolated install, source/version, full regression and
generated/bit64 audits passed again. No runtime dependencies or C changes and no
CRAN submission. See docs/system-audit.md for detailed evidence and limits.
