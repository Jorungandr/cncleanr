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

## 本地结果 / Local results (2026-10-15–16, Asia/Shanghai)

Windows 11 x64, R 4.6.1, UCRT GCC 15.2. Source commit:
`a172958c6384cb70d16273cfebef90150662993d`.

Two complete benchmark runs (seconds; each cell is the median of five paired,
alternating-order samples; old/new complete outcomes matched):

| Dataset | Rows | Run 1 old → new | Run 2 old → new |
| --- | ---: | ---: | ---: |
| Distinct compact numbers | 1,000,000 | 0.603 → 0.647 | 0.437 → 0.460 |
| Mixed formatted numbers/errors/missing | 100,000 | 0.040 → 0.035 | 0.040 → 0.040 |
| Repeated extreme numbers | 3,000 | 0.010 → 0.010 | 0.010 → 0.010 |
| Distinct qualified quantities | 100,000 | 0.610 → 0.590 | 0.670 → 0.630 |
| Distinct ranges | 100,000 | 5.940 → 5.940 | 3.310 → 1.290 |

The runs show substantial machine/timing variation, not a new range speedup.
Because the first two million-row medians were 5–7% slower, a further isolated
ordinary-number check used nine alternating pairs, three million-row calls per
sample, explicit GC before each pair and exact output comparison. Its median was
**0.140 → 0.133 seconds**. Thus no stable ordinary-data slowdown was observed;
neither zero overhead nor a speedup is established. The native ordinary path adds
one pointer-length comparison, not another string scan. The R fallback adds a
length check to identify long values. No universal 0.1-second promise is made.

修复前后多轮计时存在明显波动；普通百万条专项九轮对照中位数为 0.140 → 0.133 秒。
不能据此宣称提速或零开销，但未观察到稳定的普通数据退化。两轮完整测试的百万条
中位数曾慢 5–7%，因此一并保留，未只挑最快结果。超长 5,000 位、100 个不同值的
新包中位数分别为 0.260 和 0.030 秒；旧包会拒绝它们，不能计算有效提速倍数。

Local clean-commit archive `R CMD check --as-cran --no-manual`: **Status: OK**,
833 assertions, zero failures/warnings/skips. Remote incoming and PDF manual were
not checked locally. [Five-platform CI](https://github.com/Jorungandr/cncleanr/actions/runs/38763569044)
passed on the same source commit, 833 assertions each; Linux release PDF/HTML
manual checks were OK. The retained financial, multi-source and broad-data audits
all passed on installed 0.2.14; no new data sources are claimed. A Windows German
comma-decimal locale probe passed and restored its prior locale afterwards.

An additional fixed-seed independent Python 3.14 binary64 oracle matched all
**1,500** long-decimal results bit-for-bit (or the documented overflow/underflow
rejection). The 500 base cases included 100 randomly selected adjacent-double midpoints with
5,000-digit tails below/at/above each midpoint, plus 200 random long decimals
across subnormal, ordinary and overflow exponents. The same base cases were also
checked after exact decimal percentage and trillion scaling. This was a supplementary
local check, not an added package dependency or an extra CI assertion count.

## 内存检查与发布 / Native checks and publication

[R-hub 38763677021](https://github.com/Jorungandr/cncleanr/actions/runs/38763677021)
checked the same source commit using clang-ASAN, clang-UBSAN and Valgrind. All
three completed with Status OK and 833 assertions, no test failures/warnings/skips.
The actual Valgrind logs report zero errors and zero definitely, indirectly or
possibly lost bytes for examples and both test scripts. The unused alternate
platform matrix job is expected to be skipped; none of the three requested
native check jobs was skipped.

[GitHub v0.2.14](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.14)
uses the annotated tag object `80b4334fe14b7f7580b82b32995cb8211e4c3c1f`, pointing
to checked source `a172958c6384cb70d16273cfebef90150662993d`. The exact locally
checked asset is 50,077 bytes, SHA-256:

```text
35618A239BDC1898B96C7BBE67DBA9488ADE06446992DF921E34AA0D17FE2354
```

The GitHub asset digest and draft-download hash match the checked archive.
Isolated installation from that download, source/version verification, all 833
assertions and the dependency-free regression passed before publication.
After publication, an unauthenticated GitHub asset API download matched the same
SHA-256 and size. It installed into the separate
`outputs/long-decimal/published-library/`; source/version verification, the
complete 833 assertions and the dependency-free regression passed again. No
CRAN upload was made. Older tags and assets were not changed.

同一源码的五平台检查、ASAN、UBSAN、Valgrind 均通过；发布附件为实际检查过的源码包。
性能结论仍限于上面的实测范围，不作全格式统一耗时或零开销保证。本次未提交 CRAN。
