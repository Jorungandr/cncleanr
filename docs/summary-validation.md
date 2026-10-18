# 诊断汇总验收 / Diagnostic summary validation

`cn_summary()` adds ordinary `counts` and `reasons` tables to the existing API.
It never reparses source values. The three parser implementations and C sources
are unchanged. Shared result-shape/problem-index validation was extracted from
`cn_subset()` rather than implemented twice; existing selection rules remain.
Summary scans happen only when requested, not during parsing. No new dependency,
result class, print method, automatic provenance tracking or CSV restoration API.

## Contract

`counts` has one row: `total`, `parsed`, `missing`, `failed`. NA/NaN without a
problem are missing; diagnosed absent values are failed. Numeric infinities and
valid textual open bounds count as parsed. `reasons` has `reason`/`count`, in
first-occurrence order; duplicate selections count repeatedly. Empty results
retain a zero-count row and typed empty reasons. Counts describe current rows,
not unique source records.

Summarize unmodified parser or `cn_subset()` results. Basic malformed columns,
out-of-range/duplicate indices and diagnostics pointing to nonmissing values
are rejected. No plain-R result can prove provenance: removed diagnostics and
arbitrary mutations may be undetectable. This is not a data-validity certificate.

## Local validation

Source checkpoint: `c88f8f99cf985a62cae7a5c37c6d26911716d783`.
Clean committed archive check: `Status: OK`, 1,388 assertions, zero failures,
warnings or skips. The new summary regressions contribute 87 assertions, covering
literal counts/reasons across all parsers, empty/all-missing/all-failed results,
nonfinite values, header failures, ranges/qualifiers, subsets/duplicates,
immutability, malformed diagnostics and a no-reparsing isolated-environment check.
They first failed because the old installation did not export `cn_summary()`.

Local R 4.6.1 / Windows 11 / UCRT GCC 15.2 check uses `--as-cran --no-manual`,
with incoming checks and remote dependency-cycle lookup disabled. No local PDF
or incoming certification is claimed. Installation and checkout/archive smoke
verification, including the new summary API, passed.

Actual haven 2.5.5 / units 1.0.1 / bit64 4.8.6 audit: 77 checks passed. System
audit: 2,454 generated consistency and 28 optional bit64 checks passed; generated
agreement is not independent semantic proof. Both literal READMEs ran 11 blocks
each with real units, including the expected strict error; three installation
blocks are intentionally not executed. Existing financial, research, penguin and
multi-domain audits passed, with all nine retained snapshot hashes verified.
No new source data or speed/sanitizer/Valgrind run is claimed.

The exact local archive SHA256 is
`1fbbaf87d83f9cd569c5ee6dd7d5f672ba4c9db12a0a7a9f4698f8fb4df5b8dc`.

## GitHub and public artifact

[CI run 39092001750](https://github.com/Jorungandr/cncleanr/actions/runs/39092001750)
passed Ubuntu devel/release/oldrel-1, Windows release and macOS release.
All five job logs show `Status: OK` and 1,388 passing assertions, with no failures,
warnings or skips. Ubuntu release additionally passed PDF and HTML manuals.
CI ran ten README blocks per language, excluded the three installation blocks
and explicitly reported the optional units block not executed. Real units was
verified locally, not certified on all five platforms.

Published [v0.2.19](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.19)
from the source checkpoint above; fixed annotated tag object
`17e86d9adac59100477deaeb6b1861d6eff9785a`. The 58,643-byte public asset was
downloaded without authentication and matched the archive SHA256 above.
Independent installation and source/archive/installed verification passed,
including the new summary API. Literal README execution, all 77 real imported-type,
2,454 generated consistency and 28 optional bit64 checks passed again against
the public installation. The full testthat suite and `tests/parser.R` also passed
again against that independent public installation. No CRAN submission.

## Incremental example on main (after v0.2.19)

The new checkout example accumulates only four double totals and a named numeric
reason-frequency vector between batches. Its local `summarize_batches()` is
example code, not another exported function. It preserves cross-batch
first-occurrence order and counts repeated source occurrences repeatedly.
The example still holds synthetic source text and its other workflow branches
retain tables: this is not a claim of constant-memory end-to-end file streaming.
State grows with distinct reasons and temporary parsing work with batch size.
Double integer counts are exact only through 2^53. Export individual problems
before releasing a batch if source-row review is required.

Source checkpoint: `b5bdfc88cb2743268defb4a5f43a612dfb899206`. New regressions
first failed against the earlier installed example, then passed after the update.
The same example validates all three parsers against whole-input summaries for
mixed, empty, missing-only, failed-only, reordered/repeated and numeric-nonfinite
cases, including a no-batch case. Whole-input passes are validation oracles, not
production accumulator work. Literal counts, stable empty schemas, reason totals
and first-occurrence order contribute 54 new testthat assertions.

Local clean committed archive check: `Status: OK`, 1,442 assertions, zero
failures/warnings/skips. The local check limitations above still apply. Checked
installation and checkout/archive verification passed. Real imported-type audit
(77), generated consistency (2,454), optional bit64 (28), and both README
editions with actual units (11 executed blocks each, three installation blocks
excluded) passed again. No parser, C, dependency, API or package-version changes.
No new benchmark, sanitizer run or collected real data is claimed.

The existing v0.2.19 tag and published asset retain their original contents and
1,388-assertion suite; the new accumulator is in main only until a future release.
No CRAN submission.

[CI run 39092573242](https://github.com/Jorungandr/cncleanr/actions/runs/39092573242)
passed all five platforms (Ubuntu devel/release/oldrel-1, Windows release,
macOS release). Each job log reports `Status: OK` and 1,442 passing assertions,
zero failed/warned/skipped tests. Ubuntu release passed PDF and HTML manuals.
CI executes the same updated example; its README audit excludes installation
commands and explicitly reports unavailable optional units examples, as above.
The fixed v0.2.19 tag SHA and asset size/digest were rechecked unchanged.
