# cncleanr 0.2.17

## 中文

- 三个解析接口统一尊重 SPSS 自定义缺失码和缺失区间，包括字符型缺失；无需额外
  依赖或加载 haven，保留名称及原有未换算的 NA／NaN／带标签 NA。
- **兼容性变化：** 直接传入 units 对象现在会明确报错。请先转换到所需单位，
  再显式 `units::drop_units()`；空及无量纲 units 也不再静默剥离。
- 普通标签、bit64 精度警告、既有解析规则不变。新增独立回归、真实第三方类型
  审计及双语说明；无新运行时依赖、公开参数或 C 改动。

仅发布 GitHub，不提交 CRAN。

## English

Respects numeric/character SPSS user-defined missing codes and ranges consistently
across all three parsers, without importing haven. Keeps names and existing
unscaled NA/NaN/tagged-NA payloads. **Compatibility change:** direct units objects,
including empty/dimensionless ones, now error; choose/convert units first and
explicitly call `units::drop_units()`. Ordinary labels, precision warnings and
established parsing rules remain. Adds regressions, a real imported-type audit
and bilingual guidance, no new dependencies/public parameters/C changes.

GitHub only; no CRAN submission.

[Validation and limits](https://github.com/Jorungandr/cncleanr/blob/main/docs/import-types.md).
