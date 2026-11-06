# Complete explicit currency marker checks in the salary example

The November 2 correction covered case-insensitive RMB but omitted CNY, another
marker accepted by the core parser. Reproduction: `月薪CNY3000` with
`currency = "USD"` returned parsed bounds of 3000 labelled USD.

The salary example now rejects 人民币 and every ASCII case variant of RMB/CNY
when the caller supplies a label other than CNY. The generic conflict reason
also correctly describes the ambiguous ¥/￥ symbols instead of calling them
explicit RMB. Caller-supplied CNY and JPY remain compatible with those symbols;
no currency inference or conversion is performed.

Regression coverage expands the existing marker matrix from eight to seventeen
markers across USD, JPY, EUR, CNY and absent labels. Three additional assertions
check compatible ambiguous symbols and the review reason. These synthetic checks
are distinct from the existing nineteen attributed source fragments.

Local results: 149 cumulative salary assertions, 288 generated wrapper cases,
19 source fragments, and 46 runnable bilingual documentation blocks passed.
Core package source, exports, dependencies and version 0.2.25 are unchanged.
No CRAN submission or replacement package archive is included.

## GitHub verification

Source commit: `ff8aae5b11f84ae6cfc3c3956666e9d3f491fea7`.
[Run 42237888849](https://github.com/Jorungandr/cncleanr/actions/runs/42237888849)
passed all five jobs: Ubuntu release/devel/oldrel-1, Windows release and macOS
release. Ubuntu release logs confirm 149 salary assertions, 1832 package
assertions, `Status: OK` and PDF manual OK. The ignored local log is
`outputs/salary-adapter/currency-completeness-ci.log`.
