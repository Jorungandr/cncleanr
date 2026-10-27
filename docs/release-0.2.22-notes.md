# cncleanr 0.2.22

Adds `unit = NULL` to quantities and ranges, reusing number-parser header rules:

```r
parse_cn_quantity('约3',unit='百元')$value # 300
parse_cn_range('3-5',unit='千元')$upper # 5000
parse_cn_range('3-5千元',unit='千元')$upper # 5000, not scaled twice
```

Matching units are scaled once; percentages/conflicting units are diagnosed.
Numeric header conversion preserves missing values and reports nonfinite inputs
and overflow. Inequality-generated infinite open ends remain valid. Default
behavior, six exports, native code and dependencies are unchanged.

数量与区间函数新增表头单位支持，复用既有换算、缺失值和错误诊断规则。
不改变默认行为及函数名，不提交 CRAN。
