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

## 完成记录 / Completed validation

GitHub [v0.2.17](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.17)
is published from source commit `1f5271cacb92c4a7261a5931a77e480c17d55c11`.
The fixed annotated tag object is `488a8fe899b02857bb15c38e4aa6f826b1037f52`.
The 53,430-byte source asset has SHA256
`1178f073396dda1f5fc849892421f7df8086f3d037f3a3b3b64b12028e1bf211`.
An unauthenticated public asset download matched that hash and was independently
installed; release/source verification and the real imported-type/system audits
passed against that installation.

- Local clean-source R CMD check: `Status: OK`, 1,008 assertions, no failed,
  warned or skipped tests. Local check used `--no-manual`, disabled incoming
  checks and remote dependency-cycle lookup; it does not certify those checks.
- [CI run 39045672287](https://github.com/Jorungandr/cncleanr/actions/runs/39045672287):
  all five jobs reported `Status: OK` and 1,008 passing assertions (Ubuntu devel,
  release, oldrel-1; Windows release; macOS release). Ubuntu release additionally
  passed PDF and HTML manual checks.
- Real haven 2.5.5 / units 1.0.1 / bit64 4.8.6 audit: 77 checks passed;
  generated consistency audit: 2,454 passed, plus 28 real bit64 checks.
  Generated consistency is not independent semantic proof.
- Existing real/multi-source/broad-data audits passed, with all nine retained
  snapshot hashes verified. This is snapshot reuse, not newly collected data.
- C sources are unchanged; no new sanitizer/Valgrind run is claimed.

Ordinary-input regression timing used five alternating paired medians against
0.2.16 R code with the same unchanged C implementation, on this Windows machine:

| Interface / rows | 0.2.16 seconds | 0.2.17 seconds |
| --- | ---: | ---: |
| number / 100,000 | 0.0133 | 0.0133 |
| quantity / 100,000 | 0.20 | 0.18 |
| range / 20,000 | 0.39 | 0.41 |

These short samples vary in both directions; they neither establish a speedup
nor guarantee zero overhead. No broad performance rewrite or new dependencies
were introduced. 单位输入现在明确报错，是有意的兼容性变化；需要先自行换算再去单位。
No CRAN upload was made.
