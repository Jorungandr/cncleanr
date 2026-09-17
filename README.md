# cncleanr

[English](README_EN.md) | **中文**

[![R-CMD-check](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml)

`cncleanr` 用于安全解析中文表格、网页和统计公报中的紧凑数字、模糊数量及数值区间。

它不会只截取字符串中遇到的第一个数字。无法完整解释的非缺失值会变成 `NA`，同时产生警告并记录失败原因。

## 安装

从 GitHub 安装正式版本：

```r
install.packages("pak")
pak::pak("Jorungandr/cncleanr@v0.2.2")
```

## 企业营收清洗示例

下面的流程保留原始文本，解析营收列，并把无法解析的记录定位回原始企业：

```r
library(cncleanr)

enterprises <- data.frame(
  company = paste0(c("甲", "乙", "丙", "丁", "戊"), "公司"),
  revenue_raw = c("3.2亿元", "约5万", "10万+", "暂无", "3万abc")
)

parsed <- suppressWarnings(parse_cn_quantity(enterprises$revenue_raw))
cleaned <- cbind(enterprises, parsed)
cleaned
#>   company revenue_raw   value qualifier
#> 1 甲公司     3.2亿元 3.2e+08      exact
#> 2 乙公司       约5万 5.0e+04     approx
#> 3 丙公司       10万+ 1.0e+05   at_least
#> 4 丁公司        暂无      NA       <NA>
#> 5 戊公司      3万abc      NA       <NA>

problems <- cn_problems(parsed)
problem_rows <- cbind(
  company = enterprises$company[problems$index],
  problems
)
problem_rows
#>   company index  value                                      reason
#> 1 戊公司      5 3万abc value does not match the supported number syntax

write.csv(
  cleaned,
  "enterprise_revenue_cleaned.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
```

这里使用 `suppressWarnings()`，是因为下一步会通过 `cn_problems()` 检查完整的结构化问题；如果不准备检查问题，不建议隐藏警告。

## 精确数字

```r
library(cncleanr)

parse_cn_number(c("1.25万", "￥3亿元", "12.5%", "１．２e５", "暂无"))
#> [1] 1.25e+04 3.00e+08 1.25e-01 1.20e+05       NA
```

支持的常见形式包括：

- `万`、`亿`、`万亿`；
- `元`、`人民币`、`￥`、`¥`、`RMB`、`CNY`、`块`和`块钱`；
- 百分数和科学计数法；
- 全角数字、标点、指数，以及 PDF 常见的异体负号；
- 普通空格、不间断空格、窄空格和全角空格组成的合法三位分组；
- 普通负数和会计括号负数；
- 可配置的缺失值标记。

数字间的空格只在构成合法三位分组时才会被接受：`1 234` 会解析为 `1234`，但 `1 2` 和 `12 34` 会报告错误，不会被静默拼接。

## 模糊数量与不等式

`parse_cn_quantity()` 保留原文中的约数与模糊限定含义。

```r
parse_cn_quantity(c("3万", "约3万", "超过2亿", "不少于5万", "10%以下"))
#>     value    qualifier
#> 1   3e+04        exact
#> 2   3e+04       approx
#> 3   2e+08 greater_than
#> 4   5e+04     at_least
#> 5   1e-01      at_most
```

六种 `qualifier` 的含义和边界如下：

| `qualifier` | 含义 | 边界语义 |
| --- | --- | --- |
| `exact` | 精确值 | 等于 `value` |
| `approx` | 约数 | 以 `value` 为近似值，不定义开闭边界 |
| `greater_than` | 大于 | `> value`，不包含边界 |
| `at_least` | 不小于 | `>= value`，包含边界 |
| `less_than` | 小于 | `< value`，不包含边界 |
| `at_most` | 不大于 | `<= value`，包含边界 |

常见不等式表达具有明确的边界含义：

- `大于3万`、`小于3万`：不包含边界；
- `不大于3万`、`不小于3万`：包含边界；
- `<`、`>`、`<=`、`>=`、`≤`、`≥` 及其全角形式也可以使用；
- `10万+` 按“不少于10万”处理；
- `50余`、`10万余`、`50余万` 和 `50余万元` 均保留“大于”的限定含义。

## 数值区间

`parse_cn_range()` 返回上下界以及边界是否包含在区间内。

```r
parse_cn_range(c("3万-5万", "3-5万", "10万元以上", "低于2亿"))
#>   lower upper lower_inclusive upper_inclusive
#> 1 3e+04 5e+04            TRUE            TRUE
#> 2 3e+04 5e+04            TRUE            TRUE
#> 3 1e+05   Inf            TRUE           FALSE
#> 4  -Inf 2e+08           FALSE           FALSE
```

`3-5万` 这类共享单位会自动应用到数据区间的两个端点。上下界颠倒或端点无法解析时会报告问题。
科学计数法中的符号不会被误认为区间分隔符，因此 `1e-3` 和 `1e-3-2e-3` 都可以正确解析。

## 返回值速查

所有解析函数都保持输入顺序，每条输入对应一条结果；问题信息可以从结果对象中单独取出。

| 函数 | 返回值 |
| --- | --- |
| `parse_cn_number()` | 数值向量，每条输入对应一个值 |
| `parse_cn_quantity()` | 含 `value` 和 `qualifier` 两列的数据框 |
| `parse_cn_range()` | 含 `lower`、`upper`、`lower_inclusive` 和 `upper_inclusive` 四列的数据框 |
| `cn_problems()` | 含 `index`、`value` 和 `reason` 三列的数据框；没有问题时返回零行 |

## 查看解析问题

```r
result <- suppressWarnings(parse_cn_number(c("2万", "约3万", "abc")))
cn_problems(result)
#>   index value                                      reason
#> 1     2  约3万 value does not match the supported number syntax
#> 2     3   abc value does not match the supported number syntax
```

普通模式会把失败位置返回为 `NA`，保留其他可用结果，同时发出警告。清洗流程如果要求“任意一行失败就停止”，可以设置 `strict = TRUE`：

```r
parse_cn_number(c("2万", "abc"), strict = TRUE)
```

无论使用哪种模式，自定义缺失值（例如默认支持的 `"暂无"`）都不算解析失败。

## 常见失败原因

`cn_problems()` 的 `reason` 可以直接用于定位以下问题：

| 情况 | 示例 | `reason` |
| --- | --- | --- |
| 不支持的语法 | `3万abc` | `value does not match the supported number syntax` |
| 数字空格分组无效 | `1 2` | `digits use invalid whitespace grouping` |
| 限定词重复或冲突 | `约3万左右` | `multiple or conflicting qualifiers` |
| 区间上下界颠倒 | `5万-3万` | `range lower bound is greater than its upper bound` |
| 区间端点无效 | `3万-abc` | `one or both range endpoints are invalid` |
| 数值超出有限双精度范围 | `1e308万` | `value is outside the finite double range` |

遇到失败时，先在普通模式下调用解析函数并查看 `cn_problems()`；只有在清洗流程要求“任意一行失败就停止”时，才使用 `strict = TRUE`。

## 开发与测试

项目包含两套测试：

- `tests/parser.R`：无额外依赖的基础包检查；
- `tests/testthat/`：覆盖边界条件和错误行为的完整开发测试。

每次推送都会在 Linux、macOS 和 Windows 上运行 GitHub Actions 检查。

## 设计边界

`cncleanr` 专注于实际数据源中的阿拉伯数字加中文单位，例如 `3.2亿元`、`约5万` 和 `3万-5万`。中文文字数字（例如“一万三千”）暂不属于本包的核心范围。

## 许可证

MIT
