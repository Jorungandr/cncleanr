# Diagnostic Workflow Implementation Plan

**Goal:** Implement the approved compatible diagnostic subset and encoding-location design.

**Architecture:** Keep plain numeric/data-frame return types. Add explicit
`cn_subset(x, rows)` using base row selection and remap `problems` to selected
positions, including repeated rows. Numeric (integer-valued) and logical indices
only; reject missing/out-of-range selections instead of manufacturing records.
Ordinary `[]`, mutation and binding remain outside the tracking contract.
Wrap encoding failures with their argument (`x` or `na`) and first original
position. Locate failures only after an encoding error, before returning no
partial result. Do not change C validation or reinterpret malformed bytes.

**Tech Stack:** base R, existing registered C routines, testthat, PowerShell.

## Sequential tasks

1. Add independent regressions in `tests/testthat/test-diagnostic-workflow.R`;
   run against installed 0.2.12 to demonstrate missing helper/location behavior.
2. Add the subset helper to `R/problems.R`, using integer/logical selection,
   resetting stale inherited attributes and remapping retained problem rows.
3. Add private encoding wrappers in `R/problems.R`; route native normalization
   and numeric entry points through them and annotate at each public parser
   boundary using its original arguments. Test deduplication, pending subsets,
   factors, damaged missing markers, bytes/noncharacters and normal errors.
4. Regenerate Rd/NAMESPACE, update DESCRIPTION/NEWS and both READMEs, add a
   runnable workflow example and extend dependency-free/release smoke checks.
5. Isolated installation, full suite, existing data/batch/CSV checks, exact
   source archive check, platform CI and native-tool verification where applicable.
6. Review scoped diff, commit/push, fixed v0.2.13 tag, source release, downloaded
   checksum and isolated installation. Record evidence; no CRAN upload.

Design approved by the user on 2026-10-13. Execute in this chat without subagents.

## Completion

All six tasks completed. GitHub v0.2.13, checked/downloaded archive hash,
784-assertion local/platform/native checks, data regressions and isolated public
installation are recorded in `docs/diagnostic-workflow.md`. No CRAN upload.
