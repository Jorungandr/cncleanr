# Performance closeout / 性能优化收尾

2026-10-12. This closes the current performance-optimization campaign; future
maintenance prioritizes correctness, compatibility and real bug reports rather
than continuing speculative speed tuning. One R package and public interface
are retained, with registered native numeric/normalization routines.
本轮结束持续性能调优，后续以正确性、兼容性和真实问题维护为主。
仍维护一个 R 包，常用数值和规范化由注册的 C 函数加速。

## Final changes / 收尾改动

- Large unresolved numeric batches sample the first 256 cells for repetition.
  Only batches of at least 1000 cells with sampled duplication attempt full
  deduplication, and only those with fewer than half as many unique values use
  it. Results and complete diagnostics map back to original rows and names.
- Grouping validation uses possessive quantifiers where backtracking cannot
  change the accepted language. Invalid grouping is still rejected before
  whitespace removal. 30000 randomized comparisons matched the previous rule.
- The existing benchmark now covers distinct invalid values, repeated formatted
  values, mixed errors, quantity parsing and range parsing. It accepts row count
  and parser kind instead of introducing another benchmark framework.
- Single-separator closed ranges split and propagate endpoint suffixes in
  vectors. Endpoint results use a two-column matrix; valid-candidate counts use
  `tabulate` instead of per-source lists. Complex signed/scientific separator
  cases still enumerate candidates and apply the same validity/ambiguity rules.
- Obvious positive-decimal closed ranges go directly to endpoint validation
  instead of first constructing a failed quantity parse. Scientific point values
  and qualified bounds still use the quantity path; endpoints always undergo
  the full number parser.

大批量未解析文本仅在有明显重复时去重，恢复全部原始行号、名称和错误报告。
分组正则减少不必要回溯，随机差异检查通过；基准覆盖三种解析函数和不同重复率。
闭区间增加批量切分、单位传播和候选统计，复杂分隔符仍遵循原有判定规则。

## Measurement / 测量

Baseline is the retained pre-closeout source package (`0634370`), installed at
`outputs/syntax-filter/check/cncleanr.Rcheck/`. Candidate is the final working
tree, byte-compiled by the benchmark, with the unchanged native DLL. Windows,
R 4.6.1. Five alternating paired trials; median seconds per call. Each 100k
trial averages five calls; each million-row trial uses one call. Input generation
and file I/O are excluded. Benchmarks run sequentially after checks/audits.
Do not combine earlier stage timings into an overall speedup ratio.
基准串行运行，报告同轮新旧耗时中位数，不含数据构造和文件读写。

Initial 100k closeout results (seconds per call):

| Number input / 数字输入 | Before / 收尾前 | Final / 收尾后 |
| --- | ---: | ---: |
| Plain / 普通数值 | 0.014 | 0.016 |
| Currency / 常规货币 | 0.018 | 0.018 |
| Spaced currency / 带空白货币 | 0.124 | 0.122 |
| Accounting / 括号负数 | 0.018 | 0.018 |
| Full-width / 全角数字 | 0.134 | 0.128 |
| Grouped / 分组文本 | 0.160 | 0.166 |
| Repeated invalid / 重复无效文本 | 0.078 | 0.022 |
| Distinct invalid / 不同无效文本 | 0.110 | 0.108 |
| Repeated formatted / 重复格式文本 | 0.068 | 0.022 |
| Mixed errors / 重复混合错误 | 0.108 | 0.030 |

The repeated fallback cases improved; distinct data remained essentially flat,
including a slightly slower grouped sample. These results do not justify a
universal speedup claim. Conditional deduplication deliberately skips unique
sample prefixes to avoid adding a full uniqueness scan to common distinct data.
重复回退样本受益，不同值基本持平，分组本次略慢；没有统一提速保证。

Final million-row numeric rerun, completed with exit 0:

| Number input / 数字输入 | Before / 收尾前 | Final / 收尾后 |
| --- | ---: | ---: |
| Plain / 普通数值 | 0.20 | 0.21 |
| Currency / 常规货币 | 0.20 | 0.22 |
| Spaced currency / 带空白货币 | 1.60 | 1.58 |
| Accounting / 括号负数 | 0.22 | 0.20 |
| Full-width / 全角数字 | 1.56 | 1.57 |
| Grouped / 分组文本 | 2.11 | 2.16 |
| Repeated invalid / 重复无效文本 | 0.88 | 0.16 |
| Distinct invalid / 不同无效文本 | 1.42 | 1.42 |
| Repeated formatted / 重复格式文本 | 0.59 | 0.16 |
| Mixed errors / 重复混合错误 | 1.28 | 0.22 |

An earlier million-row run printed completed results but exited with a script
read/parse error after the benchmark file was edited during execution. It is
excluded; the table above comes from the fixed-script rerun. High-repetition
samples improved about 73–83%; distinct formats did not improve materially.
百万条采用固定脚本正常退出的复跑结果；运行中编辑脚本引发错误的先前结果不计入。
高重复样本约改善 73–83%，不同值及分组文本没有明显改善。

Quantity measurements (seconds per call), all exact comparisons passed:

| Quantity input / 数量输入 | 100k before / 前 | 100k final / 后 | 1m before / 前 | 1m final / 后 |
| --- | ---: | ---: | ---: | ---: |
| Distinct approximate / 不同近似数量 | 0.340 | 0.350 | 4.44 | 4.59 |
| Repeated approximate / 重复近似数量 | 0.010 | 0.010 | 0.07 | 0.07 |
| Distinct invalid / 不同无效文本 | 0.284 | 0.280 | 3.37 | 3.42 |

The quantity parser already deduplicates raw text; its repeated path was not
sped up by this numeric-fallback change. Distinct quantities retain R qualifier
matching and output construction costs and were flat/slightly slower here.
数量函数原本已去重，重复值路径本次持平；不同值仍承担限定词匹配和输出构造成本。

Intermediate vectorized-range measurements (seconds per call, before bypassing
the redundant quantity parse):

| Range input / 区间输入 | Rows / 行数 | Before / 收尾前 | Vectorized / 批量阶段 |
| --- | ---: | ---: | ---: |
| Distinct closed / 不同闭区间 | 10000 | 0.894 | 0.092 |
| Repeated closed / 重复闭区间 | 10000 | 0.012 | 0.012 |
| Distinct invalid / 不同无效文本 | 10000 | 0.070 | 0.038 |
| Distinct closed / 不同闭区间 | 100000 | NA | 1.100 |
| Repeated closed / 重复闭区间 | 100000 | 0.082 | 0.080 |
| Distinct invalid / 不同无效文本 | 100000 | 0.866 | 0.426 |
| Distinct closed / 不同闭区间 | 1000000 | NA | 12.710 |
| Repeated closed / 重复闭区间 | 1000000 | 0.950 | 0.960 |
| Distinct invalid / 不同无效文本 | 1000000 | 7.490 | 2.670 |

The paired 10k closed-range sample improved about 9.7-fold. The 100k invalid
range sample improved about 51%. These are within-run comparisons, not a
guarantee across arbitrary formats. Signed/scientific/multi-separator grids and
strict diagnostics matched the old parser under three missing-marker settings.
万条闭区间同轮约提速 9.7 倍；十万条不同无效区间约改善 51%。
符号、科学计数法、多分隔符及三组缺失标记的差异验证通过。

Frozen range results after bypassing the redundant quantity parse:

| Range input / 区间输入 | Rows / 行数 | Before / 收尾前 | Frozen / 最终 |
| --- | ---: | ---: | ---: |
| Distinct closed / 不同闭区间 | 10000 | 0.762 | 0.034 |
| Repeated closed / 重复闭区间 | 10000 | 0.012 | 0.010 |
| Distinct invalid / 不同无效文本 | 10000 | 0.062 | 0.032 |
| Distinct closed / 不同闭区间 | 100000 | NA | 0.502 |
| Repeated closed / 重复闭区间 | 100000 | 0.094 | 0.088 |
| Distinct invalid / 不同无效文本 | 100000 | 0.962 | 0.454 |
| Distinct closed / 不同闭区间 | 1000000 | NA | 7.110 |
| Repeated closed / 重复闭区间 | 1000000 | 1.020 | 1.000 |
| Distinct invalid / 不同无效文本 | 1000000 | 11.190 | 4.970 |

The frozen 10k distinct closed-range sample improved about 22-fold in its
paired run. Candidate-only large-row times cannot establish a million-row
speedup ratio. Numeric/quantity tables above were measured before this final
range-only change; their implementations and DLL did not change afterward.
最终万条闭区间同轮约提速 22 倍；大批量闭区间仅计候选版，不能计算百万条提速倍数。
数字和数量表在最终区间专属改动前测量，之后这两个函数及 DLL 未改变。
All frozen range runs exited 0. Full baseline equivalence was checked for
repeated/invalid samples; distinct large closed-range bounds were independently
verified for every row. Million-row distinct invalid ranges improved about 56%
in the final paired run. Retained logs are under `outputs/performance-final/`.
最终区间计时均正常退出；重复/无效样本完整对比，全部不同闭区间的每行边界独立核对。
百万条不同无效区间同轮约改善 56%，原始日志保留在上述本地输出目录。

## Reproduction / 复现

```powershell
./docs/run-r.ps1 -RArguments @('--vanilla', 'docs/formatted-performance.R',
  'outputs/syntax-filter/check/cncleanr.Rcheck',
  'outputs/performance-final/closeout-check/cncleanr.Rcheck', '1000000', 'number')
```

Use `quantity` or `range` for the other parsers, and `100000` for 100k rows.
Paths refer to local retained installed packages; use your own library paths
elsewhere. The candidate R code is sourced from the current working tree.
可替换解析函数及行数；以上路径为本地快照，其他环境需使用自己的安装库。

## Verification / 验证

The final independent source build/check including vectorized ranges completed
with `Status: OK`, exit 0, `FAIL 0 | WARN 0 | SKIP 0 | PASS 339`. Logs:
`outputs/performance-final/closeout-check/cncleanr.Rcheck/`. Existing broad-data and
multi-source audits, 100k mixed-cell batch checks and CSV round trips passed.
This reruns retained public-data samples, not new source coverage. Spacing-rule
fuzzing matched 30000 cases. Nine named repeated-batch configurations matched
the pre-closeout parser exactly across header units, custom missing markers,
full problem attributes and strict messages.
独立整包检查、339 项断言、已有公开数据审计、批量及 CSV 验证通过。
随机分组和九组具名重复数据配置的差异验证通过；没有宣称新增公开数据来源。

The first check failed because a new test incorrectly assumed custom `na`
retained the default dash marker. Its expectation was corrected to explicitly
include `-`; the final independent check passed. CRAN repository-index download
warnings occurred during dependency discovery. PDF manual and remote incoming
checks were not run; this is not a new online CRAN pretest.
首次检查发现新增测试把自定义缺失标记误当成追加默认标记，修正测试后通过。
CRAN 索引下载有提示；未检查 PDF 手册及远程 incoming。

## Boundaries / 限制

There is no universal 0.1-second guarantee for arbitrary formats, hardware or
batch sizes. Distinct qualified quantities and ranges still require R matching
and data-frame construction. Complete per-row diagnostics cost memory/time
proportional to the number of failed rows. No diagnostic truncation, hidden
parallelism, external cache or second implementation/package was added.
不能承诺任意数据、硬件和行数统一低于 0.1 秒；完整错误报告仍有与失败行数成正比的成本。
数量和区间仍需要 R 层规则匹配及结果构造，没有截断报告或新增第二套包。

The original large closed-range benchmark was stopped before reporting results
because its scalar baseline was too slow to repeat dozens of times. The final
benchmark pairs old/new timings at 10k rows. For 100k/million distinct closed
ranges it compares the first 10k against the old parser, verifies every candidate
bound against independent expectations, and times the candidate only. A missing
large-baseline timing is reported as `NA`, not zero or an extrapolated speedup.
原版大批量闭区间计时过慢，已停止且不作为测量成果；最终只在万条做新旧配对计时。
十万条及百万条不同闭区间核对前万条与旧版一致，并独立核对全部上下界，计时只跑候选版。
大规模基线缺失记为 NA，不用零或外推值计算提速倍数。

Prefix sampling is deliberately conservative and may miss repetition appearing
only later in a batch. Signed/scientific multi-separator ranges still use scalar
candidate enumeration; the fast batch path does not cover every valid interval
spelling. These are explicit ceilings, not claims of exhaustive optimality.
前缀采样可能漏掉后段重复值；复杂符号/科学计数法多分隔符仍保留逐项候选枚举。
这是当前维护边界，不声称已经达到所有可能输入的理论最优速度。
