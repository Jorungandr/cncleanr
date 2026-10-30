# cncleanr 0.2.25

新增可重复的随机组合回归测试：3000 个数值、3000 个限定数量、3000
个括号区间，独立算术预期按每个元素核对；4096 行混合输入在七种表头设置
下对比原生 C 与完整 R 回退的数值、负零、名称及诊断。
三个解析器均覆盖重复筛选、再次倒序筛选和汇总计数。随机状态运行后恢复。

Adds reproducible fixed-seed tests for 3000 scalar values, 3000 qualified
quantities and 3000 accounting intervals against independent per-cell arithmetic
expectations. A 4096-row mixed batch compares complete native-enabled and R-only
results under seven header settings, including names, signed zero and diagnostics.
All three parsers test repeated selection, reversal and independent summary counts.
The tests restore RNG state and do not add runtime work or dependencies.

No confirmed new parser defect was reproduced in this batch. Production R/C
algorithms, supported grammar and six public interfaces are unchanged. Finite
tests do not establish the absence of every possible defect. No CRAN submission.

验证：最终提交的五平台 CI 均为 Status OK，各通过 1832 项断言；Ubuntu
release 的 PDF 手册通过。公开附件校验和一致，重新编译安装后的完整测试
也通过。本地最终检查有 1 个远程时间校验不可用的 NOTE，0 errors / 0 warnings。

Validation: final-source CI has Status OK and 1832 passing assertions on all five
platform jobs, including the Ubuntu release PDF manual check. The public asset's
SHA256 matches; independent compilation/installation and all 1832 assertions
passed. Final local check: 0 errors, 0 warnings, 1 NOTE for unavailable remote
clock verification. No new sanitizer or speedup claim.

SHA256: `5cac55025b15ce3ee1afcd0d86160247309cb1809600d05c1f4f7e092beedae6`
