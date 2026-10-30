# Header-unit and chunk workflow audit

**Goal:** Exercise existing header-unit semantics and diagnostic provenance
together with custom missing markers and deduplicated batches.

Extend docs/system-audit.R, already run automatically by Ubuntu release CI.
Use three parsers and 百元/千元/万元 headers, 4800 rows per combination with
independent expected values, failures and missing labels. Check strict mode,
negative zero, qualifiers, point ranges and summaries. Compare irregular/empty
and repeated/reordered chunk schedules with full results, mapping errors back
through source rows. Include conflicting units, overflow, underflow, malformed
grouping, normalized full-width missing markers and repeated fallback rows.

Run locally against installed v0.2.25, then inspect the final GitHub five-platform
run and the additional audit log. Update bilingual README coverage descriptions.
Do not change runtime code or public APIs unless a separate supported-behavior
defect is reproduced. No new package release, dependency, speed claim, CSV
serialization guarantee or CRAN submission is needed for an external audit update.
