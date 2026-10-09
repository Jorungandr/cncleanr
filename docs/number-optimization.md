# Shared numeric-core optimization / 数值核心优化

2026-10-09, Windows, R 4.6.1. Baseline: the installed quantity-optimization
snapshot; candidate: working-tree code, byte-compiled like an installed package.
Inputs are prepared outside the timer. Three runs, median elapsed seconds;
100,000 cells per call. No file I/O is included.

输入在计时前生成，每项运行三次取中位数；不包含文件读写。
旧版为上一轮数量优化后的快照，新版使用同样的字节编译方式。

| Input / 输入 | Before / 优化前 | After / 优化后 |
| --- | ---: | ---: |
| Different numbers / 不同数值 (`1万` … `100000万`) | 2.86 s | 0.30 s |
| Different quantities / 不同数量 (`约1万` … `约100000万`) | 3.50 s | 0.61 s |
| Range parser, different points / 区间函数解析不同单点 | 3.50 s | 0.37 s |
| Mixed numeric formats / 混合数值格式 | 1.86 s | 0.22 s |

These are local measurements, not universal guarantees. The 0.1-second target
has not been reached. Repeated quantity and range inputs already benefit from
deduplication; this change does not materially improve those fast paths.
上一轮的 1.70 秒与本轮旧版计时不是同一次测量，不能直接用来计算提速比例。
本轮仍未达到 0.1 秒；耗时随格式、重复率、硬件和系统负载变化。

The parser now uses vectorized capture positions instead of one match list per
cell, then batches conversion and validation. Syntax and error precedence stay
unchanged. No dependency or native compiler is added.
本次减少逐条匹配对象和转换操作，不增加依赖，不改变语法及错误优先级。

Run `Rscript docs/number-performance.R` from the repository root to compare
values, names, problem attributes, strict errors, fixtures, header units and timing.
The unchanged baseline defaults to `outputs/quantity-optimization/library`;
it is a local snapshot, not included in the repository.

Local verification: differential checks passed; batch stability, broad-data audit,
multi-source audit and CSV round-trip passed. Full testthat assertions passed,
but the process exited nonzero; the pre-existing local exit problem is unresolved.
The process result is not recorded as a successful full check.
本地差异检查、压力测试、已有公开数据审计及 CSV 往返验证通过；
完整测试断言通过，但进程退出异常仍未解决，不算完整检查通过。
