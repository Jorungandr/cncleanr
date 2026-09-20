# cncleanr

**English** | [中文](README.md)

[![R-CMD-check](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml)

`cncleanr` safely parses compact numbers, qualified quantities, and numeric ranges commonly found in Chinese tables, web pages, and statistical reports.

It does not merely extract the first number it encounters. A non-missing value that cannot be interpreted in full becomes `NA`, produces a warning, and records a structured reason.

## Installation

Install the released package from GitHub:

```r
install.packages("pak")
pak::pak("Jorungandr/cncleanr@v0.2.4")
```

## Enterprise revenue cleaning example

The workflow below preserves the original text, parses the revenue column, and maps unparseable records back to their source companies:

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

This example uses `suppressWarnings()` because the next step inspects every structured problem with `cn_problems()`. Do not hide the warnings if you do not plan to inspect the problems.

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
- full-width digits, punctuation, exponent letters, and common PDF minus signs;
- valid three-digit grouping with regular, non-breaking, narrow, or ideographic spaces;
- regular negative signs and accounting parentheses;
- configurable missing-value markers.

Whitespace between digits is accepted only when it forms valid three-digit grouping: `1 234` becomes `1234`, while `1 2` and `12 34` are reported instead of being silently concatenated.

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

The six `qualifier` values and their boundary semantics are:

| `qualifier` | Meaning | Boundary semantics |
| --- | --- | --- |
| `exact` | Exact value | Equal to `value` |
| `approx` | Approximate value | Treats `value` as an estimate; no open or closed boundary is defined |
| `greater_than` | Greater than | `> value`; excludes the boundary |
| `at_least` | At least | `>= value`; includes the boundary |
| `less_than` | Less than | `< value`; excludes the boundary |
| `at_most` | At most | `<= value`; includes the boundary |

Common inequality forms have explicit boundary semantics:

- `大于3万` and `小于3万` exclude the boundary;
- `不大于3万` and `不小于3万` include the boundary;
- `<`, `>`, `<=`, `>=`, `≤`, `≥`, and their full-width forms are supported;
- `10万+` means at least 100,000;
- `50余`, `10万余`, `50余万`, and `50余万元` all retain a `greater_than` qualifier.

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

## Return-value reference

Every parser preserves input order and returns one result for each input. Problem details can be retrieved separately from the result object.

| Function | Result |
| --- | --- |
| `parse_cn_number()` | A numeric vector with one value for each input |
| `parse_cn_quantity()` | A data frame with `value` and `qualifier` columns |
| `parse_cn_range()` | A data frame with `lower`, `upper`, `lower_inclusive`, and `upper_inclusive` columns |
| `cn_problems()` | A data frame with `index`, `value`, and `reason` columns; zero rows when there are no problems |

Numeric input is converted directly to doubles and preserved, including `Inf`,
`-Inf`, and `NaN`. `parse_cn_quantity()` marks finite values, `Inf`, and `-Inf`
as `exact`, while `NA` and `NaN` have a missing qualifier. `parse_cn_range()`
represents each non-missing numeric value as an inclusive point range. Infinite
bounds generated from textual inequalities are open-ended bounds and are
distinct from numeric `Inf` or `-Inf` point inputs.

## Inspecting problems

```r
result <- suppressWarnings(parse_cn_number(c("2万", "约3万", "abc")))
cn_problems(result)
#>   index value                                      reason
#> 1     2  约3万 value does not match the supported number syntax
#> 2     3   abc value does not match the supported number syntax
```

Ordinary mode returns `NA` at failed positions, preserves the other usable results, and emits a warning. If a cleaning workflow must stop as soon as any row fails, set `strict = TRUE`:

```r
parse_cn_number(c("2万", "abc"), strict = TRUE)
```

Custom missing values, such as the supported default `"暂无"`, are not parsing failures in either mode.

## Common failure reasons

The `reason` returned by `cn_problems()` can be used directly to locate these problems:

| Situation | Example | `reason` |
| --- | --- | --- |
| Unsupported syntax | `3万abc` | `value does not match the supported number syntax` |
| Invalid whitespace grouping between digits | `1 2` | `digits use invalid whitespace grouping` |
| Repeated or conflicting qualifiers | `约3万左右` | `multiple or conflicting qualifiers` |
| Reversed range bounds | `5万-3万` | `range lower bound is greater than its upper bound` |
| Invalid range endpoint | `3万-abc` | `one or both range endpoints are invalid` |
| Value outside the finite double range | `1e308万` | `value is outside the finite double range` |

When parsing fails, first use ordinary mode and inspect `cn_problems()`. Use `strict = TRUE` only when the cleaning workflow must stop if any row fails.

## Development and testing

The project includes two test suites:

- `tests/parser.R`: a dependency-free package check suite;
- `tests/testthat/`: the complete development suite for edge cases and error behavior.

Every push is checked on Linux, macOS, and Windows with GitHub Actions.

## Scope

`cncleanr` focuses on Arabic digits combined with Chinese data conventions, such as `3.2亿元`, `约5万`, and `3万-5万`. Fully written Chinese numerals such as “一万三千” are currently outside the package's core scope.

## License

MIT
