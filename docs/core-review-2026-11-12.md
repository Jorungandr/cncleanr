# Core parser and diagnostic workflow review

## Coverage

Added 331 checks to `docs/system-audit.R`, comprising 324 checks across all nine
header-unit spellings and seven percentage checks. They cover the six public
functions through parsing, problem extraction, nested selection and summary.

The independent expectations include scalar arithmetic, scientific notation,
accounting negatives, signed zero, exact and approximate quantities, inclusive
and exclusive bounds, shared interval suffixes, percentage intervals, overflow,
underflow, invalid grouping, conflicting units and normalized missing markers.
Repeated and reversed selections are checked against original source positions
and independently counted successful, missing and failed rows.

The expanded installed-package audit passes 2960 assertions in total, comprising
2454 existing generated checks, 147 existing header/chunk checks, 331 new checks
and 28 optional bit64 checks. The complete package suite passes 1832 assertions.
The reproduced core-parser defect count in this bounded review is zero.

## Build correction

The first local installation reused a native binary dated October 19 from
`src/`. The installation was repeated with `R CMD INSTALL --preclean`, and the
full suite and expanded audit were rerun against the rebuilt installation.
The CI independent-install step now also uses `--preclean`. The contributing
guide includes the corresponding installed-package audit command.

## Performance measurements

Windows R 4.6.1 with GCC 15.2, 100000 rows per call. Each workload was warmed up,
then measured three times. Each measurement timed twenty consecutive calls and
divided elapsed time by twenty, with garbage collection before each measurement.
The table reports the median per-call seconds from the final paired run.

| Parser | Released installation, unique integers | Rebuilt installation, unique integers | Released installation, repeated mixed fields | Rebuilt installation, repeated mixed fields |
| --- | ---: | ---: | ---: | ---: |
| Number | 0.0100 | 0.0110 | 0.0085 | 0.0085 |
| Quantity | 0.0940 | 0.1015 | 0.0095 | 0.0110 |
| Range | 0.2485 | 0.2670 | 0.0705 | 0.0695 |

Unique integers are strings from 1 to 100000. Mixed fields repeat `3万元`,
`-5千元`, `1e3`, `1 234`, `bad`, `暂无` and NA. The range workload therefore
measures point-range parsing. Continuous-call timings include allocation and
garbage-collection costs. Final paired differences span approximately -1% to
+16%, with absolute differences up to 0.0185 seconds. These machine-local
measurements have limited precision for the shortest calls. Earlier measurements
using the reused binary are superseded by the rebuilt measurements above.

Local scripts and raw timings are retained under ignored
`outputs/core-review-2026-11-12/`, including `cost.R`, `current-preclean.csv`
and `baseline-final.csv`.

## 中文记录

本轮新增 331 项检查，覆盖九种表头单位、科学计数法、负数、百分比区间以及连续
筛选后的诊断与汇总。扩展审计共通过 2960 项断言，完整包测试通过 1832 项断言。
在本轮有限样本中，复现的核心解析缺陷为 0 项。

本地安装发现了旧 C 编译产物复用问题，已强制重新编译并重新运行全部相关测试。
CI 独立安装步骤和贡献指南加入 `--preclean`。性能表记录重编译后的实际测量，
包含连续调用的内存分配及垃圾回收成本。两套安装的测量存在波动，具体耗时见表。

## GitHub verification

Final validation source `05b60568ccb6042f34d6d69c77102e19c1a62629` passed all
five jobs on Ubuntu release/devel/oldrel-1, Windows release and macOS release.
Ubuntu release logs confirm `--preclean`, 2960 expanded audit assertions,
1832 package assertions, `Status: OK` and PDF manual OK. The expanded audit runs
in the Ubuntu release independent-install step.
[View run 43228786993](https://github.com/Jorungandr/cncleanr/actions/runs/43228786993).

The downloaded log is retained at
`outputs/core-review-2026-11-12/ci-ubuntu.log`.
