# 系统检查与数值下标修复 / System audit and numeric selectors

## 范围与结果 / Scope and findings

Audit baseline: installed 0.2.15. Reviewed parser input validation, native entry
points, numeric boundaries, encoding diagnostics, selection/remapping, example
workflows, package metadata and release reproducibility. Existing tests and
retained public data supplement, not replace, independent known-answer tests.

Confirmed defect: actual bit64 4.8.6 numeric selectors `c(2,1)` produced an empty
selection; `-1` could manufacture a missing row. A synthetic numeric S3 selector
also demonstrated that its conversion method was ignored. All three parser
result forms were affected through the single `cn_subset()` entry point.

Repair: call `as.double()` once only for classed numeric selectors, then validate
the converted plain double vector and reuse existing base selection/remapping.
Malformed result type/class/dimensions/length is rejected. Ordinary integer,
double and logical indices avoid this conversion; parser algorithms and C are
unchanged. No extra runtime/test dependencies or general class-adapter layer.

本轮已确认的问题集中在数值下标入口，而非三个解析算法。修复后再跑原有测试、
生成语料一致性、真实 bit64 及公开数据审计；不把测试通过表述为永远不会有缺陷。

## 可复现检查 / Reproduce

```text
Rscript docs/system-audit.R <installed-library> [optional-bit64-library]
```

The generated audit uses a fixed seed and covers 2,454 comparisons: scalar/batch,
factor, duplicates, missing markers, diagnostic remapping, and rejection of dates,
date-times, durations, logical/complex/raw/list/NULL inputs. These comparisons
detect inconsistent paths, not a shared wrong semantic interpretation. The
optional bit64 section adds 28 checks; unavailable optional checks are printed as
not tested. The package's permanent regressions instead use a dependency-free
S3 fixture, including invalid conversion results and one-conversion assertions.

日期、时间和时长当前明确拒绝，不自动把它们解释为天数或秒数。integer64 经数值
转换后仍受 double 精度限制；超过精确范围的整数可能由 bit64 发出精度警告。
自定义类别的单位含义不能由通用解析器推断。haven 和 units 在本机安装尝试失败，
不列为已验证；未为此新增依赖或改变第三方对象的含义。

Retained financial/multi-source/broad-data audits and nine snapshot hashes are
rechecked; no new sources or data coverage are claimed. Ordinary `[]`/binding/CSV
still do not automatically maintain diagnostics. An accounting-unit range such
as `(3万)-5` retains existing behavior; changing unit inheritance here requires a
separate semantic decision and is not silently included in this bug fix.

Publication and final validation evidence follows after completion. No CRAN upload.
