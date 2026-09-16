# cncleanr

[English](README_EN.md) | **中文**

[![R-CMD-check](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml)

`cncleanr` 用于安全解析中文表格、网页和统计公报中的紧凑数字、模糊数量及数值区间。

它不会只截取字符串中遇到的第一个数字。无法完整解释的非缺失值会变成 `NA`，同时产生警告并记录失败原因。

## 安装

从 GitHub 安装正式版本：

```r
install.packages("pak")
pak::pak("Jorungandr/cncleanr@v0.2.0")
```

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
- 全角数字、标点和空白；
- 普通负数和会计括号负数；
- 可配置的缺失值标记。

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

可能的 `qualifier` 为 `exact`、`approx`、`greater_than`、`at_least`、`less_than` 和 `at_most`。

常见不等式表达具有明确的边界含义：

- `大于3万`、`小于3万`：不包含边界；
- `不大于3万`、`不小于3万`：包含边界；
- `<`、`>`、`<=`、`>=`、`≤`、`≥` 及其全角形式也可以使用；
- `10万+` 按“不少于10万”处理，`50余` 按“大于50”处理。

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

## 查看解析问题

```r
result <- suppressWarnings(parse_cn_number(c("2万", "约3万", "abc")))
cn_problems(result)
#>   index value                                      reason
#> 1     2  约3万 value does not match the supported number syntax
#> 2     3   abc value does not match the supported number syntax
```

设置参数 `strict = TRUE` 可以让任意解析失败立即变成错误：

```r
parse_cn_number(c("2万", "abc"), strict = TRUE)
```

## 开发与测试

项目包含两套测试：

- `tests/parser.R`：无额外依赖的基础包检查；
- `tests/testthat/`：覆盖边界条件和错误行为的完整开发测试。

每次推送都会在 Linux、macOS 和 Windows 上运行 GitHub Actions 检查。

## 设计边界

`cncleanr` 专注于实际数据源中的阿拉伯数字加中文单位，例如 `3.2亿元`、`约5万` 和 `3万-5万`。中文文字数字（例如“一万三千”）暂不属于本包的核心范围。

## 许可证

MIT
