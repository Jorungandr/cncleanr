# 数值转换一致性 / Numeric conversion consistency

## 已修复问题 / Repaired behavior

A numeric S3 object's storage can differ from its converted value. The old
no-header branch and quantity/range parsers called `as.double()`, but the header
branch formatted the original storage with `sprintf()`. A minimal S3 object with
storage `1` and converted value `30000` therefore produced `10000` under header
万 instead of `300000000`. This is a synthetic regression fixture, not a claim
about a separately tested third-party package or real dataset.

0.2.15 converts once at numeric entry and uses that plain double vector for both
missing detection and header formatting. Original input names are restored.
No-header numeric Inf/-Inf/NaN pass-through remains; with a header, missing values
remain missing and infinities/overflow remain parsing problems. Numeric text
syntax and all C sources are unchanged. No additional character-input scan,
dependency, public argument or arbitrary class adapter is added.

数值 S3 对象的底层存储不一定就是转换后的数值。修复前，带表头单位的分支直接格式化
底层存储；现在先用已有 `as.double()` 转换，再判断缺失并换算。转换方法只调用一次。
这不保证精确大整数或任意第三方类别的语义；调用方仍需提供正确的转换方法，结果仍为
双精度数值。此处不引入 `integer64`、日期或单位类别的专用解析器。

## 回归与复现 / Regressions and reproduction

The dependency-free S3 test registers a unique method only inside its test call,
then removes it on exit, including failed tests. It covers all eight header
spellings, names and empty names, one conversion, converted sentinel missingness,
NA/NaN, infinities, negative zero, strict failures, plain integer/double values,
and quantity/range consistency. It failed on installed 0.2.14 before the repair.

```r
library(cncleanr)
testthat::test_file('tests/testthat/test-header-unit.R')
```

```text
Rscript docs/numeric-conversion-performance.R <new-library> <0.2.14-library>
```

The timing script compares complete equal outputs on 100,000 ordinary integers,
doubles and character cells with a header. It uses the same C routines, warm-up,
seven alternating paired samples and three calls per sample. This is a narrow
regression check, not a new speed-optimization campaign or universal latency
guarantee. Final results are recorded after verification; no CRAN submission.
