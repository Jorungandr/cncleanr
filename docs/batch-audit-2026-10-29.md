# Combined correctness audit — 2026-10-29

Baseline: public/installed v0.2.23. Scope: all six public functions, shared input
validation, number/quantity/compound/range paths, diagnostic selection/summary,
and native conversion source. Findings are counted by root cause, not failing
examples, and do not imply an exhaustive proof over all R objects or strings.

## Defect inventory: three confirmed families

| ID | Root cause | Reproduction on 0.2.23 | Repair |
|---|---|---|---|
| B1 | Accounting suffix detection/insertion | `(3万)-5万` and `(3)-5万` rejected | Recognize inner suffixes; insert inferred units before closing parenthesis |
| B2 | Dimensioned inputs bypass vector contract | A 2x2 numeric/character matrix silently becomes four values in all three parsers | Reject dimensioned x/na; request explicit column selection |
| B3 | Summary result-integrity checks incomplete | Reversed bounds or qualifier `nonsense` counted as successful | Validate qualifier/missingness and bounds/inclusivity in explicit summary only |

This is **one parsing defect plus two validation gaps**, not three separate
algorithm failures. B1 was already identified; B2/B3 were additional findings.
The batch also resolves the previously deferred accounting inheritance policy:
`(3万)-5` now means -30000 to 50000 rather than -30000 to 5. The historical
system-audit note deliberately left that semantic choice open; it is not counted
as a fourth defect or silently retroactively relabelled as an old bug.

## Audit / repair / re-audit

1. Read current R parsers, compound conversion, diagnostics/subsetting/summary
   and native code. Excluded documented unsupported grammar, precision limits,
   and unprovable provenance after ordinary R transformations from defect counts.
2. Reproduced all three families against the installed released package. Added
   regression tests before production edits; failures confirmed the gaps.
3. Fixed the shared root paths with no new public functions, parameters,
   dependencies or C changes. Existing units-object rejection and numeric
   conversion contracts stay intact. No extra summary scan inside parsers or
   cn_subset; no per-cell repair/reparsing layer.
4. Independent accounting interval oracle covers 8748 signed/unit/separator
   combinations. The baseline disagreed with 1728 cases under the new unified
   accounting policy (not 1728 distinct defects). The repaired code matches the
   complete oracle, including reversed/dimension-conflicting rejections.
5. Expanded tests after the first repair: grouped Unicode whitespace, currency,
   full-width wrappers, missing markers before/after inference, invalid signs,
   nested wrappers, compounds, vector shape and summary integrity. These passed;
   no fourth root cause was reproduced in this bounded second pass.
6. A separate arithmetic oracle checks 7392 scalar/parser combinations across
   magnitudes, signs, currency, accounting, percentages and six qualifier forms,
   plus summary/subset counts. These are permanent regressions in
   tests/testthat/test-batch-hardening.R, not only temporary audit scripts.

## Compatibility and limits

* Valid non-accounting vector behavior and six API names remain unchanged.
* Accounting inheritance is explicitly unified as above; explicit mixed scales
  remain distinct, percentages/currency conflicts reject, compound ambiguity
  still rejects. Original textual missing markers are not resurrected.
* Matrices/arrays must be reduced explicitly (for example `x[, 1]`); shaped
  missing markers must be supplied as an intentional character vector.
* Mutated invalid result frames can now error in cn_summary. Valid native parser
  results, numeric infinities/NaNs and textual open bounds remain supported.
* Plain R objects cannot establish provenance; arbitrary stale metadata after
  transformations is still not fully detectable. No promise of zero possible
  remaining defects. No new native sanitizer result or fresh data-source claim.

## Verified package and platform evidence

* Fixed source: edc176ba6a675b52336b6b0ce0d8acc5ff180244, version 0.2.24.
* Clean-source local R CMD check --as-cran --no-manual: Status OK on Windows,
  R 4.6.1/UCRT GCC 15.2. Incoming checks disabled; no local PDF check.
* Full suite: 1789 passed, 0 failures/errors/warnings/skips (137 new assertions).
  Counts are test assertions, not the 8748+7392 independently calculated cases.
* CI run 40901813520: all five platform jobs successful. GitHub connector logs
  confirm Status OK and 1789 passes on Ubuntu release/devel/oldrel, Windows,
  and macOS. Ubuntu release PDF reference manual check is OK.
* Both literal README editions: 14 runnable blocks each; three installation
  blocks deliberately not run, one expected error, no missing optional skips.
* Real imported-type checks: 77 passed (haven 2.5.5, units 1.0.1, bit64 4.8.6).
  Existing generated audit: 2454 consistency and 28 optional bit64 checks passed.
* Existing real/multi-source/broad-data audits passed; all nine retained input
  hashes matched. This is regression coverage, not newly collected data.
* Exact checkout/archive/installed-source/version verifier passed.
* Seven-run warmed 100000-success-row medians (old/new): number 0.01/0.02,
  quantity 0.10/0.11, range 0.81/0.84 seconds. Coarse timers are noisy. A paired
  same-process number comparison, 40 calls/sample with alternating order and
  identical native code, measured 0.0125/0.01175 seconds per call (five pairs).
  These are smoke checks, not a speedup or universal no-regression guarantee.

## Publication

* Annotated tag v0.2.24: 6927e870e64a8c8c6d0a2317826b7c0856584121.
* Public release: https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.24
* Release ID 428052320; asset 689005302, cncleanr_0.2.24.tar.gz, 70726 bytes.
* SHA256: 706ED3ECE9B5EB0483AB209962185FA0C88D1A7CBB05FD0D970964E959C8782D.
  Server size/digest match the locally checked archive. Public-download tests
  used an unauthenticated download resumed after transient connection failures;
  only the final complete, hash-matching file was independently compiled/installed.
* Public installed-package full suite: 1789 passed, 0 failures/errors/warnings/
  skips. Exact release staging checkout/archive/installed-source verifier passed.
  Final README pins point to v0.2.24; both editions' 14 runnable blocks and
  imported/system/optional-bit64 checks (77/2454/28) passed again. The final
  README/report-only commit does not change the fixed release archive.

本轮按根因统计共 3 类（此前 1 类＋新增 2 类），不是 1728 个独立缺陷。
三类均已修复，扩大复测中没有再复现第四类根因；有限范围测试不等于证明整个
项目不存在任何其他缺陷。历史括号继承策略的统一是明确列出的兼容性变化。
No CRAN submission. Previous tags and release assets are unchanged.
