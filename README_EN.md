# cncleanr

**English** | [中文](README.md)

[![R-CMD-check](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml)

`cncleanr` safely parses compact numbers, qualified quantities, and numeric ranges commonly found in Chinese tables, web pages, and statistical reports.

It does not merely extract the first number it encounters. A non-missing value that cannot be interpreted in full becomes `NA`, produces a warning, and records a structured reason.

## Installation

### Released versions

Install from [CRAN](https://CRAN.R-project.org/package=cncleanr) (verified as 0.2.5 on 2026-10-12; table-header units were introduced in 0.2.6):

```r
install.packages("cncleanr")
```

Alternatively, pin GitHub v0.2.23, with more specific range failures, table-header units and diagnostic summaries:

```r
install.packages("pak")
pak::pak("Jorungandr/cncleanr@v0.2.23")
```

### Development version and source installation

For subsequent development changes, install the development branch (`main` changes over time; replace it with a full commit SHA to pin the code):

```r
install.packages("pak")
pak::pak("Jorungandr/cncleanr@main")
```

The development version remains one R package with one R API and registered C numeric/character-normalization routines. Source installation requires build tools; it fails without a suitable compiler rather than silently installing a pure-R variant.

Since 0.2.9, normalization explicitly rejects malformed UTF-8 (such as truncated byte sequences)
instead of continuing with damaged text. Encoding errors are not ordinary numeric parsing failures:
they also stop with `strict = FALSE`, without returning a usable partial result.
Import or convert data using its actual encoding first; valid UTF-8 and Latin-1 handling is unchanged.
Since 0.2.13, failures identify the originating `x` or `na` argument and first
original position, not a deduplicated/fallback position (for example, position 3).

- Windows: install [Rtools](https://cran.r-project.org/bin/windows/Rtools/) matching your R version.
- macOS: use Xcode Command Line Tools and a C compiler compatible with R; see the [official R installation guide](https://cran.r-project.org/doc/manuals/r-release/R-admin.html#macOS).
- Linux: provide a C compiler, `make`, and R development files; see the [official source-package installation guide](https://cran.r-project.org/doc/manuals/r-release/R-admin.html#Installing-packages).

The package itself has no Fortran, OpenMP, or additional runtime R dependency. A prebuilt binary compatible with your system and R version does not require local compilation of this package. Installing GitHub `main` is a source installation; do not assume that a matching binary exists.

Restart R after installation, then check the version and path actually loaded:

```r
library(cncleanr)
packageVersion("cncleanr")
find.package("cncleanr")
parse_cn_number(c("3万", "１２．５％"))
#> [1] 30000.000     0.125
```

The v0.2.8 release tag contains this optimization round; source installation requires the build tools above. Since `main` can still change, use a fixed tag or record the installed commit SHA for reproducibility.

### Performance and release preparation

See the [next-release preparation](docs/release-next.md) for cross-platform validation and a user-facing change summary.

Development benchmarks: [native numeric acceleration](docs/native-optimization.md), [qualifier/character-normalization optimization](docs/qualifier-optimization.md), [mixed-batch optimization](docs/mixed-optimization.md), and [formatted-number optimization](docs/formatted-optimization.md). Timing depends on input format and repetition; no universal latency is guaranteed.

The development version shares a native scan for full-width characters and PDF minus signs across number, quantity and range parsing, retaining whitespace-grouping validation. A local million-row full-width sample improved from 0.99 to 0.66 seconds; see the formatted-number benchmark above.

Whitespace removal now reuses this native scan. Spaces between digits are still checked for valid grouping first, so `1 2` is not silently parsed as `12`.

See the [performance closeout](docs/performance-final.md) for 100k/million-row measurements across all three parsers with complete diagnostics retained. Future maintenance prioritizes correctness, compatibility and real issues; no universal 0.1-second latency is promised.

0.2.14 rescues very long significands (for example, 5,000 digits with a compensating
exponent) while retaining tail direction at rounding boundaries. The repair runs
only in the long, extreme-value fallback; ordinary fast paths are unchanged.
See the [repair and performance validation](docs/long-decimal.md).

## Enterprise revenue cleaning example

See the [systematic hardening record](docs/systematic-hardening.md) and
[snapshot reproduction and audit entry points](docs/data-audit-reproduction.md).

Complete walkthrough: [real financial tables, mixed units, and failure tracing](docs/financial-table-example_EN.md).

Open-data example: [separate missing values, error markers, and mixed text](docs/open-data-cleaning_EN.md).

CSV workflow: [preserve source text and identifiers, handle column units, and export problems](docs/csv-cleaning_EN.md).

Advanced workflow: [batch merging, chained selection/sorting and CSV diagnostics](docs/cleaning-workflows_EN.md).
Repository `main` also provides an [incremental summary example](docs/cleaning-workflows_EN.md#keep-only-incremental-summaries-not-every-parsed-batch)
using `cn_summary()` without retaining parsed batches. The accumulator ships
since v0.2.20; older fixed assets remain unchanged.
CSV is an interchange format, not a bit-for-bit double round-trip or an R
attribute backup; use RDS for lossless R storage as described in the CSV guide.
Repository CI also executes literal R examples from both READMEs, excluding
installation commands. Optional `units` examples run only when available, with
any unexecuted blocks explicitly reported.
These examples/tests ship with 0.2.14, without changing existing batch-merging or diagnostic-preservation rules.

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

- `万`, `亿`, and `万亿` magnitude suffixes, plus thousand-yuan amounts (`千元`, so `1.5千元` becomes `1500`);
- `元`, `人民币`, `￥`, `¥`, `RMB`, `CNY`, `块`, and `块钱` currencies;
- percentages and scientific notation;
- full-width digits, punctuation, exponent letters, and common PDF minus signs;
- valid three-digit grouping with regular, non-breaking, narrow, or ideographic spaces;
- regular negative signs and accounting parentheses;
- configurable missing-value markers.

Whitespace between digits is accepted only when it forms valid three-digit grouping: `1 234` becomes `1234`, while `1 2` and `12 34` are reported instead of being silently concatenated.

### Explicit compound quantities

Since GitHub 0.2.20, two or three explicitly suffixed terms can combine
`万亿`/`亿`/`万` in strictly descending, distinct order. Each coefficient may be
an unsigned decimal with valid comma grouping. Signs, currency markers and
accounting parentheses apply to the entire expression:

```r
parse_cn_number(c("1亿2000万", "1万亿2亿3万", "-￥1亿2000万元"))
# Values: 120000000; 1000200030000; -120000000
parse_cn_quantity("约1亿2000万")$value
#> [1] 1.2e+08
parse_cn_range("1亿2000万-2亿")$upper
#> [1] 2e+08
```

Implicit tails such as `3万5`/`3万5000元`, reversed/repeated magnitudes, internal
currency markers, per-term scientific notation, interdigit whitespace grouping
and percentages are outside this compound grammar. Existing single-term grouped
and scientific forms remain supported. Every `unit=` header conflicts with
compounds. Ranges containing a compound endpoint require explicit trailing units
at both ends: `1-2亿3000万` never guesses that the left endpoint means 10,000.
Components and their sum must be finite; double addition is not exact decimal
money arithmetic.

## Table-header units

When the header says "thousand yuan" but cells contain bare numbers, supply `unit` explicitly:

```r
parse_cn_number(c("123.5", "1.5千元", "暂无"), unit = "千元")
#> [1] 123500   1500     NA
```

Supported units are `元`, `百元`, `千元`, `万`, `万元`, `亿`, `亿元`, `万亿`, and `万亿元`.

GitHub 0.2.21 adds hundred-yuan support using the thousand-yuan rules:

```r
parse_cn_number("3百元")                 # 300
parse_cn_number(c("3", "3百元"), unit = "百元") # 300 300
parse_cn_quantity("约3百元")$value       # 300
parse_cn_range("3-5百元")$upper          # 500
```

Only the complete monetary unit `百元` is supported, not bare `百` or `百块`.

Since 0.2.22, quantities and ranges also accept a table-header `unit`
(default `NULL`, no conversion):

```r
parse_cn_quantity("约3", unit = "百元")$value   # 300
parse_cn_range("3-5", unit = "千元")$upper     # 5000
parse_cn_range("3-5千元", unit = "千元")$upper # 5000
```

Explicit units must match the header multiplier and are not scaled twice;
percentages conflict with header units. With `unit` supplied, numeric infinities
and overflow become diagnosed failures, while missing values stay missing.
Infinite open ends generated from textual bounds (such as the upper `Inf` in
“大于3”) are unaffected.

Since 0.2.23, range failures retain specific causes such as unit conflicts and
overflow. Uniquely split candidates identify the `left range endpoint` or
`right range endpoint`. Parsed values and the problem-table schema are unchanged,
but `reason` strings and `cn_summary()` reason groups can become more specific;
do not rely on previous generic reason text. Missing endpoints, multiple split
candidates and digit-grouping failures retain conservative diagnostics.

0.2.24 unifies shared units in accounting ranges: `(3万)-5万` and `(3)-5万`
both mean -30000 to 50000. **Compatibility note:** `(3万)-5` now has that
same interpretation, rather than an upper bound of 5. Explicit units are not
appended twice; compound quantities still do not infer shared units.
Parser input and `na` must be dimension-free vectors; explicitly select a column
from matrices/arrays first. `cn_summary()` rejects reversed bounds, invalid
qualifiers and inconsistent missing/inclusivity flags, but plain R objects still
cannot prove diagnostic provenance: summarize before modifying results.
Bare values inherit the header unit. Explicit units with the same multiplier
are converted only once (`万` and `万元` have the same multiplier). Different
explicit multipliers and percentages are reported as problems, not overridden.
Omitting `unit` preserves existing behavior. With `unit`, numeric input is also
scaled, `NA`/`NaN` remain missing, and `Inf`, `-Inf`, or conversion overflow are
reported as problems. This argument is only available in `parse_cn_number()`;
it does not read or infer table headers.
Since 0.2.15, numeric input also respects applicable `as.double()` S3 methods
before header scaling and missing detection, retaining original names. See
[conversion consistency validation](docs/numeric-conversion.md).
Apply header units only to relevant monetary rows or columns. EPS (yuan/share),
headcounts, or ratios in the same table may have their own units and must not
receive a blanket monetary multiplier.

## Imported types and unit safety

Since 0.2.18, numeric conversion methods must return a double vector of the
original length, without a class or dimensions. Malformed results error rather
than changing row counts or returning text as numbers. Method warnings propagate.

Since 0.2.17, all three parsers respect `haven_labelled_spss` `na_values` and
`na_range`. User-defined missing codes such as 97/99 no longer become actual
values, and character missing codes no longer become parse failures. Ordinary
labels retain their underlying codes, not label text. Existing NA/NaN/tagged-NA
payloads are preserved without a header; header scaling keeps its established
missing-value output rules.

Direct `units` objects now error, including empty or dimensionless units, rather
than silently losing their meaning. Choose and convert units first, then remove
them explicitly:

```r
x <- units::set_units(c(1000, 2000), "m")
x <- units::set_units(x, "km")
parse_cn_number(units::drop_units(x))
#> [1] 1 2
```

This is not automatic unit recognition or monetary conversion. These third-party
packages are not runtime dependencies. Integer64-to-double precision warnings
still propagate; large integers and decimal money are not guaranteed exact.
See [imported-type validation](docs/import-types.md) for scope and reproduction.

## Qualified quantities

GitHub 0.2.7 accepts one approximation prefix paired with
`左右`: `约15%左右` returns `value = 0.15` and `qualifier = "approx"`.
Mixed inequalities and repeated prefixes or suffixes remain invalid.
Approximations do not define a deterministic range. This change is not in
the GitHub 0.2.6 release.

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
- `超3万` means greater than 30,000 and excludes the boundary;
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

A shared suffix in a form such as `3-5万` is applied to both endpoints of the numeric range; `3-5千元` means 3,000 to 5,000. Reversed ranges and invalid endpoints are reported as problems.
Signs in scientific notation are not treated as range separators, so both `1e-3` and `1e-3-2e-3` are parsed correctly.

Since 0.2.10, whitespace digit grouping is validated independently at each endpoint:
`1 234-2 345` returns `1234` to `2345`, and `1 234-2 345万元` returns
`12340000` to `23450000`. `1 23-2 345` still reports invalid grouping rather
than silently joining digits; `2 345-1 234` reports reversed bounds. A single
approximate value does not define explicit bounds.

Since 0.2.11, textual endpoint missing markers are checked both before and after
shared-unit propagation. With `na = "0"`, `0-5万` reports an invalid endpoint
instead of resurrecting `0` by appending `万`; strict mode raises an error.
Matching uses normalized text, not numeric equality, so `0万-5万` does not match
the marker `"0"`. A whole cell matching `na` remains an ordinary missing value
without a parsing problem.

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

### Summarize cleaning quality

Since GitHub 0.2.19, `cn_summary()` returns two ordinary tables in a list without
reparsing the original text:

```r
parsed <- suppressWarnings(parse_cn_number(c("3万", "bad", "暂无", NA)))
report <- cn_summary(parsed)
report$counts
#>   total parsed missing failed
#> 1     4      1       2      1
report$reasons
#>                                                reason count
#> 1 value does not match the supported number syntax     1
```

Parsed, missing and failed counts sum to the total; `reasons` counts failures in
first-occurrence order. Quantity/range results are supported, including valid
qualifiers and open bounds. Numeric `Inf`/`-Inf` count as parsed; NA/NaN count as
missing unless diagnosed as failures. Repeated selections count repeatedly.
Summarize before ordinary subsetting, mutation, binding or CSV export, or pass
a `cn_subset()` result. Obvious malformed diagnostics error, but lost diagnostics
cannot be recovered and arbitrary modifications cannot always be detected.
Only an explicit summary call scans results; parsers do no additional work.

Ordinary mode returns `NA` at failed positions, preserves the other usable results, and emits a warning. If a cleaning workflow must stop as soon as any row fails, set `strict = TRUE`:

```r
parse_cn_number(c("2万", "abc"), strict = TRUE)
```

Custom missing values, such as the supported default `"暂无"`, are not parsing failures in either mode.

### Preserve diagnostics when filtering or sorting

Since 0.2.13, `cn_subset()` explicitly filters, reorders or repeats selected rows
without changing the numeric-vector/data-frame return types:

```r
parsed <- suppressWarnings(parse_cn_number(c("bad", "2万", "wrong", "1万")))
rows <- c(3L, 2L, 1L, 3L)
selected <- cn_subset(parsed, rows)
cn_problems(selected)$index
#> [1] 1 3 4
cn_problems(selected)$value
#> [1] "wrong" "bad" "wrong"
clean <- cn_subset(parsed, !is.na(parsed))
sorted <- cn_subset(parsed, order(parsed, na.last = TRUE))
```

Indices refer to positions in the current result. Keep `rows` and use
`rows[cn_problems(selected)$index]` to recover original identifiers. Repeated
selections repeat problems. Logical selections must be full-length; integer-valued
numeric S3 selectors use `as.double()` once before validation and indexing since
0.2.16, including integer64. Preserve source identifiers alongside the actual
selection; see the [system audit](docs/system-audit.md). Integer-valued
numeric indices support zero/negative base-R selection, but not missing,
fractional or out-of-range indices. Ordinary `[]`, mutation and binding still do
not track diagnostics. Use this helper first; it cannot recover lost/stale
attributes. See the [executable diagnostic workflow and evidence](docs/diagnostic-workflow.md).

## Common failure reasons

The `reason` returned by `cn_problems()` can be used directly to locate these problems:

| Situation | Example | `reason` |
| --- | --- | --- |
| Unsupported syntax | `3万abc` | `value does not match the supported number syntax` |
| Invalid whitespace grouping between digits | `1 2` | `digits use invalid whitespace grouping` |
| Repeated or conflicting qualifiers | `超过3万左右` | `multiple or conflicting qualifiers` |
| Reversed range bounds | `5万-3万` | `range lower bound is greater than its upper bound` |
| Invalid range endpoint | `3万-abc` | `one or both range endpoints are invalid` |
| Value outside the finite double range | `1e308万` | `value is outside the finite double range` |

When parsing fails, first use ordinary mode and inspect `cn_problems()`. Use `strict = TRUE` only when the cleaning workflow must stop if any row fails.

## Development and testing

The project includes two test suites:

- `tests/parser.R`: a dependency-free package check suite;
- `tests/testthat/`: the complete development suite for edge cases and error behavior.

Every push is checked on Linux, macOS, and Windows with GitHub Actions.

For a local Windows R shutdown crash caused by `cli`, use
[`docs/run-r.ps1`](docs/run-r.ps1) to launch R. It supplies the architecture
environment variable only when missing, leaves the global environment unchanged,
and preserves the actual exit code. See the [environment diagnosis](docs/environment-diagnosis.md).

## Scope

Results use double precision, not arbitrary-precision integer or decimal money
arithmetic; integers above `2^53` may round. Since 0.2.12, representable final
values such as `1e309%` and `1e-330万亿` are rescued before intermediate
overflow/underflow loses information. Nonzero text that finally rounds to zero
reports underflow. Fractional spacing is unsupported: both `.1 234` and
`0.1 234` are rejected. Percentage/non-percentage ranges such as `3%-5元`
are rejected; `3-5%` and `3万-5亿` remain valid. More than eight candidate
range separators are rejected to bound malformed-input resource use.

Use `cn_subset()` to filter/sort, or extract `cn_problems()` before ordinary
`[]`, mutation or binding, which can drop the attribute or retain stale indices.
Missing markers match text, not numerical equality; qualified quantities still
match the whole cell. Matrix/array flattening is unchanged; pass the target column
explicitly. Existing single-term accounting-parenthesis suffix propagation and whole-batch errors on
malformed UTF-8 retain their existing policies.

CI covers Linux R release/devel/oldrel-1 and Windows/macOS R release, not every
older R version, locale or hardware architecture.

`cncleanr` focuses on Arabic digits combined with Chinese data conventions, such as `3.2亿元`, `约5万`, and `3万-5万`. Fully written Chinese numerals such as “一万三千” are currently outside the package's core scope.

## License

MIT
