# Real business workflows: finance, salaries and statistics

[中文](business-workflows.md)

This tutorial validates text import, field-specific parsing, separate review,
export and read-back. The scripts are external project audits; the six public
cncleanr functions remain unchanged.

## Sources and reproduction

Four retained, hash-locked real snapshots are reused, not newly collected:

| Scenario | Source | Use in this audit |
| --- | --- | --- |
| Financial reports | [CFQA](https://github.com/ygan/CFQA), pinned test split | 1418 numeric spans from 2100 answers, not full-report parsing |
| Salaries | [Labour Ministry vacancies, 44062](https://data.gov.tw/dataset/44062) | Endpoints, pay modes and two manually selected complex descriptions from 1000 jobs |
| Statistics | [Employment by education and age, 34112](https://data.gov.tw/dataset/34112) | 1050 fields across 25 areas in year 114 |
| Supplemental monetary headers | [Tourism benefits, 42792](https://data.gov.tw/dataset/42792) | 800 estimated-benefit fields in ten-thousand TWD, not corporate accounts |

The government providers are the Workforce Development Agency, DGBAS and Tourism
Administration. Their datasets use the [Open Government Data License v1](https://data.gov.tw/license);
retain attribution. The pinned CFQA [LICENSE](https://github.com/ygan/CFQA/blob/61c9ec3c4335d0411a1735cd228af8b3ead114fc/LICENSE)
is MIT, Copyright (c) 2025 ygan. Raw files and generated business tables stay in local outputs.

Follow [snapshot reproduction](data-audit-reproduction.md), install this checkout,
then run from the repository root:

```sh
python docs/business-validation.py
Rscript docs/business-validation.R <installed-library>
```

The builder uses Python's standard library and independent Decimal arithmetic,
reusing the existing financial-span extraction rules. R needs the installed
cncleanr package. All four source SHA256 hashes are checked first; a mismatch
stops the build rather than changing the baseline. Attempts to download new
budget, recruitment and unemployment resources on 2026-10-30 timed out/reset.
New snapshot downloads: zero. This adds workflow coverage, not new data volume
or a claim about current vacancies.

## 1. Import source text and provenance

```r
library(cncleanr)
cases <- read.csv("outputs/business-validation-2026-10-30/cases.csv",
  colClasses = "character", na.strings = character(),
  check.names = FALSE, fileEncoding = "UTF-8")
```

Each case retains case_id, original record_id, source_row, field, original text,
parser input and an explicit transformation. Financial source_row identifies the
original answer record; extracted spans are distinct from complete answers.
Salary record IDs identify snapshot rows, not stable vacancy keys. Retain your
own stable business IDs in production.

## 2. Parse according to field meaning

```r
parse_cn_quantity("6.38%")
parse_cn_number("35000", unit = "元")
parse_cn_range("35000~45000")
```

Financial qualifiers remain explicit rather than becoming exact values; 39
negative expectations are also checked. The 692 valid salary intervals are
derived from two endpoint fields, not original Chinese range expressions.
Construct closed intervals only when both endpoints are positive and ordered.
Neither zero nor a missing marker establishes an infinite upper bound.
Keep monthly, hourly, daily and piece-rate pay separate; do not silently convert
hours or compare pay modes as if they had the same denominator.

For 525 percentage-point fields, metadata explicitly authorizes appending `%`;
Decimal divides their expectations by 100. Another 525 fields retain their source
unit of thousand persons. Do not use a monetary thousand-yuan header for people
or silently convert those counts. Tourism money explicitly uses `unit="万元"`.

## 3. Separate missing values, parser failures and business review

Do not drop every NA row:

- Ordinary missing values have no attached parser problem.
- Parser failures retain cn_problems() reasons, source text and source rows.
- 308 salary records without a defensible closed interval are flagged for
  business review before attempting interval parsing.

The 77 education/certification pay-rule descriptions and two complete bonus,
multiple-salary or negotiation descriptions should not become single intervals.
Spreadsheet errors, unreported benefits and multi-part benefit descriptions also
need review. A correct rejection avoids a misleading number; it does not resolve
the underlying business meaning.

## 4. Export, read back and preserve precision

Each domain writes separate `*-cleaned.csv` and `*-review.csv` files. Pay modes,
source units, qualifiers and inclusive bounds remain explicit. Read-back checks
all character columns and compares numeric values with per-row tolerance 1e-12.

`parsed-objects.rds` stores grouped results with case IDs and must read back
identically, including diagnostics. CSV does not store R attributes or guarantee
binary64 tail bits, negative zero or NA/NaN distinctions. See
[CSV limitations](csv-cleaning_EN.md).

## Results

| Scenario | Correct parse | Correct missing | Expected rejection | Business review, not parsed |
| --- | ---: | ---: | ---: | ---: |
| Financial spans | 1412 | 0 | 6 | 0 |
| Salaries | 2307 | 385 | 79 | 308 |
| Statistics | 1050 | 0 | 0 | 0 |
| Monetary headers | 670 | 96 | 34 | 0 |
| Total | 5439 | 481 | 119 | 308 |

6347 cases; 427 review records; zero wrong parses/acceptances in this bounded
audit. This is not a general accuracy score or financial fact certification.
No new production parser defect was reproduced. Package version remains 0.2.25.
CI runs 22 attributed offline cases, while the full 6347 cases require the local
snapshots; these totals are distinct. The real monetary header uses ten-thousand
yuan. Source data were not rewritten to manufacture hundred/thousand-yuan cases.
