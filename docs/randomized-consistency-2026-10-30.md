# Fixed-seed consistency audit / 固定种子一致性检查

## Scope and outcome / 范围与结论

This batch adds four permanent generated tests (43 assertions). No new
supported-behavior parser defect was reproduced. R/ and src/ are identical to
v0.2.24: no speed claim, grammar extension, public API or dependency change.
Finite tests cannot prove the absence of all possible defects.

本轮新增四组永久测试、43 项断言，尚未复现新的解析缺陷。生产 R/C 代码与
0.2.24 相同；没有增加接口、语法、运行时扫描或依赖，也不宣称提速。

* Seed 20261030: 3000 signed/accounting scalars, including randomly selected
  full-width variants and outside whitespace; 3000 qualified quantities.
  Expectations use coefficient arithmetic and an explicit qualifier table.
  Per-cell relative tolerance is 1e-14, with absolute tolerance 1e-14 near zero;
  large-unit rows cannot hide an error in a small-unit row.
* Seed 20261031: 3000 accounting intervals across seven suffixes, three
  separators and left/right/both explicit-unit placement. Independently
  calculated bounds, inclusivity and successful summary counts are checked.
* Seed 20261101: 4096 mixed rows under seven header settings (28672 row-setting
  comparisons). Complete outputs and problem attributes must be identical;
  reciprocals also check signed zero. This is differential consistency, not an
  independent semantic oracle. The reference disables C_simple_numbers in the
  initial call AND recursive deduplication calls. Native normalization is still
  shared; this is not an entirely independent parser implementation.
* Seed 20261102: 2048 labelled inputs per parser, 3072 selections with replacement,
  followed by reversal and empty selection. Problem positions, original failed
  text, missing/failed/success counts and repeated rows use independent labels.
* RNG state is saved/restored, including the absence of .Random.seed. Cases and
  assertions are different units and are not summed into a single defect count.

Review caught and repaired a test-reference gap before publication: recursive
deduplication initially resolved the optimized parser. The final reference binds
its recursive name to itself. This was a test construction issue, not a new
production algorithm bug. The unpublished draft attachment and preparation tag
were finalized together; no earlier released tag or asset was changed.

## Evidence / 验证记录

Final release source: 821d560eff049dd953ba393dac2bb76d7a63541f.
Annotated v0.2.25 tag: 5c9ffb77046e572fc13e64ae25c5b2fd617fba0a.
Archive: cncleanr_0.2.25.tar.gz, 72600 bytes.
SHA256: 5CAC55025B15CE3EE1AFCD0D86160247309CB1809600D05C1F4F7E092BEEDAE6.

Final exact-archive local check passed all 1832 assertions (0 failures,
warnings or skips), examples, compilation and loading. Its overall result is
0 errors, 0 warnings, 1 NOTE: remote current-time verification was unavailable.
The preceding draft archive had Status OK; that is not the final archive's
status. Checkout/archive/installed-source verification passed on the final file.
Local check uses Windows R 4.6.1/UCRT GCC 15.2, --as-cran --no-manual, incoming
checks disabled. PDF validation belongs to Ubuntu release CI. Platform and
public installation results are recorded below.

Both README editions' 14 runnable blocks passed (one expected error each;
three installation blocks deliberately not executed). Existing audit scripts
passed 77 imported-type, 2454 generated-consistency and 28 optional-bit64
checks. Existing real/multi-source/broad snapshots passed their checks; all
nine input hashes matched. These reused data, not newly collected sources.

## GitHub validation / GitHub 验证

Run 41069154150 on the final source completed successfully. Downloaded job logs
confirm Status OK and 1832 passing assertions on macOS release (124108360944),
Ubuntu oldrel-1 (124108361066), Ubuntu release (124108361153), Windows release
(124108361216) and Ubuntu devel (124108361346). Ubuntu release also passed its
PDF manual check. These are fresh final-source results, not the earlier draft run.

Release: https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.25
Release ID 429100334, final asset ID 692316608. Server size and SHA256 match
the final local archive. No earlier published release was changed.

The public attachment was downloaded without authentication using the asset API
after a transient reset on the browser download URL. Its complete SHA256 matched
before compilation. Independent public-archive installation with tests passed
all 1832 assertions (0 failures, warnings or skips), followed by successful
checkout/archive/installed-source and version verification. No partial download
was installed. Final evidence-only documentation does not alter the release
archive or its source tag.

No fresh sanitizer result, universal performance guarantee or CRAN submission
is claimed. Final production files have no changes from v0.2.24.
