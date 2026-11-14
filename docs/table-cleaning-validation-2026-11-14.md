# Configurable CSV workflow validation

## Delivered workflow

`docs/table-cleaning.R` defines the repository example `clean_cn_csv()`. It takes
a UTF-8 CSV path, column/parser/unit configuration, a new output directory, an
optional ID column and a parsing batch size. It uses the public number,
quantity and range parsers together with `cn_problems()` and `cn_summary()`.

Outputs comprise cleaned values with original columns and statuses, per-field
review rows, quality counts, reason counts and a complete RDS result. The
workflow checks generated-name collisions and preserves duplicate IDs, original
data positions, qualifiers and open-bound flags. Files are staged in a sibling
directory and published after all writes succeed.

The full input and final results remain in memory. Batch size controls parser
calls. The Chinese/English guides include runnable configuration, export and
read-back examples linked from both READMEs.

## Correctness evidence

Independent synthetic expectations cover three columns at once, a repeated ID,
multiple errors in one source record, approximate quantities, monetary header
scaling, infinite bounds and endpoint inclusivity. Whole and chunked results
are identical across batch sizes 1, 2, 3, 20 and the maximum supported integer.
Additional checks cover empty/success/missing/failure inputs, omitted ID fields,
invalid configuration, output-name collisions, malformed CSV, invalid UTF-8 and
a UTF-8 BOM. A deliberately failing RDS write verifies staged-output cleanup and
preservation of an earlier completed output.

The workflow passed 21 parser fields from the attributed offline business
fixture and 6039 parser fields from the retained 6347-case business fixture.
The other 308 cases represent upstream business-review decisions in that fixture.
Source transformations are retained in the input columns. Existing source
attribution is recorded in `docs/fixtures/business-cases-README.md` and
`docs/business-validation-2026-10-30.md`.

Both new guides' three R blocks execute literally. Together with existing
README/tutorial blocks, 52 runnable blocks passed locally with optional
dependencies available. The new workflow audit and guide execution are part of
the existing five-platform CI.

## Cost measurements

Windows R 4.6.1, GCC 15.2. The synthetic CSV contains 100000 rows and three
configured columns, totaling 300000 field values. IDs repeat, amount contains
unique integer strings, estimate mixes approximation/bounds/failure/missing,
and interval mixes closed/open ranges/failure/missing. Results include 50000
per-field review rows. Each configuration ran three times, including reading,
parsing, summary construction and writing all CSV/RDS files.

| Batch size | Elapsed seconds | Median seconds | Returned object MiB | R heap high-water MiB |
| --- | --- | ---: | ---: | --- |
| 10000 | 1.24, 1.18, 2.72 | 1.24 | 20.71 | 77.8, 117.8, 117.8 |
| 100000 | 2.77, 2.64, 2.86 | 2.77 | 20.71 | 98.9, 98.9, 98.9 |

The object size is from `object.size()`. Heap figures sum R's Ncell/Vcell
high-water MiB after resetting GC statistics before each trial. They describe
R heap accounting and can reflect peaks at different times. Timing varied
between trials and includes serialization and compression. Whole/chunk RDS
outputs are exactly equal at 100000 rows, with independent numerical and review
position expectations checked across all rows.

Input, raw measurements, scripts and generated outputs are retained under
ignored `outputs/table-cleaning-2026-11-14/`.

## 中文记录

已提供按列配置解析方式和金额单位的完整 CSV 示例，一次输出清洗表、逐字段
复核表、质量汇总、原因汇总和完整 RDS。重复 ID、同一行多个字段失败、空输入、
开放边界、损坏输入和导出中断均有检查。已验证已有多领域数据中的 6039 个解析
字段，以及 21 个离线来源字段。

本机十万行、三列数据按一万行分批，含读取及全部文件写出的三次中位耗时为
1.24 秒，返回对象约 20.71 MiB。输入和最终结果整体保留在内存中。双语教程
均可直接执行，完整文档审计通过 52 个代码块。
