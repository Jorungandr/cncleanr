# Hundred-yuan adaptation implementation plan

**Approved goal:** Add 百元 using the existing 千元 semantics: `3百元` and
`parse_cn_number('3', unit='百元')` both yield 300, without double scaling.
All six public underscore names remain unchanged. No bare 百, expanded compound
grammar, new parameter/dependency or CRAN submission.

**Design:** Extend the existing header/magnitude mapping with 100 and the
lookahead-only 百-before-元 token. Add the same fixed UTF-8 suffix branch to
`simple_number()` in C. Quantity infix-余 and range suffix/obvious-range regexes
use the existing 千元 path with `[百千]元`. Existing signed/currency/grouping/
missing and finite/underflow rules are reused, not reimplemented.

1. Add `tests/testthat/test-hundred-yuan.R`: literal all-parser/header values,
   qualifiers, shared/explicit range suffixes, conflicts, missing/names/factors,
   direct native/R-reference consistency, truncation and floating boundaries.
   Confirm failures against installed 0.2.20 before changing runtime code.
2. Patch R mapping/regexes and C suffix branch; extend existing native/random
   tests and all-header loops with 百元/100. Run focused and full suites.
3. Update version 0.2.21, NEWS, Rd, both READMEs, release notes and verifier.
   Commit clean source; build/check locally and all five regular CI platforms.
   Dispatch existing R-hub ASAN/UBSAN/Valgrind workflow for the same source.
4. Repeat real imported-type/system/data audits and ordinary/new-unit timing
   smoke checks without starting a new speed-optimization campaign.
5. Publish a fixed tag and the exact checked archive after validation; download
   public asset unauthenticated, hash, independently install and fully retest.
   Record fresh native-tool results honestly, including any environment limits.

Alternative: an R-only special-case replacement or requiring manual ×100.
Rejected: 百元 should be a first-class existing monetary suffix without losing
diagnostics or penalizing common hundred-yuan batches. The minimal existing
C branch extension avoids a second implementation or new abstraction.
Continue in the authorized checkout with no agents or extra sessions.
