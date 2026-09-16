# cncleanr

`cncleanr` safely parses compact numeric values commonly found in Chinese
tables and spreadsheets. The first development version is deliberately small:
it parses values, reports ambiguous input, and does not modify data frames
automatically.

```r
parse_cn_number(c("1.25万", "3亿元", "12.5%", "暂无", "—"))
#> [1] 1.25e+04 3.00e+08 1.25e-01       NA       NA
```

Supported forms include:

- `万`, `亿`, and `万亿` magnitude suffixes;
- `%` and the full-width `％`;
- full-width digits and punctuation;
- negative signs and accounting parentheses;
- configurable Chinese missing-value markers.

Values that cannot be parsed completely are never silently truncated.
Non-strict parsing returns `NA`, warns once, and stores details in the
`problems` attribute. Use `strict = TRUE` to stop on the first batch of invalid
values.

The package has a dependency-free base R check suite under `tests/parser.R`
and a more detailed development suite under `tests/testthat/`.
