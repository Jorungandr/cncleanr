# Salary currency conflict correction

The independent salary example accepted `月薪rmb3000` and `月薪Rmb3000`
with `currency = "USD"`, producing a parsed amount labelled USD. The core
parser accepts case-insensitive RMB markers, whereas the example's currency
conflict guard previously checked only uppercase RMB.

The guard now checks RMB case-insensitively, preserving the existing policy:
explicit RMB conflicts with any supplied label other than CNY. No conversion
or implicit currency inference is introduced. The single batched core parsing
call and the six package exports remain unchanged.

Regression coverage uses all eight ASCII case variants against USD, JPY and
EUR, and verifies CNY and absent-label acceptance, withheld conflicting values,
and original review indices/text. These are synthetic cases, not new datasets.

Local validation: 146 cumulative salary assertions, including 13 new assertions;
288 generated wrapper/unit/payment cases and 19 attributed source cases.
Bilingual executable guides and README blocks also pass (46 runnable blocks).
Package version remains 0.2.25; no CRAN submission or release archive change.
