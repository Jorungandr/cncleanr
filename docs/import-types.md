# 导入类型安全 / Imported-type safety

## 根因与兼容性 / Cause and compatibility

Installed 0.2.16 was tested against actual haven 2.5.5, units 1.0.1 and bit64
4.8.6 in task-local libraries. SPSS numeric missing codes/ranges became valid
numbers; character user-defined missing cells had inconsistent diagnostics.
Units objects lost their units silently, even when monetary header scaling was
requested. These were reproduced before changing parser sources.

0.2.17 uses one shared entry function for all three parsers. It reads SPSS
`na_values`/`na_range`, strips only that class's storage metadata and replaces
matching non-native-missing values with NA before existing parsing. Direct metadata
handling works for RDS-restored objects without haven's namespace. Names are kept;
pre-existing NA/NaN/tagged-NA payloads are not overwritten without header scaling.
Malformed missing ranges are rejected. Ordinary labelled inputs still retain
their codes, not labels; text labels are not interpreted as quantities.

**Intentional compatibility change:** all direct `units` parser inputs now error,
including empty/dimensionless ones, with an explicit `units::drop_units()` remedy.
First choose/convert to the intended unit yourself. This prevents silent physical
or monetary interpretation, but does not perform unit algebra or infer currencies.
It is limited to parser inputs; `cn_subset()` still expects already parsed results
and explicit positional indices, not arbitrary labelled/unit-aware source tables.

本次只处理已确认的缺失定义和单位丢失风险，不添加通用第三方类型适配层。普通输入
只多常数时间的类别检查，不新增全量预扫描。原 C 源码、公开参数和运行时依赖不变。
integer64 仍转为 double：低于 2^53 的整数边界按既有规则处理，bit64 的精度警告会
传出；bit64 可能从 2^53 起保守地警告，不能据警告断言每个值都已实际失真。

## 验证与复现 / Validation and reproduction

Permanent dependency-free tests use SPSS metadata and units-class fixtures;
they failed against 0.2.16 first. They cover numeric/character discrete/range
missingness, mixed missing definitions, names, empty inputs, strict diagnostics,
custom text missing markers, NaN, invalid metadata and units rejection.

Real third-party checks deliberately live outside package tests, avoiding new
Suggests dependencies or optional-test skips in the ordinary suite:

```text
Rscript docs/import-types-audit.R <cncleanr-library> <optional-test-library>
```

This audit requires all three optional packages and prints actual loaded versions.
It compares real SPSS fixtures against independent literal expected values, tests
tag payloads/ordinary labels, units rejection and explicit metre/kilometre
conversion, plus bit64 exact values and precision-warning propagation.

These local versions do not certify every future/older dependency version or
platform. Current platform CI uses the dependency-free regressions; it is not a
claim that haven/units binaries ran on all five platforms. Neither schema labels
nor physical units can be inferred safely from an arbitrary custom S3 method.

Final measured validation and GitHub publication evidence follows after completion.
No CRAN upload is authorized.
