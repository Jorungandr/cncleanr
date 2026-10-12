# cncleanr 0.2.10

## 中文

- 修复合法三位空格分组的区间被误拒绝的问题：`1 234-2 345` 现在返回
  1234 到 2345；端点分别校验，支持原有共享单位、负号和科学计数法规则。
- `1 23-2 345` 等非法分组仍拒绝，不先删除空格拼接数字；
  `2 345-1 234` 明确报告上下界颠倒。原文、行号、缺失整单元格和严格错误保留。
- 增加已知正确答案回归，包括 42 种空格/分隔符组合、500 条不同金额区间、
  单位内部空格、重复输入和 factor。精确数值/数量接口与 C 源码不变。

本次不扩充新语法、不继续提速、不提交 CRAN。附件是源码包，仍需与 R
兼容的 C 编译工具；不是 Windows 二进制包。

最终源码包本地检查为 OK，五项平台 CI 均成功，每项 539 个断言通过。
Linux release 仅有缺少 HTML Tidy 的 NOTE，PDF 手册检查通过。

## English

- Fixes valid whitespace-grouped ranges being rejected as whole-string grouping
  failures. `1 234-2 345` now returns 1234 to 2345. Endpoints are validated
  independently with existing shared-unit, negative and scientific-sign rules.
- Malformed groups remain invalid rather than concatenated, and reversed grouped
  bounds report the existing reversed-range reason. Original diagnostics,
  whole-cell missing markers, duplicate rows and strict behavior are retained.
- Adds known-answer tests for 42 whitespace/separator combinations, 500 distinct
  monetary ranges, spaced units and factor inputs. Number/quantity APIs and C
  sources are unchanged.

No new syntax, speed-tuning round or CRAN submission. The attachment is a source
package, not a Windows binary; an R-compatible C toolchain is still required.

The exact source archive passed local checks. All five platform CI jobs passed
539 assertions each; Linux release had only the missing-HTML-Tidy NOTE and
passed PDF manual generation.

[Validation / 验收记录](https://github.com/Jorungandr/cncleanr/blob/main/docs/range-grouping.md)
