# cncleanr 0.2.13

## 中文

- 新增 `cn_subset()`：显式筛选、排序、重复取行时同步诊断行号，保留原返回类型。
- 编码错误注明 `x` 或 `na` 中首个原始失败位置，覆盖去重、回退与 factor。
- 定位仅在错误后执行，正常输入不增加全量编码扫描；C 源码未改动。
- 补齐独立回归、双语说明和跨平台可运行示例。

普通 `[]`、修改或合并仍不自动维护诊断；请先使用新函数。编码错误仍中止整批，
不改成普通缺失值。数值解析、返回类别、现有参数及普通错误原因保持不变。
本次不提交 CRAN，也不增加依赖。

## English

Adds explicit `cn_subset()` for diagnostic-preserving filtering, reordering and
repeated selection without new result classes. Encoding failures now identify
the originating argument and first original position through fallback,
deduplication and factor paths. Location work runs only on failure and reuses
unchanged native validation. Independent regressions, bilingual documentation
and an executable platform-CI example are included.

Ordinary `[]`, mutation and binding still do not track diagnostics; use the helper
first. Encoding errors still stop the batch, without partial results. Existing
signatures, ordinary reasons, numeric behavior and C sources remain unchanged.
No new runtime dependencies or CRAN upload.

[Validation evidence](https://github.com/Jorungandr/cncleanr/blob/main/docs/diagnostic-workflow.md).
