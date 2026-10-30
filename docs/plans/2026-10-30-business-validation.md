# Real business workflow validation

**Goal:** Validate finance, recruitment and statistics workflows against public
source data, keeping raw/derived/review cases distinct.

**Architecture:** Retain downloaded raw snapshots in ignored outputs with source
metadata, retrieval date and SHA256. Build independent Decimal expectations in
Python; read all text/IDs without implicit conversion in R, parse explicitly by
field semantics, separate review records, export and read back. Finite lexical
validation does not certify financial or labour-market facts.

1. Verify official metadata/resources/licensing; acquire new snapshots separately
   from existing regression inputs. No third-party applicant/contact data is
   included in committed tutorial examples.
2. Add reproducible builders and R validation for supported scalar/quantity/range
   fields. Preserve source positions and periods. Distinguish original cells,
   derived intervals and manually reviewed unsupported salary text.
3. Report correct parses, expected rejections, ordinary missing values and wrong
   outcomes separately. Reproduce any parser defect before changing runtime code.
4. Provide Chinese/English end-to-end tutorials: import, parse, review, export;
   explicitly document header units, percentage points, pay periods and CSV limits.
5. Run local validation, existing package tests/README checks and final GitHub CI.
   Batch confirmed fixes if needed. No new interface or CRAN submission. Do not
   manufacture a package release when only external audit/docs changed.

User approved this scope. Existing snapshots remain regression baselines; new
downloads are not silently substituted for earlier hash-locked inputs.
