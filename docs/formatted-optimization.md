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
