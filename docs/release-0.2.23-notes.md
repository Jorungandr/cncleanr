# cncleanr 0.2.23

Range failure diagnostics now preserve specific scalar causes (unit conflicts,
overflow, underflow and conflicting qualifiers). Uniquely split failed ranges
identify left/right endpoint reasons using existing parser results.

Parsed values, accepted grammar, six exports, arguments and problem-table schema
are unchanged. Missing/ambiguous endpoints and grouping/structural errors retain
conservative priority. No extra row parsing, C changes or new dependencies.
Exact `reason` strings and `cn_summary()` groups may be more specific than before.

完善区间失败诊断，保留单位冲突、溢出等原因；拆分候选唯一时标注左右端点。
不改变可解析值或诊断表结构，但原因文本及原因汇总分组可能变化。不提交 CRAN。
