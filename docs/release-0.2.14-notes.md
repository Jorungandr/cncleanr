# cncleanr 0.2.14

## 中文

- 修复超长有效数字配合指数时，本应可表示的值被误判为超出范围的问题。
- 在共享极端数值回退中保留 1,100 位及非零尾数标记，并用精确二进制中点比较
  校正平台转换结果；覆盖常规舍入、次正规数和溢出边界。
- 普通数值快速路径、公开接口和既有诊断规则不变，无新运行时依赖。
- 包含此前 main 上的分批清洗示例与回归；补齐双语文档和性能复现脚本。

本次仅发布 GitHub，不提交 CRAN。性能实测与验收见下面的记录。

## English

Rescues representable long decimal significands in the shared extreme-value
fallback. A 1,100-digit prefix plus a sticky tail retains rounding direction;
exact binary64 midpoint comparisons correct platform conversion candidates,
including subnormal and overflow boundaries. Ordinary fast paths, public APIs
and established diagnostic rules are unchanged, with no new runtime dependencies.
Includes the previously added batch-cleaning example, independent rounding tests,
bilingual documentation and a reproducible old/new performance comparison.

GitHub release only; no CRAN submission.

[Validation and timings](https://github.com/Jorungandr/cncleanr/blob/main/docs/long-decimal.md).
