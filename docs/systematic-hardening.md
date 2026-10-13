# 系统整改与发布验收 / Systematic hardening and release validation

2026-10-13，GitHub 正式版本 0.2.12。集中完成已批准的正确性与工程整改；
没有新增语法、运行时依赖、第二套解析包，也没有 CRAN 提交。
Release 0.2.12 consolidates the approved audit fixes, without new syntax,
runtime dependencies, a second parser package or CRAN submission.

## 修复与兼容性 / Fixes and compatibility

- `3%-5元`、`3%-5万` 等不再作为有效区间；`3-5%`、`3万-5亿` 保留。
- 数字解析在 factor 转换和空返回前保存名称。
- 极端转换先合并十进制指数与倍率，保留 `1e309% = 1e307`、
  `1e-330万亿 = 1e-318`。普通输入维持原转换与舍入；最终非零下溢报告问题。
- `.1 234` 与 `0.1 234` 都拒绝，整数三位分组仍有效。
- 分组区间按实际端点失败报告，不再把缺失端点都归为分组错误。
- 区间候选超过八个分隔符则拒绝，限制反复切片的最坏资源消耗。
- 审计入口必须加载与 checkout 相同版本；快照校验和源码包核对可执行。

Percentage/non-percentage endpoint conflicts, name preservation, extreme
scaling, fractional grouping and endpoint diagnostics are corrected. New reasons
cover incompatible units, final underflow and excessive separators. Existing
reason spellings remain; some grouped cases now use the correct endpoint reason.
Numeric pass-through, public signatures and undecided semantic policies remain.

The native path defers nonzero underflow and scaled subnormal bodies to the R
boundary converter. It does not acquire a high-precision arithmetic dependency.
The unused normalization flag was removed rather than adding another abstraction.

## 当前证据 / Evidence so far

- Independent regressions failed against installed public 0.2.11, then passed
  against the candidate; existing differential and encoding tests passed.
- All nine retained source snapshots match the recorded SHA-256 values.
- Current financial audit: 1,412 valid spans correct, six malformed spans rejected;
  1,393 eligible bounds correct, 12 manual examples passed, 2,100 full answers rejected.
- Multi-source audit: 377 scalar CSL expressions, 37 intervals, 2,029 penguin
  measurements and 35 missing cells correct; nine review expressions stay separate.
- Broad audit: 48 review texts rejected, 692 derived salary intervals correct;
  no wrong outcomes. This is reuse of recorded snapshots, not new data acquisition.
- Launcher repair/restoration/exit-code checks passed. Compilation used existing
  local UCRT GCC; shell utilities needed a process-local PATH, not system changes.

Final source archive, platform CI, native tools and public asset evidence is
recorded below. Historical native results are not reused as fresh evidence.
PDF/incoming checks unavailable locally are not claimed.

## 最终源码包 / Checked source archive

`outputs/systematic-hardening/artifacts/cncleanr_0.2.12.tar.gz`

SHA-256: `9C9B6C06D7D2FB893C6F17AFE1C2C6D4BA55CE90D91B75144039F7353DF324E7`

- Windows 11 x64, R 4.6.1, existing UCRT GCC 15.2: exact archive
  `R CMD check --as-cran --no-manual` returned `Status: OK`, exit 0,
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 633`. Incoming disabled; no local PDF check.
- `docs/verify-release.R` passed against the check-installed package and checked
  archive, comparing package contents with the checkout (allowing CRLF/LF and
  R CMD build's DCF whitespace folding). Wrong version tags are rejected.
- All 633 development assertions, dependency-free `tests/parser.R`, retained
  audits, batch stress and CSV round-trip passed. `gctorture(TRUE)` with all
  three public parsers, full-width inputs and extreme scaling also passed.
- [Source CI 38343202131](https://github.com/Jorungandr/cncleanr/actions/runs/38343202131)
  at `5b58e6852f742a1c92e85126de7c054914a1134f`: all five platform checks
  `Status: OK`, 633 assertions each. Linux release PDF and HTML manuals both OK;
  installing Tidy removed the previous skipped-HTML NOTE.

The archive package payload matches this source checkpoint. Later verification
script/report changes are excluded from the package; the hash above identifies
this specific checked archive, not every rebuild.

Native tools: [R-hub 38343208232](https://github.com/Jorungandr/cncleanr/actions/runs/38343208232)
checks the same source checkpoint. clang-ASAN, clang-UBSAN and Valgrind all
report `Status: OK`, 633 assertions each. Actual Valgrind logs for examples,
dependency-free regression and testthat report `0 errors from 0 contexts`,
with definitely/indirectly/possibly lost all zero bytes.

Negative checks also verified stale installed-version rejection, wrong release
tag-version rejection, invalid snapshot arguments and missing snapshot rejection.

## 发布完成 / Published

[GitHub v0.2.12](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.12)
固定标签指向 `fd52a635a759c076d21f9241fd8c4b16db696f3d`，旧标签未改动。
[最终标签 CI 38343908692](https://github.com/Jorungandr/cncleanr/actions/runs/38343908692)
五项均 OK、633 个断言各自通过，Linux PDF 和 HTML 手册也均 OK。
标签与原生检查点的包文件一致，后续差异仅为包外验收脚本/记录。
正式附件为 40,792 字节，GitHub digest 和发布后重新下载的 SHA-256
均与上面的已检查文件一致。独立库安装成功，发布验收脚本通过。
下载附件安装后的完整 633 个断言与基础回归也全部通过。
本次没有提交 CRAN。

Published at the fixed tag above. All five final-tag CI checks passed 633
assertions each, including Linux PDF/HTML validation. Package payload matches
the native-tool checkpoint. The 40,792-byte public source attachment was
downloaded, hash-verified, installed independently and passed release smoke
verification, all 633 development assertions and the dependency-free regression.
Existing tags/assets are preserved. No CRAN submission.

## 留存限制 / Retained limits

Double rounding above `2^53`; extract problems before transforming results;
malformed UTF-8 stops the batch; textual missing matching, matrix flattening and
accounting suffix policy are unchanged. Fixed dataset hashes may not be retrievable
from dynamic APIs later. Action SHA pinning and certification of every older R /
locale are not claimed. CRAN draft remains explicitly unsubmitted.
