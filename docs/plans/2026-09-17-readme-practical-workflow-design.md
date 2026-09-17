# README Practical Workflow Design

## Goal

Make the existing package immediately usable from the bilingual README without
adding API surface or package dependencies. A reader should be able to copy one
complete example, clean a realistic column, inspect rejected rows, and export
the result.

## Chosen approach

Add a compact, executable base R workflow directly to both `README.md` and
`README_EN.md`. The example uses a small enterprise revenue table containing an
exact value, approximate and lower-bound values, a configured missing marker,
and a malformed value.

This is preferred over a vignette because it remains visible on the repository
front page and does not add `knitr` or `rmarkdown` dependencies. It is preferred
over a separate example script because new users do not need to discover or
open another file.

## Documentation structure

The Chinese and English READMEs will contain matching sections in the same
order:

1. A complete workflow that creates or reads a data frame, parses the revenue
   column with `parse_cn_quantity()`, joins the returned value and qualifier,
   inspects `cn_problems()`, maps problem indices back to source rows, and shows
   how to export the cleaned table.
2. A compact return-value reference for `parse_cn_number()`,
   `parse_cn_quantity()`, `parse_cn_range()`, and `cn_problems()`.
3. A qualifier reference explaining the six stable qualifier values and their
   boundary semantics.
4. A troubleshooting reference for unsupported syntax, invalid whitespace
   grouping, conflicting qualifiers, reversed ranges, invalid endpoints, and
   finite-double overflow.
5. A concise explanation of warning mode versus `strict = TRUE`.

The English README translates the prose while preserving Chinese input strings,
function calls, column names, and displayed values so both versions describe
the same behavior.

## Data flow and failure handling

The workflow keeps the original text column beside parsed output. Non-missing
inputs that cannot be fully parsed become missing parsed values, while their
source text, row position, and reason remain available through
`cn_problems()`. Missing markers are not treated as errors. The example uses
`suppressWarnings()` only because it immediately inspects the structured problem
table; the surrounding text makes this trade-off explicit.

## Verification

Add a testthat case that executes the data transformation represented in the
README and checks cleaned values, qualifiers, problem indices, and source-row
mapping. Run the complete testthat suite, the dependency-free tests, and
`R CMD check`. Verify that both READMEs retain matching headings and examples.

## Non-goals

- No parser rule changes.
- No new exported functions.
- No vignette framework or new suggested packages.
- No release tag until the documentation work has passed CI.
