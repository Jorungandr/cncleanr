# CSV import, cleaning and problem export

[中文](csv-cleaning.md)

See [chunked/chained workflows](cleaning-workflows_EN.md) for batch merging,
repeated selections and the shared executable example/regressions.

Run the [complete example](csv-cleaning.R):

```powershell
Rscript docs/csv-cleaning.R
```

All inputs are synthetic demonstrations, not additional real-data coverage.
The script creates `input.csv`, `cleaned.csv` and `problems.csv` in a unique
directory under the current R session's temporary directory.
It may be removed at session exit. For persistent results, adapt the example
to explicit new output paths and verify that files do not already exist before writing.

## Important decisions

- `read.csv(..., colClasses='character', na.strings=character())` preserves source
  text: identifier `0001` is not converted to `1`, and `暂无` remains available for review.
- The monetary column is explicitly defined in ten thousand yuan. Only this
  column uses `unit='万元'`; its output unit is yuan.
- Headcounts retain their source text: `0007` is preserved alongside numeric value 7.
- The share column is defined in percentage points. Bare `11.81` receives `%`,
  while `5%` is left unchanged, yielding proportions 0.1181 and 0.05.
  Do not apply this transformation to columns with unknown semantics.
- `cn_problems()` provides input positions; the review export preserves data-row
  position, identifier, field, original text and reason. Positions are not physical
  CSV line numbers, which may include a header or multiline cells.

`1 2` and `bad` require review. Default markers `暂无` and `-` are missing values,
not problem rows. Different fields in the same source row can produce separate
problems; do not deduplicate by row. Warnings are suppressed only because the
complete structured problem table is subsequently inspected.

After export, the script reads the files back and checks original text, leading
zeros, proportions and problem text. Numeric missing values are exported as empty
cells; original columns retain the source markers.
CSV does not store column types. Excel may still display identifiers as numbers
when opening a file automatically; use text import with an explicit identifier type.
This example handles UTF-8 CSV, not automatic GBK detection, Excel files or business semantics.

## CSV is not a lossless backup of an R object

The round-trip assertions cover this example, not bit-for-bit preservation of
arbitrary doubles. Ordinary `write.csv()` can round trailing significant digits
(for example, `1 + 2^-52` can be written as `1`) and lose the sign of negative zero.
With `na=''`, both `NA` and `NaN` become empty cells and cannot be distinguished
from that column alone; a source empty string also needs a separate missing-status
field. Text `Inf`/`-Inf` is not missing, and an open infinite range bound must not
be confused with an inclusive numeric infinite point.

For CSV interchange retain source text, IDs, status, qualifiers/inclusivity flags
and a separate review table, not just numeric columns. To preserve the current
R object, including problem attributes, NaN and negative zero, use:

```r
saveRDS(parsed, "parsed.rds")  # First ensure this path will not overwrite needed data.
restored <- readRDS("parsed.rds")
stopifnot(identical(restored, parsed))
```

Read only RDS files you saved or obtained from trusted sources. RDS is not a
general cross-application replacement for CSV.
