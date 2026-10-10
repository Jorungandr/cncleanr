# Qualifier optimization / 限定词优化

2026-10-10, unreleased development branch. No public API or grammar change.
开发分支更新，不改变公开接口、支持语法或错误优先级。

Profiling the native-stage quantity parser identified regex matching and
character normalization as the main remaining work. Prefix/suffix rule groups
are mutually exclusive, so each group is now matched once; captured lengths
are reused for stripping instead of repeating each regex. The infix “余” and
conflict/redundant-approximation rules are unchanged.

All three parsers now reuse normalized characters between text cleaning and
digit-spacing checks. The expensive grouping check only scans texts actually
containing whitespace between digits. Missing markers still take precedence.
三个解析器共用标准化结果；只对数字之间有空白的文本检查分组。
没有增加 C 规则，也没有削减错误检测。

## Measurements / 计时

Windows, R 4.6.1. Baseline: unchanged installed native-stage parser
(`outputs/native-optimization/library`). Candidate: byte-compiled working-tree
code, using the same C routine. Inputs are prepared before timing, no I/O;
three runs, median elapsed seconds per 100,000-cell call. Repeated-input calls
are aggregated ten times per run to avoid timer-resolution artifacts.

| Sample / 样本 | Unique texts / 不同原文 | Before / 优化前 | After / 优化后 |
| --- | ---: | ---: | ---: |
| Approximation / 约…万 | 100000 | 0.22 s | 0.16 s |
| Mixed inequalities / 多种不等式 | 100000 | 0.47 s | 0.30 s |
| Mixed suffixes / 多种后缀 | 100000 | 0.47 s | 0.31 s |
| Currency with approximation / 约 RMB … 万元左右 | 100000 | 1.26 s | 0.82 s |
| Repeated inputs / 高重复 | 100 | 0.008 s | 0.009 s |
| 1% invalid / 1% 异常值 | 99002 | 0.71 s | 0.56 s |
| 10% invalid / 10% 异常值 | 90002 | 0.61 s | 0.65 s |

High-repetition parsing already benefits from deduplication and shows no gain.
The 10%-invalid sample fluctuated: five additional paired runs in a separate
process gave medians of 0.33 s before and 0.28 s after. Both measurements are
reported rather than claiming every input becomes faster. Timing varies with
system load and garbage collection; the 0.1-second quantity target is not met.
高重复样本基本不变；10% 异常样本单独复测有所改善，但不能保证固定提速。
此轮数量解析尚未达到 0.1 秒；不要与其他轮次的计时混用计算提速比例。

## Verification / 验证

Run `Rscript docs/qualifier-performance.R [baseline-library]` from the repository
root. The baseline is a local snapshot, not redistributed. Differential checks
cover every supported qualifier synonym, repeated/conflicting tokens, Unicode
grouping, factors, names, fixtures, custom missing values, strict errors, header
units and complete problem attributes across all three parsers.

Batch stability, existing broad/multi-source open-data audits and CSV round-trip
checks passed in independent processes with exit code 0. The Unicode capture
regression also passed against explicit expected values. Existing full testthat
assertions passed, but the process exited with the pre-existing access violation;
this is not recorded as a successful full local check.
差异检查、公开数据审计、压力测试及 CSV 验证通过；本机完整测试退出异常
当时尚未解决，不算完整检查通过。新的 Unicode 回归检查也纳入远程测试。

Follow-up: the shutdown environment issue is resolved via `docs/run-r.ps1`;
see [diagnosis](environment-diagnosis.md). The
[qualifier-stage CI](https://github.com/Jorungandr/cncleanr/actions/runs/38031781519)
passed all five platforms. Existing open-data audits, batch stress and CSV
round-trip checks were rerun on the current installed parser with exit code 0.
本机退出问题已解决；限定词优化的五平台检查均通过。
已复跑公开数据、压力及 CSV 验证；没有新增数据来源，也不重复计算覆盖量。
