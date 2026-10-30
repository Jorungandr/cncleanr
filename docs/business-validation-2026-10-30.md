# Real business workflow validation / 真实业务流程验收

Source checkpoint: c754d5d6b196804bdedfafc7a83fe05b2c7ef209.
Installed package tested: cncleanr 0.2.25, Windows R 4.6.1.

## Results / 结果

| Domain | Correct parse | Correct missing | Correct rejection | Business review, not parsed |
| --- | ---: | ---: | ---: | ---: |
| CFQA financial spans | 1412 | 0 | 6 | 0 |
| Salaries | 2307 | 385 | 79 | 308 |
| Employment statistics | 1050 | 0 | 0 | 0 |
| Monetary column header | 670 | 96 | 34 | 0 |
| Total | 5439 | 481 | 119 | 308 |

6347 labelled cases, 427 review records; zero wrong numerical results or wrong
acceptances in this bounded audit. Correct rejection does not resolve business
meaning. Counts are cases, not independent datasets or distinct defects.
No new production parser defect was reproduced; no R/src/DESCRIPTION/NAMESPACE
or package test changes compared with v0.2.25.

## Provenance and transformations / 来源及转换

Four retained snapshots are reused; no new snapshot was successfully downloaded.
New official budget, Taipei job and unemployment CSV resources were discovered
via their metadata, but direct requests timed out and proxy retries reset.
No response body was substituted into the old baseline. This is new end-to-end
workflow coverage on old real sources, not a new collection or current-market
survey. Reproduction/source/license links are in the bilingual tutorials.

* CFQA pinned test split: 2100 answers, 1418 extracted spans, including 39
  negative expectations. Reuses the existing Decimal builder; original record
  IDs are mapped back to original answer positions, not extracted-span numbers.
  This is lexical span validation, not NLP extraction accuracy or financial truth.
* Taiwanjobs: 1000 records; 1615 valid raw endpoint fields, 385 missing endpoint
  fields. The 692 eligible derived closed intervals are 556 monthly, 124 hourly,
  five piece-rate, five part-time monthly and two daily. No pay-period conversion.
  308 other intervals require business review before parsing. 77 full pay-rule
  descriptions and two manually reviewed complete job descriptions are rejected.
* Employment: 525 thousand-person fields retain source units; 525 percentage
  fields explicitly append `%` and use Decimal /100 expectations.
* Tourism: 800 monetary columns in ten-thousand TWD. These estimated benefits
  supplement header-unit coverage; they are not corporate accounts. 34 text or
  spreadsheet-error cells require review. Source data were not rewritten to
  simulate hundred/thousand-yuan monetary headers.

## Reproducibility / 复现

docs/business-validation.py verifies these raw SHA256 hashes before building:

| Input | SHA256 |
| --- | --- |
| cfqa.json | e4c08332a1f6aada430ac94fe62106fd557c3d80cd68c495118412bb7704bc7d |
| tw-jobs.json | 9c359ee13ce64bdf328eb7e9b135ea68af8f61ff15c02a07d4ec69eda394a937 |
| tw-education.xml | 28fdad833de16689d8dd123f80cc7bc2ab2572c1c148efc65325eb318e0d7960 |
| tw-tourism.csv | 08d298d4d54992b1a3169b1dd528af89b1119fa82a0454a7d4350ac2aff87e18 |

Local generated cases.csv SHA256:
0931349afa1978ee97b4e6471b9562a426edd0c06f5e6b7a7aac82116deedecc.
Raw files, full case tables, manifest, output tables and RDS stay under ignored
outputs/business-validation-2026-10-30. The repo includes only a small attributed
22-case factual sample and runnable scripts/tutorials, not the full snapshots.

docs/business-validation.R imports all columns as text; groups by parser/header;
maps each local problem back to case IDs/source rows; distinguishes missing,
rejection and pre-parse business review. Each domain exports annotated values
and a separate review table. CSV read-back checks all character fields, units,
pay modes, source positions, reasons, qualifiers and logical flags. Numeric
read-back uses per-row tolerance 1e-12. RDS grouped parser objects and diagnostics
read back identically. CSV is not claimed to preserve every binary64 bit.

## Checks / 检查

* Full local business workflow: all 6347 cases and output round-trips passed.
* Offline sample through the same script: all 22 cases passed, five review rows.
* Full installed package suite: 1832 assertions, no failures/warnings/skips.
* Both README editions: 14 runnable blocks each; one expected error and three
  intentionally unexecuted installation blocks, zero optional skips.
* Both business tutorials' two literal R blocks match and executed successfully.
* Python AST syntax check and git diff --check passed.

GitHub run 41074251822 on the source checkpoint succeeded on all five jobs:
Windows release 124126085882, macOS release 124126086197, Ubuntu release
124126086210, Ubuntu devel 124126086238, Ubuntu oldrel-1 124126086289.
Downloaded Ubuntu logs confirm Status OK, 1832 passing assertions and PDF manual
OK; the additional audit step passed 2454 consistency, 147 header/chunk, 28
bit64, 77 imported-type and 22 offline business cases. The 6347 full cases were
run locally, not in CI. The final evidence-only commit does not change audited
scripts, fixtures, tutorial examples or workflow.

No speed benchmark, new sanitizer result, new package release or CRAN submission
is claimed. The package stays at 0.2.25; existing public tag/archive are unchanged.
