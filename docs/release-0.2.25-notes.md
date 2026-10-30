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
