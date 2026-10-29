# 系统检查与数值下标修复 / System audit and numeric selectors

## 范围与结果 / Scope and findings

Audit baseline: installed 0.2.15. Reviewed parser input validation, native entry
points, numeric boundaries, encoding diagnostics, selection/remapping, example
workflows, package metadata and release reproducibility. Existing tests and
retained public data supplement, not replace, independent known-answer tests.

Confirmed defect: actual bit64 4.8.6 numeric selectors `c(2,1)` produced an empty
selection; `-1` could manufacture a missing row. A synthetic numeric S3 selector
also demonstrated that its conversion method was ignored. All three parser
result forms were affected through the single `cn_subset()` entry point.

Repair: call `as.double()` once only for classed numeric selectors, then validate
the converted plain double vector and reuse existing base selection/remapping.
Malformed result type/class/dimensions/length is rejected. Ordinary integer,
double and logical indices avoid this conversion; parser algorithms and C are
unchanged. No extra runtime/test dependencies or general class-adapter layer.

本轮已确认的问题集中在数值下标入口，而非三个解析算法。修复后再跑原有测试、
生成语料一致性、真实 bit64 及公开数据审计；不把测试通过表述为永远不会有缺陷。

## 可复现检查 / Reproduce

```text
Rscript docs/system-audit.R <installed-library> [optional-bit64-library]
```

The generated audit uses a fixed seed and covers 2,454 comparisons: scalar/batch,
factor, duplicates, missing markers, diagnostic remapping, and rejection of dates,
date-times, durations, logical/complex/raw/list/NULL inputs. These comparisons
detect inconsistent paths, not a shared wrong semantic interpretation. The
optional bit64 section adds 28 checks; unavailable optional checks are printed as
not tested. The package's permanent regressions instead use a dependency-free
S3 fixture, including invalid conversion results and one-conversion assertions.

日期、时间和时长当前明确拒绝，不自动把它们解释为天数或秒数。integer64 经数值
转换后仍受 double 精度限制；超过精确范围的整数可能由 bit64 发出精度警告。
自定义类别的单位含义不能由通用解析器推断。haven 和 units 在本机安装尝试失败，
不列为已验证；未为此新增依赖或改变第三方对象的含义。

Retained financial/multi-source/broad-data audits and nine snapshot hashes are
rechecked; no new sources or data coverage are claimed. Ordinary `[]`/binding/CSV
still do not automatically maintain diagnostics. An accounting-unit range such
as `(3万)-5` retains existing behavior; changing unit inheritance here requires a
separate semantic decision and is not silently included in this bug fix.

Later policy update (0.2.24, 2026-10-29): accounting suffix inheritance was
explicitly unified in the requested batch repair; `(3万)-5` now spans -30000 to
50000. The paragraph above records the historical 0.2.15/0.2.16 audit scope,
not the current grammar. See the current batch audit and NEWS compatibility note.

Publication and final validation evidence follows after completion. No CRAN upload.

## 修复后复测 / Post-repair recheck (2026-10-17)

Source checkpoint: `d709e07412be75f852cfca67a0e1614aab36091c`.

- Focused S3 tests failed against installed 0.2.15 and passed after the repair.
  The permanent suite now has **924 assertions** (66 added), no new dependency.
- The complete 2,454-comparison generated audit and 28 actual bit64 4.8.6 checks
  passed. A second fixed-seed randomized pass added **600** comparisons of plain
  versus bit64 positive/zero/negative selectors across all three result forms;
  complete values and diagnostic attributes matched. No further reproduced defect
  was found in these checks. This is a bounded audit, not exhaustive proof.
- All three retained-data audits passed again and all nine raw snapshot hashes
  matched. The financial cases retain 1,412 valid/6 rejected malformed fragments;
  multi-source measurements and broad-data derived intervals retain their
  existing outcomes. No fresh data coverage is claimed.
- Same-process plain-selector performance check: 100,000 indices, seven paired
  alternating samples, 20 calls/sample, complete equality checked. Old and new
  medians were both **0.0015 seconds**. No regression observed in this sample;
  no general zero-overhead or speedup claim. No new performance campaign.
- Exact clean-source archive local check: **Status OK**, 924 assertions, zero
  failures/warnings/skips. Used `--as-cran --no-manual`, disabled remote incoming
  and repository-index lookup (`repos=character()`) to avoid known connection
  stalls. Installed dependencies were checked, but local PDF/incoming and remote
  dependency-cycle analysis were not. R 4.6.1, Windows 11 x64, UCRT GCC 15.2.

C sources did not change; no new ASAN/UBSAN/Valgrind run is claimed. The prior
native-tool records remain historical. Package-level platform validation and
public attachment verification are recorded after completion below.

## 跨平台与发布 / Platform checks and release

[CI 39023007179](https://github.com/Jorungandr/cncleanr/actions/runs/39023007179)
completed on the same source: Linux release/devel/oldrel-1, Windows release and
macOS release all Status OK, 924 assertions each without failures/warnings/skips.
Linux release PDF and HTML manual checks were OK. Actual job logs were inspected.

[GitHub v0.2.16](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.16)
uses annotated tag `c4930d8657a457b926fe684c23578728ef786a01`, pointing to the
checked source checkpoint above. The exact checked asset is 51,550 bytes:

```text
SHA256 B1D124D2C2A9ACBFE603607A7AC1EF7B0B86C3B36BC3580349EC2C82C2FE0D8C
```

GitHub's asset digest matches; old tags/assets were not changed. No CRAN upload.
An unauthenticated public asset API download matched the checked SHA-256 and
installed into `outputs/subset-indices/public-library/`. Source/version verifier,
all 924 assertions and the dependency-free base regression passed; the 2,454
generated comparisons and 28 real bit64 checks passed again against that exact
downloaded package. Follow-up records change excluded docs only, not the fixed
tag, package sources or attached archive.

在本轮已运行的范围内，没有剩余的已复现缺陷；未安装的第三方类型、其他硬件／R
版本及未穷举输入不在此结论内。测试通过不等于软件在所有未来输入上不会出问题。
