# cncleanr 0.2.16

## 中文

修复 `cn_subset()` 对带类数值下标的处理：先调用一次 `as.double()`，再校验和
筛选，避免 integer64 下标静默产生空结果或不存在的缺失行。诊断仍随重排、重复和
负下标同步。拒绝异常转换结果、缺失、非整数和越界下标。普通下标和解析算法不变。
集中增加 S3 回归和系统一致性审计；bit64 仅为本地可选检查，不增加包依赖。
双语说明同步。仅发布 GitHub，不提交 CRAN。

## English

Converts classed numeric `cn_subset()` indices once before validation and slicing,
preventing silent empty selections or manufactured rows for integer64 selectors.
Diagnostics follow reordering, duplicates and exclusions. Malformed conversions,
missing, fractional and oversized indices are rejected. Ordinary selectors and
parser algorithms remain unchanged. Adds S3 regressions and a reproducible system
audit with optional local bit64 checks, no new dependency or C changes.
GitHub only; no CRAN submission.

[Audit evidence and limits](https://github.com/Jorungandr/cncleanr/blob/main/docs/system-audit.md).
