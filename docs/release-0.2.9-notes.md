# cncleanr 0.2.9

## 中文

- 修复共享 C 字符规范化放行非法 UTF-8 的问题：截断、多余续字节、
  过长编码、代理码点和超出 Unicode 范围的序列会明确报错。
- 编码错误在非严格模式也会中止，不返回部分结果；有效 UTF-8 和
  Latin-1 转换、既有解析语法与结构化数值诊断保持不变。
- 新增固定随机种子的 C/R 对照回归，覆盖三个解析函数的结果、
  名称、完整诊断、警告和严格错误，以及长短字符串和原生参数边界。
- 不增加运行时 R 依赖或新语法，不继续性能调优；本次不提交 CRAN。

附件 `cncleanr_0.2.9.tar.gz` 是源码包，不是 Windows 二进制包；安装仍需
与 R 兼容的 C 编译工具。此前的 Rterm 退出异常与本次编码问题不是同一诊断。

本地源码包检查、五项平台 CI 均通过，每项 509 个断言；ASAN、UBSAN、
Valgrind 检查通过，Valgrind 已核对的示例/测试日志为 0 个错误。
Linux release 仅有缺少 HTML Tidy 的 NOTE，PDF 手册检查通过。

## English

- Fixes malformed UTF-8 passing through shared native normalization: truncated
  sequences, stray continuation bytes, overlong encodings, surrogates and
  out-of-range code points now raise an explicit error.
- Encoding errors stop even in non-strict mode without returning partial
  results. Valid UTF-8/Latin-1 handling, supported syntax and numeric diagnostics
  are unchanged.
- Adds fixed-seed C/R differential regression tests for all three parsers,
  complete results and diagnostics, warnings, strict errors and native boundaries.
- No new runtime R dependency or syntax, no further speed tuning and no CRAN
  submission. This encoding fix is not a claim to fix the earlier Rterm shutdown issue.

The attached archive is a source package, not a Windows binary. Source
installation still requires an R-compatible C toolchain.

The exact source archive passed local checks; all five platform CI jobs passed
509 assertions each. ASAN, UBSAN and Valgrind checks passed, with zero errors
in the inspected Valgrind example/test summaries. Linux release had only the
missing-HTML-Tidy NOTE and passed PDF manual generation.

[Validation / 验收记录](https://github.com/Jorungandr/cncleanr/blob/main/docs/native-stability.md)
