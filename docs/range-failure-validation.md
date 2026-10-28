# Range failure diagnostics validation — 2026-10-28

Source: c1b78794ee7f22014f57cfc16498838e4e5af111, package 0.2.23.

## Scope

Preserve specific scalar causes over generic range fallback errors; label diagnosed
left/right endpoint failures only for uniquely split non-exponent candidates.
Missing, ambiguous, grouping and structural failures retain conservative priority.
No grammar, accepted value, export, argument, C or dependency change. Exact reason
strings and cn_summary() reason groups may change; README/NEWS explicitly say so.

## Local verification

* Clean-source R CMD check --as-cran --no-manual: Status OK (Windows/R 4.6.1,
  UCRT GCC 15.2). Incoming network checks disabled; no local PDF check.
* 1652 assertions passed, 0 failures/errors/warnings/skips, including 28 new
  diagnostic/call-count assertions. The existing 3万-abc fixture was intentionally
  updated from generic endpoint failure to right endpoint syntax failure.
* 9591 generated input/header combinations compared with installed 0.2.22:
  identical parsed bounds/inclusivity and failed original indices/values. This
  is a compatibility comparison, not independent semantic gold evidence.
* Parser call-count test confirms one quantity call and two number calls for
  a mixed batch of ranges/scalar failures; no per-failure reparsing added.
* Same-machine timing smoke: 100000 distinct successful ranges, warmed, five
  runs, median 0.77 seconds in both 0.2.22 and 0.2.23. Not a timing guarantee
  or new speed-optimization claim.
* Both literal README editions: 14 runnable blocks each, one expected error,
  three installation blocks not executed, no optional skips.
* Imported-type/system audits: 77 real type, 2454 generated consistency and
  28 optional bit64 checks passed. Existing real/multi-source/broad-data audits
  passed; all nine dataset snapshot hashes matched. No new data collected.
* Checkout/archive/installed-source/version verifier and diagnostic workflow passed.
* Archive cncleanr_0.2.23.tar.gz: 67623 bytes.
* SHA256: FF5FEE2B940AD9947E97B18861CE6BAA589E602FB98EC86C59B4E9B586C4CFDE.

## Remote verification

CI run 40535124044 checked the exact source: all five platform jobs successful.
Ubuntu devel/release, Windows and macOS downloaded logs show Status OK and 1652
passes. Ubuntu release PDF manual is OK. Oldrel job 122298187336 log was retrieved
through the GitHub connector after CLI download failed; it also shows Status OK
and 1652 passes. Native C matches v0.2.22; no new sanitizer run claimed.

Annotated v0.2.23 tag: 713a55f09d81908f49f097dc9951d6410bf20ef9.

## Publication

* Public release: https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.23
* Release ID 426204486; asset ID 683592141, cncleanr_0.2.23.tar.gz.
* Server size/digest match the local archive above. Unauthenticated public
  browser-download URL returned the exact SHA256; isolated compilation and
  installation with tests succeeded. Checkout/archive/installed-source verifier
  and diagnostic workflow passed before README-only installation pin updates.
* Public installed-package full suite: 1652 passed, 0 failures/errors/warnings/
  skips. Final README editions each passed 14 runnable blocks; real imported-type
  and generated-system/optional-bit64 audits passed again (77/2454/28).
* Transient DNS/proxy/connection failures were retried with remote state checked
  before writes. Existing tags/assets were not overwritten. No CRAN submission.
