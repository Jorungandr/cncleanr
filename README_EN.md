# cncleanr

**English** | [中文](README.md)

[![R-CMD-check](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml)

`cncleanr` safely parses compact numbers, qualified quantities, and numeric ranges commonly found in Chinese tables, web pages, and statistical reports.

It does not merely extract the first number it encounters. A non-missing value that cannot be interpreted in full becomes `NA`, produces a warning, and records a structured reason.

## Installation

Install the released package from GitHub:

```r
install.packages("pak")
pak::pak("Jorungandr/cncleanr@v0.2.0")
```

## Exact numbers

```r
library(cncleanr)

parse_cn_number(c("1.25万", "￥3亿元", "12.5%", "１．２e５", "暂无"))
#> [1] 1.25e+04 3.00e+08 1.25e-01 1.20e+05       NA
```

Common supported forms include:

- `万`, `亿`, and `万亿` magnitude suffixes;
- `元`, `人民币`, `￥`, `¥`, `RMB`, `CNY`, `块`, and `块钱` currencies;
- percentages and scientific notation;
- full-width digits, punctuation, and whitespace;
- regular negative signs and accounting parentheses;
- configurable missing-value markers.

## Qualified quantities

`parse_cn_quantity()` retains the meaning of approximate values and fuzzy qualifiers in the original text.

```r
parse_cn_quantity(c("3万", "约3万", "超过2亿", "不少于5万", "10%以下"))
#>     value    qualifier
#> 1   3e+04        exact
#> 2   3e+04       approx
#> 3   2e+08 greater_than
#> 4   5e+04     at_least
#> 5   1e-01      at_most
```

Possible qualifiers are `exact`, `approx`, `greater_than`, `at_least`, `less_than`, and `at_most`.

Common inequality forms have explicit boundary semantics:

- `大于3万` and `小于3万` exclude the boundary;
- `不大于3万` and `不小于3万` include the boundary;
- `<`, `>`, `<=`, `>=`, `≤`, `≥`, and their full-width forms are supported;
- `10万+` means at least 100,000, while `50余` means greater than 50.

## Numeric ranges

`parse_cn_range()` returns explicit bounds and indicates whether each boundary is inclusive.

```r
parse_cn_range(c("3万-5万", "3-5万", "10万元以上", "低于2亿"))
#>   lower upper lower_inclusive upper_inclusive
#> 1 3e+04 5e+04            TRUE            TRUE
#> 2 3e+04 5e+04            TRUE            TRUE
#> 3 1e+05   Inf            TRUE           FALSE
#> 4  -Inf 2e+08           FALSE           FALSE
```

A shared suffix in a form such as `3-5万` is applied to both endpoints of the numeric range. Reversed ranges and invalid endpoints are reported as problems.
Signs in scientific notation are not treated as range separators, so both `1e-3` and `1e-3-2e-3` are parsed correctly.

## Inspecting problems

```r
result <- suppressWarnings(parse_cn_number(c("2万", "约3万", "abc")))
cn_problems(result)
#>   index value                                      reason
#> 1     2  约3万 value does not match the supported number syntax
#> 2     3   abc value does not match the supported number syntax
```

Set the `strict = TRUE` argument to turn any parsing failure into an error:

```r
parse_cn_number(c("2万", "abc"), strict = TRUE)
```

## Development and testing

The project includes two test suites:

- `tests/parser.R`: a dependency-free package check suite;
- `tests/testthat/`: the complete development suite for edge cases and error behavior.

Every push is checked on Linux, macOS, and Windows with GitHub Actions.

## Scope

`cncleanr` focuses on Arabic digits combined with Chinese data conventions, such as `3.2亿元`, `约5万`, and `3万-5万`. Fully written Chinese numerals such as “一万三千” are currently outside the package's core scope.

## License

MIT
