# cncleanr 0.2.20

支持 `1亿2000万`、`约1亿2000万` 和 `1亿2000万-2亿` 等明确复合表达。
仅组合两项或三项完整的 `万亿／亿／万`，严格递减、不重复；允许小数、逗号分组
和整体正负号／货币标记／财务括号。拒绝隐含尾数、倒序、百分比及表头单位混用。
含复合端点的区间不再猜测另一端的单位。使用 double 运算，不是精确十进制金额。

Adds explicit descending compound magnitudes across all three parsers, reusing
single-term conversion. Ambiguous tails, reversed/repeated magnitudes, per-term
scientific notation/whitespace grouping, percentages and header-unit combinations
remain rejected. Ranges with compound endpoints require explicit opposite units.
C and runtime dependencies are unchanged; results use ordinary double arithmetic.

Includes incremental-summary workflow examples added after 0.2.19. Existing
tags/assets remain unchanged. No CRAN submission.
