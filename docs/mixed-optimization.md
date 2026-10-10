# Mixed numeric batches / 混合数值批次优化

2026-10-10, unreleased development branch. Public API, syntax and C routine are
unchanged. Previously one unsupported cell sent the whole batch through R again.
Now accepted native results are retained; only unresolved rows are normalized
and validated by the complete R parser. Local indices are mapped to source rows
before writing values or constructing problems. Missing markers keep precedence.

开发分支更新：保留 C 已完成的行，仅对未处理行执行原 R 路径。
没有新增语法、依赖或 C 规则；异常行号、原文、名称和严格错误保持不变。

## Measurements / 计时

Windows, R 4.6.1. Baseline: installed qualifier-stage snapshot at
`outputs/qualifier-optimization/library`. Candidate: byte-compiled working-tree
R code using the same installed DLL. Each sample contains 100000 distinct
number texts before substitutions. Formatted rows get an `RMB ` prefix; invalid
rows become `bad`. Inputs are prepared before timing, with no I/O. Each reported
time is the median of three runs of five calls, divided by five.

| Sample / 样本 | Before / 优化前 | After / 优化后 |
| --- | ---: | ---: |
| All simple / 全部普通数值 | 0.006 s | 0.006 s |
| 1% formatted / 1% 货币前缀 | 0.126 s | 0.010 s |
| 10% formatted / 10% 货币前缀 | 0.272 s | 0.040 s |
| 50% formatted / 50% 货币前缀 | 0.276 s | 0.196 s |
| 100% formatted / 全部货币前缀 | 0.316 s | 0.362 s |
| 1% invalid / 1% 无效值 | 0.288 s | 0.020 s |
| 10% invalid / 10% 无效值 | 0.282 s | 0.028 s |
| 50% invalid / 50% 无效值 | 0.196 s | 0.072 s |
| 100% invalid / 全部无效值 | 0.124 s | 0.156 s |

These are local measurements, not guarantees. Completely unsupported samples
show no benefit and regressed in this run; this change targets mostly-simple
mixed batches, not every complex format. Do not mix measurements across earlier
optimization reports to calculate speedups. Preliminary overlapping benchmark
runs are not used for this table.

主要改善“多数普通数值、少数复杂或异常文本”的批次。
全复杂/全无效样本此轮略慢，不能声称所有输入都提速，也不保证统一低于 0.1 秒。

## Reproduce / 复现

From the repository root, with the unchanged baseline already installed:

```powershell
./docs/run-r.ps1 -RArguments @('--vanilla', 'docs/mixed-performance.R', 'outputs/qualifier-optimization/library')
```

The script compares values, names, complete problem attributes, fixtures,
factors, numeric inputs, custom missing markers, header units and strict messages
for all three parsers before timing. The baseline is a local snapshot, not
redistributed. Formal native tests force the R reference path with whitespace,
so mixed-batch native reuse cannot conceal a false native acceptance.

新回归测试明确核对交错的 C/R 行、原始异常索引、负零和标准化缺失标记。
公开数据审计使用既有样本复跑，不算新增数据来源或覆盖量。

The rebuilt package passed `R CMD check --as-cran --no-manual` with `Status: OK`
and exit code 0: `FAIL 0 | WARN 0 | SKIP 0 | PASS 288`. PDF manual and remote
incoming checks were not run. Logs: `outputs/mixed-optimization/cncleanr.Rcheck/`.
Batch stability, broad/multi-source audits and CSV round-trip processes also
exited 0 using the independently installed candidate library.
整包检查及 288 项断言通过，进程正常退出；未检查 PDF 手册和远程 incoming。

The qualifier differential script also matched all values, qualifiers, names,
errors and custom missing markers. Its 100000-cell quantity samples with 1%
and 10% invalid rows measured 0.57 → 0.37 s and 0.54 → 0.25 s respectively.
All-formatted quantities measured 0.80 → 0.86 s; again, gains are not universal.
限定词差异检查也通过；少量无效行的数量批次同样受益，全复杂数量此轮略慢。
