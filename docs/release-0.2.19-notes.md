# cncleanr 0.2.19

新增 `cn_summary(result)`：返回总数、成功、缺失、失败数量与失败原因频数，
支持三个解析器及 `cn_subset()` 的结果，重复行按出现次数计数。
不重新解析原文，无新增依赖，不修改 C 或解析器。
请在普通筛选、修改、合并或 CSV 导出前汇总；已丢失的诊断不能自动恢复。

Adds `cn_summary(result)`: ordinary `counts` and `reasons` tables summarizing
parsed, missing and failed rows plus reason frequencies. Supports all three
parsers and `cn_subset()`, including repeated selections, without reparsing.
No new dependencies, C or parser changes. Summarize before ordinary subsetting,
mutation, binding or CSV export; lost diagnostic provenance cannot be recovered.

Includes workflow/RDS regressions and literal bilingual README execution added
after 0.2.18. Existing tags/assets remain unchanged. No CRAN submission.
