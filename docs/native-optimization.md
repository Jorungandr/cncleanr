# C fast path / C 加速路径

2026-10-10. Development branch only; not included in the released 0.2.7 or
CRAN 0.2.5. There is still one package and one public R interface.
仅开发分支包含此改动，不属于正式版；仍维护一个包、一套公开 R 接口。

`src/simple-number.c` recognizes complete simple decimal/scientific numbers,
optional signs, common Chinese magnitudes, yuan suffixes and percentages.
It uses R's numeric conversion API, rejects non-finite results and contradictory
units, and does not modify input vectors. Native routines are registered and
dynamic symbol lookup is disabled. Garbage-collection stress testing passed.

Only entirely supported batches (including recognized missing markers) return
early. Currency prefixes, accounting parentheses, grouped digits, full-width
characters, malformed values and other unsupported forms retain the complete
R parser. This deliberately avoids a second error-remapping implementation.
Syntax, custom missing markers, names, units and error reporting remain unchanged.

常见数值整批通过 C 校验时直接返回；其他批次继续使用完整 R 解析器。
没有删除复杂格式支持，也没有把不认识的输入当成合法值。
自定义缺失标记、表头单位、名称及错误信息保持原有语义。

## Local measurements / 本地计时

Windows, R 4.6.1, GCC 15.2 UCRT. Baseline is the unchanged pure-R numeric
vectorization snapshot. Inputs are prepared before timing; medians of three
runs, elapsed time only. Fast 100,000-number calls are aggregated 20 times
per run to avoid timer-resolution zero. No file I/O is included.

| Input / 输入 | R baseline / 原 R 实现 | C fast path / C 加速 |
| --- | ---: | ---: |
| 100,000 distinct numbers / 十万条不同数值 | 0.352 s | 0.018 s |
| 1,000,000 distinct numbers / 百万条不同数值 | 3.93 s | 0.18 s |
| 100,000 distinct approximate quantities / 十万条不同的“约…万” | 0.80 s | 0.39 s |

These are measurements, not latency guarantees. Qualifier matching and range
construction remain in R; the 0.1-second target is met for this common-number
sample, not for every parser or input format. Mixed unsupported batches may
not benefit. System load and allocation/collection affect timing substantially.
0.1 秒只在此常见数值样本上达到，不代表数量、区间及所有格式都达到。
本轮计时与此前不同轮次的计时不能混用计算提速比例。

## Verification / 验证

`docs/native-performance.R` compares fixtures, factors, numeric inputs, names,
custom missing markers, header units, random finite values and complete error
attributes with the unchanged R baseline. Direct accepted-cell checks prevent
whole-batch fallback from hiding invalid native acceptance. The same direct
checks are included in `tests/testthat/test-native-fast-path.R` for CI.

At the native-stage commit, local installation, batch stability, broad-data audit, multi-source audit and
CSV round-trip checks passed. All local testthat assertions passed, but its
process still exited with the pre-existing `0xc0000005` issue; this is not
recorded as a successful full local check. The independent native benchmark
and garbage-collection stress process exit status are checked separately.

本地安装、压力测试、公开数据审计和 CSV 验证通过；完整测试断言通过，
当时测试依赖相关的本机退出异常尚未解决，不算完整检查通过。

Follow-up: the missing Windows architecture variable was identified and supplied
by `docs/run-r.ps1`. The full local check now exits cleanly (no PDF manual or
remote incoming checks). All five jobs of the
[fix CI run](https://github.com/Jorungandr/cncleanr/actions/runs/38032567982)
passed. See [environment diagnosis](environment-diagnosis.md).
退出异常已通过本地启动入口的环境修复解决，五平台检查通过；未修改解析算法。

The native regression suite additionally compares 810 scientific-number/unit
cases across six header-unit configurations, including overflow, underflow,
subnormal values and signed zero. Accepted native values, their reciprocals
and complete fast-path batches must agree exactly with the full R fallback.
新增浮点边界回归覆盖 810 种科学计数法/单位组合及六种表头配置，
核对上溢、下溢、极小值和负零；不会把混合批次自动回退误当成 C 解析正确。

Source installation now requires a C compiler. Windows local verification used
the already installed UCRT GCC through a task-local Makevars file; it did not
install Rtools or alter user/system compiler configuration. For ordinary Windows
source installation, use the matching official Rtools. No new R dependency,
threading library or independent C package is introduced.
