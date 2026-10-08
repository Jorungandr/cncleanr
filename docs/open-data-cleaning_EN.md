# Open-data cleaning: missing values versus problems

[中文](open-data-cleaning.md)

The cross-domain audit found no new numeric parsing errors, but real tourism
cells contain spreadsheet errors, unavailable-statistic notes, and multiple
numbers in one cell. Parsing failures must not all be treated as missing values.

Run the [complete executable example](open-data-cleaning.R):

```powershell
Rscript docs/open-data-cleaning.R
```

The six cells retain selected text from the [Taiwan tourism open dataset](https://data.gov.tw/dataset/42792).
`source_row` identifies positions in this example, not row numbers in the original CSV.
The example demonstrates classification, not validation or correction of activity statistics.

| Original text | Value | Handling |
| --- | --- | --- |
| `10,536` | 10536 | Parsed; unit remains visitor visits |
| `-` | NA | Explicit missing marker |
| `#VALUE!` | NA | Review the source spreadsheet error |
| `未統計` | NA | Explicitly designated as missing in this example |
| `27,091(外國跑者3,249人)` | NA | Manually distinguish the total from its subset |
| `活動仍辦理中` | NA | Preserve the ongoing-activity note for review |

The code preserves original text, units and source positions, and uses indices
from `cn_problems()` to mark `needs_review`, rather than relying on `is.na()` alone.
Warnings are suppressed only because every structured problem is inspected.
Remove `未統計` from `missing_markers` if that note should require review instead.
Custom `na` replaces the default marker list; it does not append to it.

## Column units must be handled separately

The script also includes three synthetic unit examples; they are not additional real-data observations:

| Text | Source unit | Output | Output unit |
| --- | --- | --- | --- |
| `1.5` | Thousand persons | 1.5 | Thousand persons |
| `11.81` | Percent | 11.81 | Percent |
| `316` | Ten thousand yuan | 3160000 | Yuan |

The first two rows retain their units. Only the monetary row explicitly uses `unit='万元'`.
To obtain a proportion, the caller separately divides 11.81 by 100 to get 0.1181.
Do not apply `unit='千元'` to headcounts or append `%` to every numeric field.

There is no physical-unit conversion, automatic first-number extraction, or file export.
All five GitHub R/OS check jobs run the assertions in this same script to detect example regressions.
See the [cross-domain report](broad-data-audit-report.md) for snapshot provenance and reproducible checks.
