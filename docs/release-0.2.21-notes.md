# cncleanr 0.2.21

Adds hundred-yuan (`百元`) support using the existing thousand-yuan rules:

```r
parse_cn_number('3百元') # 300
parse_cn_number(c('3', '3百元'), unit='百元') # 300 300
parse_cn_quantity('约3百元')$value # 300
parse_cn_range('3-5百元')$upper # 500
```

R fallback and C fast path both support the unit. Conflicting header units,
malformed syntax, overflow and underflow retain existing validation. Bare 百
and 百块 remain unsupported. Public function names and dependencies are unchanged.

新增百元金额、表头单位、限定数量与共享单位区间支持，不重复换算。
保持原有错误诊断与六个函数名；本版本仅发布 GitHub，不提交 CRAN。
