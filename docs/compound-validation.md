# 复合数量验收 / Explicit compound magnitudes

## Scope and implementation

0.2.20 accepts two or three explicitly suffixed `万亿`/`亿`/`万` terms in
strictly descending distinct order, with unsigned decimal or comma-grouped
coefficients. Currency markers, a sign or accounting parentheses apply to the
whole expression. Components reuse `parse_cn_number(..., na=character())` in
one batch; they are single terms, so recursion is bounded. At most three finite
component values are summed and the whole sign is applied once. This remains
ordinary double arithmetic, not exact decimal money arithmetic.

The private fallback runs only for existing single-number syntax failures.
Ordinary native success returns are unchanged. Quantity qualifiers already use
that shared number parser. Range endpoint parsing also reuses it, with a guard
against inferring a bare endpoint's scale from a compound's final small unit.
Existing single-term behavior is retained, including original missing markers,
diagnostic row mapping and finite/underflow checks.

This first compound grammar rejects implicit tails (`3万5`, `3万5000元`), repeated
or reversed magnitudes, internal currency markers, per-term scientific notation,
interdigit whitespace grouping, percentages and all `unit=` headers. Existing
single-term scientific/grouped values remain supported. Compound ranges require
explicit trailing units at both ends; incompatible percentage ranges still fail.
No arbitrary Chinese numerals, addition/subtraction syntax, unit inference or new
public function/dependency/C routine is introduced.

## Validation

Source checkpoint: `c7af18f08d3a9af54d3ef5635c143c6d9794123f`.
New compound tests first failed against installed 0.2.19, then passed. They add
46 assertions with literal expected values/qualifiers/bounds, currencies, signs,
fullwidth text, invalid grammar, strict diagnostics, names, custom NA, factors,
deduplication, header conflicts and component/sum overflow. Sixty generated
integer compounds are compared with direct integer-scale arithmetic across all
three parsers, not with another parsing implementation. Native/reference corpus
comparisons also now include compound successes, qualifiers, ranges and rejection.

Local exact clean-source R CMD check: `Status: OK`, 1,488 assertions, zero
failures/warnings/skips. Windows 11, R 4.6.1, UCRT GCC 15.2. Local flags were
`--as-cran --no-manual`, with incoming checks and remote dependency-cycle lookup
disabled; no local PDF or incoming certification is claimed. Independent source
installation and checkout/archive/installed verification passed.

Actual haven 2.5.5 / units 1.0.1 / bit64 4.8.6 audit: 77 checks passed; generated
consistency audit: 2,454 passed, plus 28 optional bit64 checks. Generated agreement
is not independent semantic proof. Both READMEs ran 12 literal blocks each with
actual units, including one expected strict error; installation blocks are not
executed. Existing financial/research/penguin/multi-domain audits passed with all
nine retained snapshot hashes verified. Those are regression snapshots, not
newly collected real compound-language coverage. C is unchanged; no new
sanitizer/Valgrind results are claimed.

## Ordinary-input timing regression

Five alternating paired medians, with identical complete outcomes checked
against installed 0.2.19 R code and the same unchanged C routines:

| Input | Rows | 0.2.19 seconds | 0.2.20 seconds |
| --- | ---: | ---: | ---: |
| number text | 100,000 | 0.010 | 0.010 |
| number numeric | 100,000 | 0.0002 | 0.0002 |
| qualified text | 100,000 | 0.16 | 0.13 |
| range text | 20,000 | 0.75 | 0.72 |
| invalid text | 10,000 | 0.02 | 0.02 |

These are short samples on a shared Windows machine, not an isolated benchmark,
a stable speedup claim or proof of zero overhead. Task-local reproduction:
`outputs/compound/performance.R`. No new optimization campaign is implied.

Candidate archive SHA256:
`f26d6cb51cb6f28b13a0ca00c19ae793fef35cc03da6c16f8dd58dc01b327d4e`.

## GitHub publication

[CI run 39275995195](https://github.com/Jorungandr/cncleanr/actions/runs/39275995195)
passed Ubuntu devel/release/oldrel-1, Windows release and macOS release. All five
job logs report `Status: OK` and 1,488 passing assertions, zero failures/warnings/
skips. Ubuntu release passed PDF and HTML manual checks. The optional units
example was separately tested locally; missing optional blocks are explicitly
reported by the CI README audit, not claimed as executed there.

Published [v0.2.20](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.20)
from the source checkpoint above, fixed annotated tag object
`d693ad1a721e4b557580c203ff063a7a1508e334`. The 63,153-byte public asset was
downloaded without authentication and matched the exact SHA256 above.
Independent installation, checkout/archive/installed verification, full testthat
suite and `tests/parser.R` passed again. The public installation also passed
both literal README editions with real units, all 77 imported-type checks,
2,454 generated consistency checks and 28 optional bit64 checks.
No CRAN submission.
