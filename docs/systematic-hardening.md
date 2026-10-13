# 系统整改与发布验收 / Systematic hardening and release validation

2026-10-13，候选版本 0.2.12。集中完成已批准的正确性与工程整改；
没有新增语法、运行时依赖、第二套解析包，也没有 CRAN 提交。
Candidate 0.2.12 consolidates the approved audit fixes, without new syntax,
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

Final source archive check, platform CI, native tools and public asset verification
are recorded below only after completion. Historical native results are not reused
as fresh evidence. PDF/incoming checks unavailable locally are not claimed.

## 留存限制 / Retained limits

Double rounding above `2^53`; extract problems before transforming results;
malformed UTF-8 stops the batch; textual missing matching, matrix flattening and
accounting suffix policy are unchanged. Fixed dataset hashes may not be retrievable
from dynamic APIs later. Action SHA pinning and certification of every older R /
locale are not claimed. CRAN draft remains explicitly unsubmitted.
