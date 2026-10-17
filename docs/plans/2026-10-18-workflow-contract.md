# Workflow/documentation consistency plan

Approved scope: verify documented three-parser behavior, chunk provenance,
CSV round-trips and bilingual executable examples. Reuse existing checks; do
not add parser features or perform another speed-optimization campaign.

Design: add focused regressions to the existing workflow tests for irregular,
reordered and repeated chunk indices plus shared exact-value gold cases. Audit
literal R code blocks extracted from both READMEs, skipping installation commands
and explicitly checking the intended strict error. Optional units examples run
only in the real dependency audit environment, with skips reported honestly.
Explain CSV's precision/NA/attribute limits and demonstrate RDS for lossless R
objects. No general CSV API or new dependencies.

Tasks:
1. Reproduce base CSV limitations using binary64 boundary values; inspect the
   existing docs/examples and check actual README blocks for errors.
2. Add tests to `tests/testthat/test-cleaning-workflows.R`, add a literal README
   audit under `docs/`, and run with installed 0.2.18. Fix confirmed defects only.
3. Update Chinese/English workflow/CSV guides and README together; add audit to
   existing five-platform CI without installing optional runtime dependencies.
4. Run full package check, real imported-type/system audits and snapshot checks.
   Commit/push, wait for all five CI jobs and record actual evidence.
5. If only docs/test coverage changes, keep version 0.2.18 and existing release
   assets unchanged. If parser fixes prove necessary, use a new fixed release and
   public download/install verification. No CRAN submission.

Alternative: introduce a batch/serialization API. Rejected: existing explicit
source mapping and base R serialization suffice; no measured need for a new API.
Execution stays in the authorized checkout, without delegated agents.
