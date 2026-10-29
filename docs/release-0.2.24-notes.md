# cncleanr 0.2.24

Combined repair for three confirmed root-cause families:

1. Accounting range units are recognized/inserted inside parentheses, without
   duplicating explicit suffixes. Shared units now propagate both ways.
2. Parser input and missing markers reject matrices/arrays rather than flatten.
3. Explicit summaries reject malformed qualifiers, bounds and inclusivity.

Compatibility: `(3万)-5` now means -30000 to 50000, not an upper bound of 5.
Select matrix/array columns explicitly. Compound-unit ambiguity, missing-marker
rules and ordinary diagnostic schema remain conservative. No new exports,
parameters, dependencies or native code. No CRAN submission.

本次集中修复 3 类根因，包含此前已发现的括号单位问题和新增的输入/汇总校验缺口。
括号单位共享规则已明确统一，兼容性变化见上；有限测试不证明永远没有缺陷。
