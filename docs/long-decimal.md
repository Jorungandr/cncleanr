# 超长数值修复 / Long decimal repair

## 范围 / Scope

```r
x <- paste0(strrep('1', 5000), 'e-4999')
parse_cn_number(x, strict = TRUE) # approximately 1.111111, not NA
```

0.2.13 在当前 Windows R 环境中误拒绝该有限值。根因是超长十进制转换产生
NaN，已有回退再次调用同一转换。直接截为 17 位不能保持舍入方向；仅缩短为
1,100 位也不足以规避某些运行时在极远尾数上的舍入误差。

The previous fallback reused a conversion that fails on long significands in the
tested Windows R environment. Truncating to 17 digits loses rounding direction;
even a longer prefix cannot make every runtime conversion a rounding oracle.

## 实现与性能边界 / Implementation and performance boundary

- 原生快速路径仅增加常数时间长度判断，将超长数字交给已有回退；普通转换规则不变。
- 规范化十进制指数及单位，再保留 1,100 位有效数字；若丢弃部分非零，追加
  非零 sticky digit。精确 binary64 中点最多需要 768 位有效十进制数字，因此
  此前缀和尾数方向足以确定相对位置，不能把尾数直接丢弃。
- 内部注册 C 函数只处理有界正规范数值，用标准转换提供邻近候选，再用整数
  十进制中点比较校正 ties-to-even。局部适配当前小数点，不修改全局区域设置。
- 不新增公开函数、依赖、普通数据扫描或整批预处理。超长输入仍需按文本长度
  读取，不能承诺与短数字等速。极端下溢仍记录错误，不悄悄变成零。

The native fast path adds only a constant-time length guard for long bodies;
the existing fallback retains a bounded significant
prefix plus sticky direction, then uses exact decimal representations of dyadic
midpoints to correct a nearby conversion candidate. Locale adaptation is local,
without process-global locale changes. Ordinary conversion semantics,
public signatures and dependencies remain unchanged. Reading a long cell still
costs time proportional to its text length; this is not a universal speed claim.

## 验证 / Validation

Independent tests cover known values across all parsers, factors and repeated
fallback batches, exact ties and tails on either side, 2^-1075, the finite/overflow
midpoint, leading zeros, scaling, and malformed private-call arguments. The
native/R differential test still bypasses accelerated normalization/numeric
paths; long-decimal rounding is shared and separately tested with known answers.

Reproduce from this checkout after installing the package:

```r
library(cncleanr)
testthat::test_file('tests/testthat/test-systematic-hardening.R')
```

Performance script (paths refer to separately installed libraries):

```text
Rscript docs/long-decimal-performance.R <new-library> <0.2.13-library>
```

It loads the old number parser, boundary function and native routines alongside
the current package for a same-process comparison, checks complete outputs, warms both functions,
alternates timing order and reports five-sample medians. This isolates the changed
repair; it is not a two-process full-environment benchmark. Timings are not
flaky CI assertions. Final measured results and publication evidence follow after
verification; no CRAN submission is authorized.
