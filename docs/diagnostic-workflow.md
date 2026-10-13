# 诊断工作流与验收 / Diagnostic workflow and validation

2026-10-13，cncleanr 0.2.13 候选。保持原结果类型和编码失败中止策略，
不增加运行时依赖，不提交 CRAN。Candidate retains plain result types and
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
verifier. Complete validation and publication evidence is appended after completion.

Public APIs retain their earlier signatures; `cn_subset` is one additional export.
Encoding messages gain location context; ordinary `cn_problems()` schema/reasons
remain unchanged. This is not an arbitrary-data-frame slicing/recovery framework.
