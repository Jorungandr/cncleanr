# Salary example validation / 薪资示例验收

Source checkpoint: 8541cf48dcc5edd7d41ef8116d04594ce526b3ef.

## Implementation / 实现

docs/salary-adapter.R defines the independently sourced salary_example(), not a
package export. It performs vectorized wrapper checks and a single batched
parse_cn_range() call for candidates. No private symbols, new runtime package
dependencies, scanning of recruitment articles or automatic income conversion.
The unchanged package stays at 0.2.25; R/, src/, NAMESPACE, DESCRIPTION and package
tests match public v0.2.25.

Data and review tables preserve original indices/raw text and duplicate rows.
Periods are explicit or supplied as scalar documented field context. K/k is
mapped only here; advertised N-pay counts remain separate metadata. Unknown
periods, commissions, conditional/probation pay, negotiations, nonpositive salary
boundaries, unsupported tails and conflicting metadata do not expose salary
amounts. Open inequalities retain the core inclusivity flags; no zero lower
bound, currency conversion or guaranteed annual income is invented.

The example is in the GitHub repository, excluded from the installed R package.
The existing six functions do not acquire these domain rules or extra work.
Sourcing the example only defines its function and writes no output files.

## Local checks / 本地检查

* 128 audit assertions passed: 52 generated/boundary/workflow assertions and
  76 assertions across the 19 attributed source-expression cases.
* 288 independent generated combinations cover three coefficients, four money
  suffixes, four pay periods, three wrapper placements and with/without 13-pay
  declarations. These cases are not 288 assertions or independent real samples.
* The 19 source cases retain their assessment expectations: nine parsed, five
  needs_context, four conditional and one negotiated. Annual amount fragments
  receive only their documented source context. No new collection or random
  market accuracy claim; attribution links accompany the small factual fixture.
* Boundaries include full-width characters, valid/invalid whitespace grouping,
  multiline grouping, currency/period conflicts, zero/negative amounts,
  overflow/underflow, malformed/duplicate payment declarations, explicit missing
  policy, invalid arguments, factors, empty inputs, repeated and chunked results.
* Full installed package suite: 1832 passing assertions, no failures/warnings/skips.
* Both salary guides' four literal R blocks passed, including review indices
  and exact RDS round-trip. Existing README (14 per edition), financial (3 per
  edition) and business (2 per edition) tutorial checks also passed. Installation
  blocks deliberately not executed; no local optional units skips.

The first implementation draft's chartr destination treated an interior ASCII
hyphen as a range; moving the hyphen first fixed it. Review also repaired
wrapper extraction across newline-grouped amounts. These were pre-publication
example implementation issues, not pre-existing core parser defects.

## Cost smoke check / 成本检查

Same local Windows R 4.6.1 session, warmed adapter, three runs per 100000-row
synthetic workload, with GC before each measurement:

| Workload | Elapsed seconds | Median |
| --- | --- | ---: |
| Distinct monthly single amounts | 0.50 / 0.50 / 0.52 | 0.50 |
| Repeated mixed salary/review/missing fields | 0.20 / 0.19 / 0.19 | 0.19 |

These are additional example-adapter costs, not a speedup claim or universal
timing promise. Core code/call paths are unchanged. General performance tuning
was not reopened. The benchmark script/log stay under ignored outputs/salary-adapter.

## Publication boundaries / 发布边界

GitHub run 41081708931 completed all five jobs successfully: Ubuntu devel
124152252292, Ubuntu oldrel-1 124152252722, Windows release 124152252923,
Ubuntu release 124152253222 and macOS release 124152253361. The final macOS
conclusion was also confirmed directly via the job API.

Downloaded Ubuntu logs explicitly confirm 288 independent generated cases,
52 boundary/workflow assertions and 19 attributed source cases (128 cumulative
audit assertions), both salary tutorial editions' four literal blocks, Status OK,
1832 passing package assertions and PDF manual OK. The salary audit is an
unconditional step in every matrix job, not an optional local-only check.
Final evidence/historical-assessment wording updates do not change the tested
adapter, fixtures, runnable guide blocks or workflow.

This adds repository example code, source-fragment tests and bilingual guides.
No new package version, tag, replacement archive, CRAN submission or native
sanitizer result. Existing released artifacts remain unchanged.
