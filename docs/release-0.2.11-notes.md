# cncleanr 0.2.11

## 中文

- 修复共享单位使缺失端点重新变成有效值的问题：设置 `na = "0"` 后，
  `0-5万` 现在报告缺失端点，不再接受为 0 到 50000。
- 缺失标记按规范化文本在补单位前后检查，覆盖普通、分组、负数和科学记数
  端点；保留整单元格缺失优先、原始行号、重复输入和严格错误。
- 新增 53 项回归断言；不改 API、数值直通规则、C 源码或运行时依赖。

这是文本标记匹配，不是数值等价判断：`na = "0"` 不自动匹配显式 `0万`。
本次不继续提速、不增加语法、不提交 CRAN。附件为源码包，仍需 R 兼容的 C 工具链。

本地正式源码包检查为 OK，五项平台 CI 均成功，每项 592 个断言通过。
Linux release 只有缺少 HTML Tidy 的 NOTE，PDF 手册检查通过。

## English

- Fixes shared suffixes resurrecting original missing endpoints: with `na = "0"`,
  `0-5万` now reports an invalid endpoint instead of becoming 0 to 50000.
- Checks normalized textual markers before and after suffix propagation for
  ordinary, grouped, signed and scientific endpoints, retaining whole-cell
  missing precedence, original diagnostics, repeated rows and strict errors.
- Adds 53 regression assertions. APIs, numeric pass-through, native C sources
  and runtime dependencies are unchanged.

Matching is textual, not numeric equivalence: `na = "0"` does not automatically
match explicit `0万`. No new syntax, speed tuning or CRAN submission. The source
attachment requires an R-compatible C toolchain.

The exact archive passed local checking. All five platform CI jobs passed
592 assertions each; Linux release had only the missing-HTML-Tidy NOTE and
passed PDF manual generation.

[Validation / 验收记录](https://github.com/Jorungandr/cncleanr/blob/main/docs/range-missing.md)
