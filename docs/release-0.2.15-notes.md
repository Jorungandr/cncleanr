# cncleanr 0.2.15

## 中文

修复带表头单位时忽略数值对象 `as.double()` 转换的问题。现在先转换一次，再检测
缺失值、应用表头单位；原始名称保留。数量／区间接口、普通数字规则和 C 源码不变。
补齐全部表头单位、转换后缺失、负零、无穷值和严格模式的回归，以及双语说明和
性能对照脚本。无新公开接口或运行时依赖。本次只发布 GitHub，不提交 CRAN。

## English

Respects numeric `as.double()` methods before header-unit scaling and missing
detection, matching existing no-header and quantity/range behavior. Conversion
runs once; original names and nonfinite policies are retained. Adds regressions
for all header units, converted missingness, negative zero and strict diagnostics,
bilingual guidance and a same-process performance comparison. No new API,
runtime dependency or C change. GitHub only; no CRAN upload.

[Validation and scope](https://github.com/Jorungandr/cncleanr/blob/main/docs/numeric-conversion.md).
