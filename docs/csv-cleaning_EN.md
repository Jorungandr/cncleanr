# CSV import, cleaning and problem export

[中文](csv-cleaning.md)

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
