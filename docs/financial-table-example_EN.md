# From a real financial table to cleaned values

[中文](financial-table-example.md)

Requires the GitHub release cncleanr 0.2.6. Install with:

```r
pak::pak("Jorungandr/cncleanr@v0.2.6")
```

## 1. Preserve source text and assign units by row

The first four rows below use the 2019 column on printed page 6 of
[Suning's 2019 annual report](https://www.suning.cn/static/snsite/contentresource/2020-04-20/d4ce9420-8511-4ada-ac1a-7578761392c7.PDF).
The header says thousand yuan, but EPS explicitly uses yuan/share and ROE uses
percentages. The source was reviewed during release acceptance; this is not
automatic PDF extraction. The last three rows are synthetic demonstrations,
not errors in the original report.

```r
library(cncleanr)

raw <- data.frame(
  source_row = 1:7,
  metric = c("Revenue", "Net profit attributable to shareholders", "Basic EPS", "ROE",
             "Demo: missing", "Demo: malformed", "Demo: unit conflict"),
  text = c("269,228,900", "9,842,955", "1.07", "11.77%",
           "暂无", "1 2", "3万元"),
  kind = c("amount", "amount", "eps", "ratio", "amount", "amount", "amount")
)
cleaned <- raw
cleaned$value <- NA_real_
cleaned$output_unit <- ifelse(raw$kind == "amount", "yuan",
                             ifelse(raw$kind == "eps", "yuan/share", "ratio"))
problem_parts <- list()

for (kind in unique(raw$kind)) {
  rows <- which(raw$kind == kind)
  # Only monetary rows inherit thousand yuan; EPS and ratios do not.
  header_unit <- if (kind == "amount") "千元" else NULL
  parsed <- suppressWarnings(parse_cn_number(raw$text[rows], unit = header_unit))
  cleaned$value[rows] <- as.numeric(parsed)
  problems <- cn_problems(parsed)
  if (nrow(problems)) {
    # index is relative to this group's input, not the complete table.
    problem_parts[[kind]] <- cbind(
      raw[rows[problems$index], c("source_row", "metric", "text")],
      reason = problems$reason
    )
  }
}
problem_rows <- do.call(rbind, problem_parts)
rownames(problem_rows) <- NULL
cleaned
problem_rows
```

## 2. Check results and failures

The expected `cleaned$value` vector is:

```r
stopifnot(isTRUE(all.equal(cleaned$value,
  c(269228900000, 9842955000, 1.07, .1177, NA_real_, NA_real_, NA_real_))))
stopifnot(identical(problem_rows$source_row, c(6L, 7L)))
```

Revenue becomes 269,228,900,000 yuan and net profit 9,842,955,000 yuan.
EPS remains 1.07 yuan/share; 11.77% becomes the ratio 0.1177, not 11.77.
The missing marker `暂无` produces `NA` without a parsing problem.
Row 6 has invalid whitespace grouping; row 7 conflicts with the thousand-yuan
header. Both produce `NA` and appear in `problem_rows`, retaining source text
for manual review.

Warnings are suppressed here to inspect one consolidated problem table, not
to ignore failures. To save the results:

```r
write.csv(cleaned, "cleaned.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(problem_rows, "problems.csv", row.names = FALSE, fileEncoding = "UTF-8")
```

These commands write to the current working directory and overwrite existing
files with the same names. Use `strict = TRUE` if any parsing problem must stop
the workflow. Unit assignment is your responsibility: the package does not
infer business meanings such as EPS or headcounts, or verify financial facts.
