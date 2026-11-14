# Configurable CSV cleaning example implementation plan

**Goal:** Deliver the approved end-to-end CSV example with explicit column,
parser and monetary-unit configuration, review exports and quality summaries.

**Architecture:** A repository example defines clean_cn_csv(). Read UTF-8 CSV as
text, preserve source positions and duplicate identifiers, parse configured
columns in bounded batches using the public parsers, and aggregate cn_summary()
results. Publish cleaned/review/summary/reasons CSV and one RDS in a new output
directory after every file is written successfully in a sibling staging directory.
The full input and final result remain in memory.

**Tech stack:** base R and installed cncleanr 0.2.25.

1. Add docs/table-cleaning-audit.R with independent multi-column expectations,
   empty/success/missing/failure inputs, duplicate IDs, open bounds, chunk
   invariance, invalid configuration and output-failure checks.
2. Implement docs/table-cleaning.R. Validate configuration and generated-column
   collisions, retain original text, and use public problem and summary APIs.
3. Extend the audit with existing attributed offline business cases and the
   retained full business fixture. Record source transformations explicitly.
4. Add bilingual runnable guides and README links. Include audit and literal
   guide execution in the existing five-platform CI.
5. Measure 100000 rows across three configured columns, including elapsed
   export time, returned object size and R heap high-water statistics.
6. Complete local checks, GitHub synchronization and final CI verification.

The user approved this workflow on 2026-11-14. Parser exports and package
release artifacts belong to the existing package release workflow.
