# Chunked cleaning, chained selections and diagnostic export

[中文](cleaning-workflows.md) | [Complete executable example](../inst/examples/chunked-cleaning.R)

These examples/regressions ship with GitHub v0.2.14, without changing existing
workflow parsing rules. Existing v0.2.13 tags/assets remain unchanged. The script
uses only APIs already available in 0.2.13. Its file is not in that older release;
run it from the checkout root:

```sh
Rscript inst/examples/chunked-cleaning.R
```

After installing v0.2.14 (or a newer checkout), alternatively run:

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

Regression tests and all five platform CI jobs execute this same example rather
than maintaining another workflow implementation inconsistent with the guide.

## Validation (2026-10-15)

Example checkpoint: `0574b41d7e4cf4a2f6772ff3de3949a76ee67e8e`.
[All five CI checks](https://github.com/Jorungandr/cncleanr/actions/runs/38690442453)
were OK with 795 assertions each; Linux PDF/HTML manuals passed. Local exact
working-tree archive `--as-cran --no-manual` was OK, without incoming or local PDF
checks. This example/test update changes no parser R/C code, version or existing
release assets and is not a fresh CRAN pre-submission certification.
