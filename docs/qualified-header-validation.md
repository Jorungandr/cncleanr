# Qualified header-unit validation — 2026-10-27

Source: 56f821a9b371ecbff4258272c350ec610be825ba (0.2.22).
Quantity/range `unit=NULL` defaults remain unchanged. Shared validation and
number parsing handle explicit units, missing values, numeric overflow and
header conflicts. No native changes relative to v0.2.21, no new dependencies.

## Local evidence

* 1624 full-suite assertions passed, 0 failures/errors/warnings/skips.
* Clean archived source check on Windows/R 4.6.1/UCRT GCC 15.2: 0 errors,
  0 warnings, 1 NOTE: unable to verify current time remotely. `--no-manual`,
  incoming checks disabled. No package-code fix or check suppression for this NOTE.
* Checkout/archive/installed package source/version verifier and diagnostic
  workflow passed. Source archive: cncleanr_0.2.22.tar.gz, 65819 bytes.
* SHA256: 63973D32E199AAC1460DEE88E1C62971629EC9A4FCBD6C52A2F6E40485C50BE0.
* Both literal README audits: 14 runnable blocks each including one expected
  error; three installation blocks deliberately not executed; no optional skips.
* 77 imported-type, 2454 generated consistency and 28 optional bit64 checks passed.
* Additional SPSS missing/labelled/bit64 numeric inputs across five header units:
  30 quantity/range comparisons agree with the existing number-parser results.
  These are consistency checks, not independent semantic gold cases.
* Existing real-data, multi-source and broad-data regressions passed; nine input
  snapshot hashes matched. No new datasets collected for this release.

## Timing smoke check

Same machine, separate fresh R processes loading installed 0.2.21/0.2.22;
100000 distinct rows, warmup and five runs, median seconds:

| Workload | 0.2.21 default | 0.2.22 default | 0.2.22 千元 header |
|---|---:|---:|---:|
| Number | 0.01 | 0.01 | 0.02 |
| Approximate quantity | 0.10 | 0.11 | 0.09 |
| Two-endpoint range | 1.77 | 1.65 | 1.61 |

Timing is noisy and not a speedup claim or guarantee. This update extends header
support, not the previously closed runtime-optimization project.

## Remote checks

CI run 40523497306 checks the exact source. Ubuntu release/devel, Windows and
macOS logs show Status OK and 1624 passes; Ubuntu release PDF manual is OK.
Oldrel environment setup was still running at this checkpoint. No fresh native
sanitizer run is claimed for this R-only update.

## Publication

* All five platform jobs in CI run 40523497306 succeeded. Oldrel's initial
  attempt stalled in Ubuntu apt downloads before package tests; it was cancelled
  and rerun alone on the identical commit. Final oldrel job 122263661594 log
  confirms Status OK and 1624 passes. Other successful matrix results retained.
* Annotated v0.2.22 tag: e01e372c570d31a34507684e1185af59e48fd593.
* Release: https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.22
* Public asset ID: 681913956, 65819 bytes, server SHA256 matches the local hash
  recorded above. Source/tag/package version are fixed; README-only installation
  updates made afterwards do not change that release archive.

* Unauthenticated download from the public GitHub browser-download URL matched
  the SHA256 above. Independently compiled and installed with package tests in
  a fresh task library: 1624 passed, 0 failures/errors/warnings/skips.
* Exact release-source staging checkout/archive/installed-source verifier and
  diagnostic workflow passed before delivery. Final main README-only install
  pins point at v0.2.22; both final editions passed 14 runnable blocks again.
  Public installed-package imported-type/system audits passed (77/2454/28).
* Transient DNS/proxy/HTTP download failures were retried without altering package
  code or checks. A stalled partial download was replaced by the hash-verified
  complete public download before installation; no validation used the partial file.

No CRAN submission. Previous release assets are unchanged.
