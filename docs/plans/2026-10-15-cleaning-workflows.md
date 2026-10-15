# Cleaning Workflow Examples Implementation Plan

**Goal:** Document and test the four approved workflow risks without new APIs,
parser behavior changes, a version bump, a release or a CRAN submission.

**Architecture:** One standalone packaged example in
`inst/examples/chunked-cleaning.R` uses existing parsers and `cn_subset`, source
row vectors/IDs, explicit problem tables and base-R CSV. A small test sources the
same example; CI also runs it. No additional runtime dependencies or S3 classes.

## Approved design and tasks

1. Preserve source IDs and original text. Parse chunks, extract problems before
   binding, map batch-local indices through the batch's source-row vector.
   Include empty and problem-free batches. Compare with whole-input parsing.
2. Classify parsed/missing/review rows before filtering NAs, and preserve an
   independent review table. Carry a source-row vector through repeated/chained
   `cn_subset` operations and sorting; assert literal expected provenance.
3. Export values and problems separately in a unique temporary directory, read
   both back as text and verify IDs, quoted/multiline originals and source rows.
4. Add `tests/testthat/test-cleaning-workflows.R` that runs this exact script;
   integrate it into the existing executable-example CI step.
5. Add matching Chinese/English guides linked from the existing CSV docs and
   both READMEs; clearly distinguish example code from new parser behavior.
6. Install current main into an isolated library, run full tests and an exact
   source-archive check, review scoped diff, commit/push and inspect platform CI.
   Existing v0.2.13 tag/assets remain unchanged. Record main commit for examples.

User approved this documentation/regression scope on 2026-10-15. Run sequentially
in this chat, without subagents. Runtime R/C code and DESCRIPTION remain untouched.
