# Hundred-yuan validation — 2026-10-19

Implemented explicit 百元 suffixes, table-header multiplier 100, quantity
qualifiers/infix 余 and shared range suffixes through existing R/C paths.
No new dependency, public API rename, bare 百 support or CRAN submission.

Local R 4.6.1 / Windows 11 / UCRT GCC 15.2:

* Installed-package full suite: 1535 passed, 0 failed/errors/warnings/skips.
* Clean source `R CMD check --as-cran --no-manual`: Status OK. Incoming network
  checks disabled; no local PDF check. A second clean build with bilingual
  installation edits also returned Status OK. Later edits are README prose,
  installation pins and inline comments only, not executable package code.
* Both literal README audits: 13 blocks each; 3 installation blocks deliberately
  not executed. Includes one intentional error; no optional units skips.
* 77 real imported-type checks, 2454 generated consistency checks and 28 optional
  bit64 checks passed. Existing real/multi-source/broad-data audit scripts passed,
  and all nine input snapshot hashes matched. These are regression datasets,
  not newly collected hundred-yuan semantic examples.
* Warmed 200000-row simple inputs, 7 repetitions: median 0.06 seconds for 百元
  and 0.06 seconds for 千元 on this machine. Not an all-workload timing guarantee.

Source code: 360c0d52efb8cba5c8ef4e67d9f72dbde03dcfdb.
R-hub ASAN/UBSAN/Valgrind requested in run 39280643669, still queued at the last
check. Regular cross-platform CI runs also queued. No sanitizer or remote check
pass is claimed. README-only follow-ups do not change R/C/test content.

GitHub release/tag/asset publication is deferred until remote checks complete;
no v0.2.21 release or public-asset verification is claimed. Use `main` to test
the new unit now. Existing v0.2.20 release and CRAN are unchanged.
