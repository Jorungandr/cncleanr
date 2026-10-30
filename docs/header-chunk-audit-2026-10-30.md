# Header/custom-missing/chunk audit / 表头、缺失标记与分块检查

## Scope / 范围

Adds 147 checks to docs/system-audit.R, already executed by Ubuntu release CI.
These are workflow and independent expectation checks, not 147 defects. No
production parser defect was reproduced in this batch. Source checkpoint:
f32fde5b5e5ab8a1f1e0f85e397764a21aa36262.

* Three parsers × 百元/千元/万元 headers × 4800 rows = 43200 input row/configuration
  cases. Rows deliberately repeat; this is not 43200 distinct real-world texts.
* Independent gold values, negative-zero reciprocals, exact quantity qualifiers,
  range point bounds/inclusivity, error indices, original text and summary counts.
* Custom markers include full-width ９９９ and whitespace-normalized 暂 无.
  Missing markers are distinct from bad syntax, conflicting explicit units,
  overflow, nonzero underflow and malformed grouping.
* Strict mode accepts all known good/missing rows and rejects a three-row sample
  at the independently known second position.
* Two chunk schedules per configuration: a full irregular partition with empty
  chunks, and a repeated/reordered selection. Compare every value column and
  reason; map batch-local failures through source rows, retaining duplicates.
* Large whole batches and smaller chunks exercise existing fallback deduplication
  differently. This is result consistency, not a new performance benchmark.

本轮扩展已有自动审计入口，不新增公开函数、参数或运行时依赖。检查同时使用
表头换算、自定义缺失标记、空批次、不规则分块及重复乱序行；期望数值和错误
位置单独构造。数量和区间的字段分别验证，不把它们的返回结构混为一谈。

## Local results / 本地结果

Against installed v0.2.25, R 4.6.1 on Windows:

* Existing generated consistency checks: 2454 passed.
* New header/custom-missing/chunk workflow checks: 147 passed.
* Optional bit64 4.8.6 checks: 28 passed.
* Both README editions: 14 runnable blocks each, including one expected error;
  three installation blocks intentionally not executed, zero optional skips.

The first draft's expected summary check compared double counts with integer
counts using identical(). The expectation was normalized to double; actual
counts were correct. This was an audit construction correction, not a parser
defect. No new data collection, sanitizer or speed result is claimed.

## Publication boundaries / 发布边界

GitHub run 41071882800 completed successfully on all five platforms: Ubuntu
oldrel-1 (124117860358), Ubuntu release (124117860817), Ubuntu devel
(124117860917), Windows release (124117861012), macOS release (124117861385).
Downloaded Ubuntu release logs confirm Status OK, 1832 passing package
assertions, PDF manual OK, 2454 existing consistency checks, 147 new workflow
checks, 28 bit64 checks and 77 imported-type checks. The final report-only
commit does not change the audited script or README examples.

Repository-only audit/documentation update. Package code (R/, src/), DESCRIPTION,
NAMESPACE and package tests match v0.2.25. Existing public tag and release asset
are unchanged; no new version or CRAN submission. CSV's documented precision and
attribute limits remain; these checks do not claim lossless CSV serialization.
