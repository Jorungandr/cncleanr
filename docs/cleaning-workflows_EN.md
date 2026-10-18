# Chunked cleaning, chained selections and diagnostic export

[中文](cleaning-workflows.md) | [Complete executable example](../inst/examples/chunked-cleaning.R)

The original cleaning example ships since GitHub v0.2.14. The current checkout
adds incremental summaries using the existing 0.2.19 `cn_summary()` API, without
changing parsing rules. Install package 0.2.19 or later before running it.
The fixed v0.2.19 tag/asset still contains the earlier
example, not this new accumulator. Run from a checkout containing this change:

```sh
Rscript inst/examples/chunked-cleaning.R
```

After installing GitHub `main` containing this change, alternatively run the
updated installed example:

```r
source(system.file("examples", "chunked-cleaning.R", package = "cncleanr"),
       encoding = "UTF-8")
```

Eight synthetic rows exercise all three parsers, not additional real-data
coverage. The script returns status/review tables and checks CSV in a unique
temporary directory removed on completion. For persistent output, choose new
explicit paths and avoid overwriting source files.

## 1. Extract batch problems before binding plain tables

`cn_problems()` indices are local to the input batch. Neither `rbind()` nor
`c()` automatically merges problem attributes or converts indices to global rows.

```r
rows <- batches[[i]]
parsed <- suppressWarnings(parse_cn_number(raw$text[rows]))
p <- cn_problems(parsed)
source <- rows[p$index]
review <- data.frame(
  source_row = source,
  id = raw$id[source],
  original = raw$text[source],
  reason = p$reason
)
```

Use the same review-table schema even for problem-free batches. Bind plain
value/data tables and explicit review tables separately. The executable example
includes empty and problem-free batches and compares every value column with
whole-input parsing. That whole-input pass is a validation oracle, not required
extra production work. After binding ordinary tables, associate diagnostics
using explicit source IDs/review tables, not residual attributes.

## Keep only incremental summaries, not every parsed batch

The script's local `summarize_batches()` is example code, not a new package API.
It calls `cn_summary()` immediately after parsing each batch and keeps only four
totals and a named reason-frequency vector, not parsed batch objects or per-row
problems. `setdiff()` adds new reasons in cross-batch first-occurrence order.

Inspect the executable example's returned results:

```r
result <- source("inst/examples/chunked-cleaning.R", encoding = "UTF-8")$value
result$number$summaries$mixed$counts
#>   total parsed missing failed
#> 1     8      4       2      2
result$number$summaries$mixed$reasons
```

Quantity/range summaries live under `result$quantity`/`result$range`. Empty
batches add nothing; ordinary missing values are not failures. A source row in
multiple batches counts repeatedly, without deduplication. If each source record
must count once, ensure batches do not overlap. Batch order determines reason
first-occurrence order too.

Double accumulators avoid ordinary integer-addition overflow, but do not
guarantee exact integer counts beyond 2^53. Additional state grows with distinct
failure reasons; temporary parsing memory grows with the current batch. This is
not a constant-memory guarantee. The demonstration still holds source text in
memory; read the next chunk yourself for real file streaming. No forced `gc()`.

Summary-only work need not keep per-row records. If review is required, export
the current batch's problems before releasing it; original row positions cannot
be recovered from frequencies. Whole-input comparisons and multiple scenarios
are validation only, not extra production parses. The script's other cleaning/CSV
branches still retain ordinary result tables.

## 2. Separate missing inputs from failures before dropping NAs

Both may produce numeric `NA`, but only failures appear in the review table:

```r
status <- rep("parsed", nrow(raw))
status[is.na(values)] <- "missing"
status[review$source_row] <- "needs_review"
```

Save the complete review table first. Keeping only `!is.na(values)` removes both
missing and failed rows; a clean remaining result does not prove the original
inputs were error-free. Here source rows 2/5 fail, while 3/7 are ordinary missing
values. Use `value`/`lower` for quantity/range results, not the matrix returned
by `is.na()` on the entire data frame as a `cn_subset()` row selector.

## 3. Carry provenance through every selection

For an untouched parser result, `cn_subset()` indices always refer to its current
positions. Carry a separate source-row vector through each operation:

```r
source_rows <- seq_along(raw$text)
selected <- cn_subset(parsed, first)
source_rows <- source_rows[first]
selected <- cn_subset(selected, keep)
source_rows <- source_rows[keep]
selected <- cn_subset(selected, ordering)
source_rows <- source_rows[ordering]
p <- cn_problems(selected)
original_rows <- source_rows[p$index]
```

Here `parsed` is the full parser result at the start of this selection workflow,
not an ordinary bound table with added ID columns. Using only the final selector
after multiple operations loses provenance. Repeated failed source rows must
remain repeated; do not silently deduplicate by source row. The example's final
problem positions 4/5/6 map to original source rows 5/2/5.

## 4. Export values and reviews separately: CSV does not store R attributes

Preserve source text, IDs, data-row positions, field identity and reasons in
separate result/review files. This example also exports repeated-selection
problems and reads all files back, checking numeric values, logical bounds,
qualifiers, IDs, status, original text, reasons and source indices. Originals
contain quotes and newlines; source-row indices are not physical CSV line numbers.

`read.csv(..., colClasses="character", na.strings=character())` avoids automatic
identifier/missing-marker conversion. CSV cannot serialize `problems`, and
`cn_problems()` cannot recover that attribute from a reimported CSV. Spreadsheet
applications may further change display types; opening a file in Excel does not
replace these text round-trip checks.

These assertions cover the example's values only. Ordinary CSV can lose trailing
double digits, negative zero and the NA/NaN distinction. Use RDS for lossless R
object storage; see [CSV limits](csv-cleaning_EN.md#csv-is-not-a-lossless-backup-of-an-r-object).
Retain inclusivity flags for textual infinite bounds, not just `lower`/`upper`.

Regression tests and all five platform CI jobs execute this same example rather
than maintaining another workflow implementation inconsistent with the guide.
Additional regressions cover reordered/repeated source rows, irregular/empty
batches, quantities/ranges and RDS preservation of boundary doubles, NaN,
negative zero and diagnostics. Direct cross-parser numeric comparisons apply
only to shared exact-input syntax; qualifier/range semantics intentionally differ.

## Incremental summary validation (2026-10-18)

The current checkout's accumulator passed [all five platform checks](https://github.com/Jorungandr/cncleanr/actions/runs/39092573242),
with 1,442 assertions each and Linux PDF/HTML checks passing. See
[summary validation](summary-validation.md#incremental-example-on-main-after-v0219)
for scope and limits. This is not a new release; the fixed v0.2.19 asset does
not contain this example update.

## Historical consistency validation (2026-10-18)

Expanded workflow-boundary regressions and literal bilingual README execution
passed; see [consistency evidence](workflow-contract.md). Each of five platform
checks passed 1,301 assertions. This is not a new release: the existing v0.2.18
asset remains unchanged and still contains its 1,181-assertion suite.

## Historical validation (2026-10-15)

Example checkpoint: `0574b41d7e4cf4a2f6772ff3de3949a76ee67e8e`.
[All five CI checks](https://github.com/Jorungandr/cncleanr/actions/runs/38690442453)
were OK with 795 assertions each; Linux PDF/HTML manuals passed. Local exact
working-tree archive `--as-cran --no-manual` was OK, without incoming or local PDF
checks. This example/test update changes no parser R/C code, version or existing
release assets and is not a fresh CRAN pre-submission certification.
