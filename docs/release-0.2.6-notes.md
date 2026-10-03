# 中文

- 新增 `parse_cn_number(unit = ...)` 表头单位参数，裸数字按指定单位换算；同倍率显式单位不重复换算，冲突单位和百分比报告问题。
- 支持 `千元` 金额及共享区间后缀，支持简称“超”。
- 修复没有有效数值的限定词被误当成缺失值的问题。
- 同步双语说明，补充混合单位表格的使用提醒。
- 190 项测试通过，五组跨平台检查通过，并验证安装后的真实财报金额、帮助页及示例。

本版本为 GitHub 发布。CRAN 当前仍为 0.2.5，未重新提交。

# English

- Adds explicit table-header units to `parse_cn_number()`. Bare values inherit the unit; matching explicit multipliers are not applied twice. Conflicting units and percentages are reported.
- Supports thousand-yuan amounts and shared range suffixes, plus the shorthand qualifier `超`.
- Reports qualifiers without valid quantities instead of treating them as missing.
- Updates bilingual documentation with guidance for mixed-unit tables.
- Validated with 190 assertions, five cross-platform jobs, and installed-package checks using actual annual-report monetary cells, help, and examples.

GitHub release only. CRAN remains at 0.2.5; no resubmission has been made.
