# Configure CSV cleaning with review and quality summaries

[中文](table-cleaning-guide.md)

Run from the complete repository root with cncleanr 0.2.25 installed.
The example function `clean_cn_csv()` is defined in `docs/table-cleaning.R`.

```r
source("docs/table-cleaning.R", local = TRUE, encoding = "UTF-8")
```

Each `spec` row configures one field. `column` names the CSV column, `parser`
selects `number`, `quantity` or `range`, and `unit` gives a documented monetary
header unit or an empty string. Here amount uses hundred-yuan scaling, interval
uses thousand-yuan scaling, and estimate retains its qualifier.

```r
raw <- data.frame(
  id = c("0001", "0001", "0003", "0004"),
  amount = c("3", "bad", "暂无", "4百元"),
  estimate = c("约3万", "5万+", "暂无", "wrong"),
  interval = c("大于3", "3-5", "暂无", "bad")
)
input <- tempfile(fileext = ".csv")
write.csv(raw, input, row.names = FALSE, fileEncoding = "UTF-8")
spec <- data.frame(
  column = c("amount", "estimate", "interval"),
  parser = c("number", "quantity", "range"),
  unit = c("百元", "", "千元")
)
output_dir <- tempfile("cleaned-run-")
result <- clean_cn_csv(input, spec, output_dir, id_column = "id", chunk_size = 2L)
result$summary
result$review
stopifnot(identical(result$review$source_row, c(2L, 4L, 4L)))
stopifnot(identical(result$cleaned$amount__value, c(300, NA, NA, 400)))
```

For your own data, replace `input` with the CSV path and `output_dir` with a new
output directory. The example uses temporary paths that may be removed at
session exit. Input must be UTF-8 with unique column names. Text import preserves
leading zeros, repeated IDs and original fields. Percentage fields should carry
`%` according to their source definition. Header units accept 元, 百元, 千元,
万/万元, 亿/亿元 and 万亿/万亿元.
Malformed encoding, quoting or field counts stop the import.

## Output files

| File | Contents |
| --- | --- |
| `cleaned.csv` | Source columns, `.source_row`, parsed values/qualifiers/bounds and statuses |
| `review.csv` | Source position, ID, field, original text and reason for each failed field |
| `summary.csv` | Per-field total, parsed, missing and failed counts |
| `reasons.csv` | Per-field failure counts grouped by reason |
| `result.rds` | Complete returned list containing the four tables and spec |

Generated names include `amount__value`, `estimate__qualifier`, `interval__lower`,
`interval__upper_inclusive` and `amount__status`. Status is parsed, missing or
needs_review. Collisions with generated names or `.source_row` raise an error.
Review rows follow configuration and source-row order. Repeated IDs retain
their positions. source_row identifies data records, while multiline CSV cells
may occupy multiple physical lines. With `id_column = NULL`, review IDs are missing.

```r
restored <- readRDS(file.path(output_dir, "result.rds"))
stopifnot(identical(restored, result))
review <- read.csv(file.path(output_dir, "review.csv"), colClasses = "character",
  na.strings = character(), fileEncoding = "UTF-8")
stopifnot(identical(review$id, c("0001", "0004", "0004")))
```

CSV export can round numeric tail digits, and empty cells merge some missing
representations. Preserve original text, statuses, qualifiers and boundary flags.
Use your saved RDS for exact R object storage. Files are written to a sibling
staging directory and published together after all writes succeed. An existing
output directory raises an error.

`chunk_size` controls parsing batches and defaults to 10000 rows. The full CSV
and final results remain in memory. Summaries accumulate per field, and review
records remain available until export completes.
