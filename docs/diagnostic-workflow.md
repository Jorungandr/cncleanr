# 诊断工作流与验收 / Diagnostic workflow and validation

2026-10-13，cncleanr 0.2.13 已发布。保持原结果类型和编码失败中止策略，
不增加运行时依赖，不提交 CRAN。Release retains plain result types and
whole-batch encoding errors, without runtime dependencies or CRAN submission.

## 已实现 / Implemented

- `cn_subset(x, rows)` 同步筛选、重排和重复取行的问题；下标对应当前结果。
  Keeps diagnostics with explicit selection/reordering/repetition and remaps
  indices to the current result. It does not reparse or repeat warnings.
- 逻辑向量须等长；数值索引只接受有限整数且在范围内，可用零或负索引。
  Integer-valued numeric or full-length logical indices only. Missing/fractional/
  nonfinite/out-of-range indices fail, avoiding manufactured empty rows.
- 普通 `[]`、修改和合并不会自动跟踪，不能恢复已经丢失或过期的诊断。
  No S3 result classes or arbitrary-operation interception; use the helper before
  other transformations and keep source IDs/selection indices separately.
- 编码错误保留原错误类型说明，再补充参数名与首个原始失败位置。
  Errors identify `x` versus `na` and first original position, including factors,
  fallback subsets and deduplication. If both arguments are damaged, it locates
  the argument whose encoding failure was actually encountered first.
- 定位只在错误后按原参数二分查找，复用现有原生验证；正常批次无额外全量扫描。
  Error-only binary search reuses native validation; no extra successful-input
  encoding pass. Existing C sources and UTF-8/bytes/noncharacter rejection stay.

## 复现 / Reproduce

```r
library(cncleanr)
source('docs/diagnostic-workflow.R', encoding = 'UTF-8')
testthat::test_file('tests/testthat/test-diagnostic-workflow.R')
```

Install this checkout first, run from the repository root and record the loaded
version/path. The independent new tests failed against installed public 0.2.12,
then passed after implementation. Existing native/R outcome checks are retained.
The executable example is checked on all five CI environments and by the release
verifier. Complete validation and publication evidence follows below.

Public APIs retain their earlier signatures; `cn_subset` is one additional export.
Encoding messages gain location context; ordinary `cn_problems()` schema/reasons
remain unchanged. This is not an arbitrary-data-frame slicing/recovery framework.

## 验证完成 / Completed validation

- 最终源码提交 / Final package-source commit:
  `80f24e761615a44efc7fe20a848f53682fad192e`.
- 本地实际源码包 `outputs/diagnostic-workflow/artifacts/cncleanr_0.2.13.tar.gz`：
  Windows 11 x64、R 4.6.1、已有 UCRT GCC 15.2，
  `R CMD check --as-cran --no-manual` 为 `Status: OK`，退出码 0，
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 784`。本地未检查 PDF 或远程 incoming。
- [五平台 CI 38394574094](https://github.com/Jorungandr/cncleanr/actions/runs/38394574094)：
  全部 `Status: OK`、每项 784 个断言，Linux release PDF/HTML 手册均 OK。
- [R-hub 38394591090](https://github.com/Jorungandr/cncleanr/actions/runs/38394591090)：
  clang-ASAN、clang-UBSAN、Valgrind 全部 OK、每项 784 个断言。
  已读取实际日志；Valgrind 的示例、基础回归和 testthat 摘要均为
  `0 errors from 0 contexts`，definitely/indirectly/possibly lost 均为 0 字节。
  C 源码未改动，但本轮错误处理和原生调用路径仍重新检查，未借用历史结论。
- 九份保留快照哈希仍一致；当前安装包的财报、多来源、跨领域审计全部通过。
  财报 1,412 个有效片段正确、六个错误片段拒绝；科研 377 个单值、37 个区间，
  企鹅 2,029 个测量值和 35 个缺失值正确；跨领域无错误接受，692 个派生区间正确。
  未新增数据来源。100,000 混合值压力、20,000 不同数值和 CSV 往返通过。

Local exact-archive check, all five platforms and all three native tools passed
784 assertions without test failures/warnings/skips. PDF/HTML were checked by
Linux CI, not locally. Retained datasets and batch/CSV checks passed; these are
rechecks of recorded snapshots, not new data acquisition or universal guarantees.
Encoding conditions still inherit `simpleError`; localization does not swallow
unrelated errors as if they were encoding failures.

## 发布与附件 / Publication and asset

[GitHub v0.2.13](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.13)
固定标签指向上面的已检查提交，旧标签和附件未修改。
正式附件大小为 44,278 字节，SHA-256：

```text
5277308A76AF8E80AFDC6D4BAD1B5A26A1B009DF3E9F7750D987A846565E6752
```

GitHub digest、发布后重新下载文件与实际已检查文件的哈希完全一致。
独立库 `outputs/diagnostic-workflow/public-library/` 安装成功，
`docs/verify-release.R` 核对源码内容、版本及诊断示例通过；下载包安装后的
完整 784 个断言与基础回归也通过。验收记录的后续修改不进入包附件。
本次未提交 CRAN，草稿不代表已完成 win-builder/incoming 预检查。

Published at the immutable checked tag. Public asset digest/download SHA-256
matches the checked archive; isolated installation, source/version verification,
workflow example, 784 assertions and dependency-free regression passed.
No existing tags/assets were changed and no CRAN upload was made.
