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

The preceding queue status records the 2026-10-19 checkpoint, not the final result.

## Publication completed — 2026-10-27

* Release source: edd91b13d9276c054f1cbf9e70b2b551572fbe10.
* Regular CI run 39281071508: all five platform jobs successful, including
  Ubuntu release PDF manual check. Downloaded Windows, macOS, Ubuntu release
  and devel logs show Status OK and 1535 passing assertions; oldrel job status
  is successful (its log download failed).
* R-hub run 39280643669: clang-asan, clang-ubsan and valgrind successful on
  360c0d52efb8cba5c8ef4e67d9f72dbde03dcfdb. R/C/tests are unchanged in the
  release source. All three downloaded logs show Status OK and 1535 passes;
  Valgrind reports ERROR SUMMARY: 0 errors.
* Fresh local clean-source check: Status OK, with --no-manual and incoming
  checks disabled. Initial attempt lacked suggested packages because R_LIBS_USER
  changed; rerun used the existing user library, with no package-code workaround.
* Annotated v0.2.21 tag: 6bf4c2f5d52c072954ae52c28829969b89679f66.
* Public GitHub release: https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.21
* Asset ID: 681839674, cncleanr_0.2.21.tar.gz.
* SHA256: 691E5ECE1EFF274AA7849FBFA131AD304DADA618C8874B43237EF4A3EE0B130D.
* Unauthenticated public download matched that hash, independently compiled and
  installed with tests. Checkout/archive/installed-source verifier and diagnostic
  workflow passed before subsequent README-only installation updates.
* Public installed-package full suite: 1535 passed, 0 failed/errors/warnings/skips.
  Both final README editions passed 13 runnable blocks; 77 imported-type,
  2454 generated consistency and 28 optional bit64 checks also passed.

CRAN and previous release assets are unchanged.
