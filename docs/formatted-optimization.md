# Formatted numbers / 格式化数值优化

2026-10-10, unreleased development branch. No public API or grammar change.
The conservative C path now handles existing `RMB`/`CNY` (case-insensitive),
yen-symbol and Chinese renminbi prefixes, and accounting parentheses. Explicit
signs inside accounting parentheses, multiple signs and currency percentages
still fall back to the existing R validator for their original errors.

Unresolved text uses the existing character and whitespace normalization, then
tries the same native parser again. Invalid digit grouping and normalized
missing markers are checked before accepting a normalized native result.
Unsupported formats retain the complete R path. No additional dependency,
thread, parser buffer or independent C package is introduced.

开发版优化既有货币前缀、括号负数、全角数字及空白格式。
仍先验证数字空白分组与缺失标记，不会将 `1 23` 清理后误接受为 `123`。
括号内显式符号、重复符号、货币百分比等错误仍保持原来的原因和行号。

## Local measurements / 本地计时

Windows, R 4.6.1, UCRT GCC 15.2. Baseline: unchanged installed mixed-stage
parser at `outputs/mixed-optimization/library`. Candidate: byte-compiled
working-tree R code with the freshly compiled candidate DLL. Each sample has
100000 rows; values are prepared before timing. Three runs of five calls each,
median elapsed time divided by five; no I/O. The grouped sample deliberately
includes invalid groupings when the first group exceeds three digits.

| Input / 输入 | Before / 优化前 | After / 优化后 |
| --- | ---: | ---: |
| Plain / 普通数值 | 0.008 s | 0.006 s |
| `RMB…万` | 0.166 s | 0.006 s |
| `RMB … 万` | 0.170 s | 0.080 s |
| `(RMB…元)` | 0.208 s | 0.006 s |
| Full-width digits / 全角数字 | 0.140 s | 0.062 s |
| Mixed whitespace grouping / 混合空白分组 | 0.174 s | 0.182 s |
| Invalid / 全无效值 | 0.070 s | 0.076 s |

Measurements are not latency guarantees. Currency, accounting and full-width
samples improved; grouped and invalid samples did not. Do not combine this
run with earlier reports to compute speedups. Not every format or million-row
batch meets a 0.1-second target.

部分格式的十万条样本达到 0.1 秒以内，不代表所有格式或百万条批次均达到。
空白分组和全无效样本此轮略慢；不宣称统一提速。

## Reproduce / 复现

```powershell
./docs/run-r.ps1 -RArguments @('--vanilla', 'docs/formatted-performance.R', 'outputs/mixed-optimization/library', 'outputs/formatted-optimization/library')
```

The differential grid covers 1800 prefix/body/suffix combinations, malformed
short prefixes, signs, parentheses, scientific extremes, whitespace and Unicode.
All three parsers, factors, names, custom missing markers, header units and
strict messages match the unchanged baseline. Direct native regression tests
disable native calls in a local reference function, preventing false acceptance
from being hidden by the new second native pass.

差异检查覆盖 1800 种格式组合；新增回归明确检查符号限制、负零、
数字分组及缺失优先级，并以禁用 C 的本地参考函数检验原 R 语义。

The rebuilt package passed `R CMD check --as-cran --no-manual` with `Status: OK`,
exit code 0 and `FAIL 0 | WARN 0 | SKIP 0 | PASS 298`. PDF manual and remote
incoming checks were not run. Logs: `outputs/formatted-optimization/cncleanr.Rcheck/`.
Existing batch stability, broad/multi-source audits and CSV checks exited 0
using the independently installed candidate. A forced-GC stress process also
passed; its deliberately unsupported cell emitted the expected parsing warning.
整包检查及 298 项断言通过；既有公开数据、压力、CSV 和强制内存回收验证通过。
不是新增数据覆盖量，也不宣称已完成 PDF 手册或远程预提交检查。

## 2026-10-11 follow-up / 后续开销削减

Native retry now only visits changed, non-missing text with valid digit grouping.
Known grouping errors are replaced with an empty temporary work string before
syntax matching; the original input and grouping error take precedence in the
problem report. The C routine and public syntax are unchanged.
仅对标准化后有变化且分组有效的文本重试 C；已知分组错误不再做完整语法匹配。
原文仍保留用于问题报告，缺失标记优先于分组错误。

Reused `formatted-performance.R` with the unchanged formatted-stage library as
both baseline and DLL source. The candidate is current byte-compiled R code;
the DLL is unchanged. Same 100000-row, three-by-five-call method, no I/O:

| Input / 输入 | Before / 优化前 | After / 优化后 |
| --- | ---: | ---: |
| Plain / 普通数值 | 0.018 s | 0.018 s |
| Currency / 货币前缀 | 0.016 s | 0.016 s |
| Spaced currency / 带空白货币前缀 | 0.156 s | 0.150 s |
| Accounting / 括号负数 | 0.016 s | 0.018 s |
| Full-width / 全角数字 | 0.124 s | 0.132 s |
| Mixed grouping / 混合空白分组 | 0.394 s | 0.338 s |
| Invalid / 全无效 | 0.178 s | 0.176 s |

The grouping sample improved modestly; other samples were flat or fluctuated,
and full-width text regressed slightly. Absolute times vary substantially with
machine load; do not compare this table directly with the previous day's times.
The full differential grid and all three parsers still match the baseline.
本轮收益有限，不是整体提速，也未达到分组文本 0.1 秒的目标。

The final independent package check passed with `Status: OK`, exit code 0 and
`FAIL 0 | WARN 0 | SKIP 0 | PASS 304`. Logs:
`outputs/retry-optimization/final-check/cncleanr.Rcheck/`.
PDF manual and remote incoming checks were not run. The existing open-data,
batch and CSV checks also passed using the independently installed candidate.
An earlier redundant check was stopped; only this completed final check is
used as evidence. The archive was verified to contain the new retry logic and
long-invalid-grouping regression.
最终独立整包检查及 304 项断言通过；公开数据、批量和 CSV 验证通过。
本轮未检查 PDF 手册及远程 incoming，没有新增公开数据覆盖量。

### Grouping-error filtering / 分组错误过滤

Further work removes known grouping failures from the regex capture and numeric
conversion vectors altogether, instead of substituting empty strings. Their
original indices and reasons merge with syntax failures in source order. Sorting
is only needed when both kinds of failure occur. The all-grouping-failure case
is covered explicitly, as are mixed errors and strict first-error precedence.
已知分组错误行不再进入捕获或数值转换，只在最终报告中与其他错误按原行号合并。
全部行分组错误、错误交错顺序及严格模式的首条原因均有回归测试。

Reused the same three-by-five-call benchmark, with the unchanged retry-stage
library as baseline and DLL source. Candidate: current byte-compiled R code.
No C change or new dependency. Final local 100000-row measurements:

| Input / 输入 | Before / 优化前 | After / 优化后 |
| --- | ---: | ---: |
| Plain / 普通数值 | 0.006 s | 0.006 s |
| Currency / 货币前缀 | 0.008 s | 0.006 s |
| Spaced currency / 带空白货币前缀 | 0.174 s | 0.218 s |
| Accounting / 括号负数 | 0.018 s | 0.020 s |
| Full-width / 全角数字 | 0.148 s | 0.148 s |
| Mixed grouping / 混合空白分组 | 0.354 s | 0.186 s |
| Invalid / 全无效 | 0.228 s | 0.222 s |

The grouping sample improved about 47%; invalid text was essentially flat.
Other samples fluctuated, including slower spaced-currency timing despite not
reaching the changed grouping-filter path. These are measurements, not guarantees,
and should not be combined with previous tables to calculate speedups.
分组样本约改善 47%，但仍未达到 0.1 秒。其他样本存在波动，不能保证统一提速。
The complete formatted differential grid and all three parsers match the baseline.

Final verification: `Status: OK`, process exit 0,
`FAIL 0 | WARN 0 | SKIP 0 | PASS 312`. Existing open-data, batch and CSV checks
also passed against the final check-installed package. Logs:
`outputs/grouping-filter/final-check/cncleanr.Rcheck/`.
The first check was interrupted during a slow repository lookup; the completed
rerun limited network request timeout to 10 seconds and still reported a CRAN
index download warning. No package tests were skipped. PDF manual and remote
incoming checks were not run; this is not a completed online CRAN pretest.
最终整包检查及 312 项断言通过，公开数据、压力和 CSV 验证正常退出。
网络索引查询有提示，未检查 PDF 手册和远程 incoming。

### Paired large-batch verification / 交替计时与百万条验证 (2026-10-11)

The existing benchmark now accepts a third argument for row count. Five paired
trials alternate baseline/candidate execution order; each trial averages five
calls below one million rows and one call at one million rows or above. Tables
report the median per-call elapsed time, excluding data preparation and file I/O.
Baseline: the formatted-stage installed library (`1c974e2`); candidate: current
byte-compiled R source (`de7fc09`) with the final check-installed DLL. This round
changes measurement only, not parser algorithms. Earlier tables retain their
original methodology and should not be combined with these timings.
现有脚本支持第三个参数指定行数，五轮交替新旧执行顺序，报告单次耗时中位数。
本轮只改进测量，没有修改解析算法；数据准备和文件读写不计入耗时。

| Input / 输入 | 100k baseline / 基线 | 100k candidate / 当前 | 1m baseline / 基线 | 1m candidate / 当前 |
| --- | ---: | ---: | ---: | ---: |
| Plain / 普通数值 | 0.010 s | 0.008 s | 0.09 s | 0.10 s |
| Currency / 货币前缀 | 0.010 s | 0.010 s | 0.10 s | 0.10 s |
| Spaced currency / 带空白货币前缀 | 0.172 s | 0.202 s | 1.00 s | 1.01 s |
| Accounting / 括号负数 | 0.018 s | 0.018 s | 0.10 s | 0.08 s |
| Full-width / 全角数字 | 0.078 s | 0.158 s | 0.80 s | 0.80 s |
| Mixed grouping / 混合空白分组 | 0.200 s | 0.086 s | 5.38 s | 1.98 s |
| Invalid / 全无效 | 0.082 s | 0.082 s | 1.71 s | 1.77 s |

The million-row grouping sample improved about 63%, but remains far above
0.1 seconds. The 100k full-width sample regressed in this run, while the
million-row full-width sample was flat. This discrepancy needs investigation,
not a blanket speedup claim. These local timings are not latency guarantees.
百万条分组样本约改善 63%，仍未达到 0.1 秒；十万条全角样本本次明显退步，
百万条全角样本则持平，后续需继续排查，不能据此承诺所有格式统一提速。

Both sizes passed exact baseline/candidate comparisons, including the formatted
grid, all three parsers, header units, custom missing markers and strict error
messages. Zero rows are rejected before library loading. No new full package
check was run for this benchmark-only change; the preceding 312-assertion check
remains the package-check evidence.
两种规模的差异验证均通过，非法行数 0 被拒绝。本轮未重新运行整包检查。

```powershell
./docs/run-r.ps1 -RArguments @('--vanilla', 'docs/formatted-performance.R',
  'outputs/formatted-optimization/library',
  'outputs/grouping-filter/final-check/cncleanr.Rcheck', '1000000')
```

The paths above refer to local retained build snapshots; use your own installed
baseline and candidate library paths elsewhere. Candidate R files are sourced
from the current working tree.
以上路径是本地保留的构建快照，其他环境需替换为自己的安装库路径；候选 R 代码来自当前工作树。

### Normalization profiling / 规范化采样

Five million-row full-width calls were profiled with `Rprof(interval = 0.01)`
after verifying that every input parsed successfully. In this local sample,
`chartr`, `grepl`, and `gsub` accounted for about 24%, 18%, and 16% of sampled
self time. Sampling percentages are diagnostic, not benchmark guarantees.
百万条全角输入连续调用五次的采样显示，字符转换和正则扫描是主要开销。

The number parser now normalizes custom missing markers only once per call,
reusing them in the fallback. The paired 100k benchmark showed no meaningful
overall speedup: full-width 0.072/0.072 s, spaced currency 0.086/0.086 s,
grouped 0.200/0.206 s, invalid 0.184/0.184 s (baseline/candidate).
仅移除缺失标记的重复规范化；本轮没有测出显著提速，不宣称解决全角瓶颈。

The differential benchmark passed. The complete `tests/testthat` suite also
passed with candidate number-parser source loaded into the retained installed
package namespace (and its existing DLL); this was not a fresh installation
or a new `R CMD check`. Initial harness attempts failed because of locked
namespace bindings and a relative library path after the test runner changed
directory; the corrected absolute-path run exited successfully.
新旧结果对比和完整测试目录通过；使用已有 DLL 与本轮 R 源码，未重新安装或整包检查。

### Native character normalization / C 字符规范化 (2026-10-12)

The shared character helper now calls registered native normalization instead
of separate `chartr` and minus-sign regex passes. Each string is transformed
once; a length prepass sizes one reusable R-managed scratch buffer. Names and
missing values are retained, unrelated UTF-8 bytes pass through, and byte-encoded
inputs are rejected. U+FFFE/U+FFFF are rejected explicitly rather than receiving
the previous platform-specific `chartr` error. Whitespace removal and grouping
validation remain unchanged in R. No dependency or public API was added.
共享字符转换改为 C 扫描，合并全角字符和特殊负号处理；长度预扫描决定可复用缓冲区大小。
保留名称、缺失值及其他 UTF-8 文本，空白清理与分组验证保持原实现。

The paired benchmark compares the retained grouping-filter package against this
candidate, with the new candidate DLL explicitly loaded by the script.

| Input / 输入 | 100k baseline / 基线 | 100k candidate / 当前 | 1m baseline / 基线 | 1m candidate / 当前 |
| --- | ---: | ---: | ---: | ---: |
| Plain / 普通数值 | 0.010 s | 0.010 s | 0.11 s | 0.11 s |
| Currency / 货币前缀 | 0.010 s | 0.010 s | 0.10 s | 0.10 s |
| Spaced currency / 带空白货币前缀 | 0.092 s | 0.076 s | 1.22 s | 1.02 s |
| Accounting / 括号负数 | 0.010 s | 0.008 s | 0.11 s | 0.11 s |
| Full-width / 全角数字 | 0.074 s | 0.054 s | 0.99 s | 0.66 s |
| Mixed grouping / 混合空白分组 | 0.106 s | 0.090 s | 1.60 s | 1.39 s |
| Invalid / 全无效 | 0.092 s | 0.066 s | 1.09 s | 0.86 s |

Million-row full-width input improved about 33% in this run; spaced currency
about 16%. Plain/native-accepted input remained essentially flat. Measurements
exclude input construction and I/O, and are not end-to-end latency guarantees.
百万条全角样本约改善 33%，带空白货币约改善 16%；原生直接接受的普通输入基本持平。

Verification: both differential benchmark sizes passed for all three parsers.
A normalization regression compares the original R transformations across
non-surrogate BMP characters through U+FFFD plus supplementary-plane samples,
mixed text, names, NA, empty and long strings. Type, byte-encoding and
noncharacter rejection are tested. Independent installation and
`R CMD check --as-cran --no-manual` completed with `Status: OK`, exit 0,
`FAIL 0 | WARN 0 | SKIP 0 | PASS 318`. Logs:
`outputs/normalization-c/check/cncleanr.Rcheck/`. PDF manual and remote incoming
checks were not run. An ASCII-prefilter experiment was discarded after slowing
full-width input. Earlier historical scripts require a candidate DLL compatible
with current source; the formatted benchmark was updated to load both symbols.
独立安装、318 项断言及整包检查通过；未检查 PDF 手册和远程 incoming。
