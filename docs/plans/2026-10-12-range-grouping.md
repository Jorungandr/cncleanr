# Range Grouping Implementation Plan

**Goal:** Fix valid grouped range endpoints being rejected as whole-string
whitespace failures, without accepting malformed digit groups.

**Architecture:** Keep the ordinary normalized range path unchanged. For rows
rejected by whole-string grouping, reuse endpoint candidate parsing on retained
character-normalized text. Normalize only suffix lookup, not endpoint digits,
so each endpoint still receives the existing numeric grouping validation.

**Tech Stack:** Existing R parser/helpers, registered native normalization,
testthat, GitHub Actions; no new API or runtime dependency.

## Scope and alternatives

The user requested the next maintenance update with the whole GitHub workflow
in one pass. This implements the existing grouping contract, not new syntax.
Prefer the narrow recovery path over rewriting range parsing or removing
whitespace validation. Keep invalid grouping, reversed bounds, full original
text, problem indices, strict failures and missing markers conservative.
No speed tuning, C changes, or CRAN submission.

## Tasks

1. Add `tests/testthat/test-range-grouping.R`: known expected endpoints across
   whitespace/separator variants, suffix spacing, signs/scientific notation,
   malformed groups, duplicates/factors, whole-cell missing markers and strict
   diagnostics. Run against installed 0.2.9 and confirm failure.
2. In `R/parse-cn-range.R`, retry only rejected grouping rows with retained
   endpoint text after ordinary processing; add private suffix-lookup
   normalization flags to existing helpers. Accept only fully valid bounds;
   report reversed valid endpoints explicitly, preserve existing failure
   reasons for unrepaired rows. Run focused and complete tests.
3. Update range help and bilingual READMEs/NEWS for 0.2.10; rerun retained data
   and batch/CSV checks. Build the exact clean staged source archive and run an
   independent package check. Record assertions/hash and actual limitations.
4. Push the final commit and verify five CI jobs. Publish a fixed v0.2.10 tag
   and checked source asset with bilingual notes; download/hash-check/install
   the public attachment and test the fixed grouping and safe rejections.
5. Push excluded publication records without moving the tag. Preserve existing
   releases, unrelated user files and historical test artifacts.

Completed as GitHub v0.2.10. Local exact-archive checking and five platform CI
jobs passed 539 assertions; public asset download/install verification passed.
See `docs/range-grouping.md` for fixed commit, checksum and check limitations.
