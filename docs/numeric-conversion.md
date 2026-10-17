# 数值转换一致性 / Numeric conversion consistency

## 已修复问题 / Repaired behavior

A numeric S3 object's storage can differ from its converted value. The old
no-header branch and quantity/range parsers called `as.double()`, but the header
branch formatted the original storage with `sprintf()`. A minimal S3 object with
storage `1` and converted value `30000` therefore produced `10000` under header
万 instead of `300000000`. This is a synthetic regression fixture, not a claim
about a separately tested third-party package or real dataset.

0.2.15 converts once at numeric entry and uses that plain double vector for both
missing detection and header formatting. Original input names are restored.
No-header numeric Inf/-Inf/NaN pass-through remains; with a header, missing values
remain missing and infinities/overflow remain parsing problems. Numeric text
syntax and all C sources are unchanged. No additional character-input scan,
dependency, public argument or arbitrary class adapter is added.

数值 S3 对象的底层存储不一定就是转换后的数值。修复前，带表头单位的分支直接格式化
底层存储；现在先用已有 `as.double()` 转换，再判断缺失并换算。转换方法只调用一次。
这不保证精确大整数或任意第三方类别的语义；调用方仍需提供正确的转换方法，结果仍为
双精度数值。此处不引入 `integer64`、日期或单位类别的专用解析器。

## 回归与复现 / Regressions and reproduction

The dependency-free S3 test registers a unique method only inside its test call,
then removes it on exit, including failed tests. It covers all eight header
spellings, names and empty names, one conversion, converted sentinel missingness,
NA/NaN, infinities, negative zero, strict failures, plain integer/double values,
and quantity/range consistency. It failed on installed 0.2.14 before the repair.

```r
library(cncleanr)
testthat::test_file('tests/testthat/test-header-unit.R')
```

```text
Rscript docs/numeric-conversion-performance.R <new-library> <0.2.14-library>
```

The timing script compares complete equal outputs on 100,000 ordinary integers,
doubles and character cells with a header. It uses the same C routines, warm-up,
seven alternating paired samples and three calls per sample. This is a narrow
regression check, not a new speed-optimization campaign or universal latency
guarantee. Final results are recorded after verification; no CRAN submission.

## 本地验证 / Local verification (2026-10-17)

Checked source: `993fb773fac1f82df3b270fd1db13bacee03404b`.
Windows 11 x64, R 4.6.1 and existing UCRT GCC 15.2. Focused tests failed with
0.2.14 and passed after the repair. The exact clean-commit archive passed the
source/version verifier. Cross-domain retained-data auditing passed with no new
wrong acceptances; this reuses the recorded datasets, not newly collected data.

Seven-sample paired timing medians for 100,000 rows with `unit = '万'`:

| Ordinary input | 0.2.14 (seconds) | New (seconds) |
| --- | ---: | ---: |
| Integer | 0.140 | 0.140 |
| Double | 0.120 | 0.117 |
| Character control | 0.010 | 0.010 |

Complete values/names/problem attributes matched. No regression was observed in
these samples; small differences do not establish a speedup. Character processing
and C source files are unchanged. This release does not rerun or claim new
ASAN/UBSAN/Valgrind evidence; the previous C-change release's records remain
historical. Current package-level platform checks are recorded after completion.

## 检查与发布 / Checks and publication

- Both local exact-archive checks completed with **Status: OK**, 858 assertions,
  zero test failures/warnings/skips. The first attempt waited for a CRAN index
  request, then completed despite that download failure. A separate run used
  `options(repos = character())` to avoid the network lookup; installed dependency
  checks, installation, examples and all tests still ran. Neither local run
  checked the PDF manual, remote incoming or a complete remote dependency-cycle
  graph. No local files or package checks were patched to mask errors.
- [Five-platform CI 39021796845](https://github.com/Jorungandr/cncleanr/actions/runs/39021796845)
  checked the same source commit: all Status OK, 858 assertions each, zero test
  failures/warnings/skips. Linux release PDF/HTML manual checks were OK.
- [GitHub v0.2.15](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.15)
  points to the checked source using annotated tag object
  `7e120ddce75f6ee756818a2d826c1abbeecffcd5`. Previous tags/assets were unchanged.
  The checked/uploaded archive is 50,946 bytes with SHA-256:

```text
66D9B7ED057880520C7FCA1C3412E58E37894617BFE06687E4450B546929023A
```

GitHub's asset digest matches. An unauthenticated download through the public
GitHub asset API matched the same SHA-256, then installed in the isolated
`outputs/numeric-conversion/public-library/`. The source/version verifier,
complete 858-assertion suite and dependency-free base regression all passed.
Follow-up validation records change excluded docs only, not the fixed tag or
archive. This release was not submitted to CRAN.
