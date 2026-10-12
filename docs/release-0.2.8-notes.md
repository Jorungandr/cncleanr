# 中文

- 加入注册的 C 数值解析和字符规范化，仍维护一个 R 包、一套公开 R 接口。
- 改善混合批次、重复复杂文本和闭区间处理，保留完整原文、错误行号、名称、缺失值规则和严格错误顺序。
- 单位、限定词及区间语义不变，不把 `1 2` 静默拼接成 `12`。
- 源码安装需要 C 编译工具：Windows 使用匹配的 Rtools；macOS/Linux 使用与 R 兼容的工具链。没有新增运行时 R 依赖。
- 本地整包检查和 339 项断言通过，公开数据、批量及 CSV 验证通过；跨平台验收链接见发布报告。
- 性能随格式、行数、重复率和硬件变化，不保证统一低于 0.1 秒。性能迭代已收尾，后续以正确性和兼容性维护为主。

```r
install.packages("pak")
pak::pak("Jorungandr/cncleanr@v0.2.8")
```

附件 `.tar.gz` 为源码包，不是 Windows/macOS 预编译二进制包。
CRAN 此次未更新，`install.packages("cncleanr")` 不会因此自动安装 GitHub 0.2.8。

# English

- Adds registered C numeric parsing and character normalization while retaining one R package and the existing public API.
- Improves mixed batches, repeated fallback text and closed ranges, preserving complete source text, error indices, names, missing-value rules and strict error precedence.
- Unit, qualifier and range semantics remain unchanged; invalid grouping such as `1 2` is not silently concatenated.
- Source installation needs a compatible C toolchain (matching Rtools on Windows). No additional runtime R dependency is introduced.
- Local package checks and 339 assertions passed, along with retained open-data, batch and CSV validation. Cross-platform evidence is linked in the release report.
- Performance depends on format, size, repetition and hardware; no universal 0.1-second guarantee is made. Routine speed tuning is closed out.

The attached `.tar.gz` is a source package, not a Windows/macOS binary. This GitHub release does not update CRAN.

[Validation / 验收记录](https://github.com/Jorungandr/cncleanr/blob/v0.2.8/docs/release-0.2.8-report.md)
| [Benchmarks / 性能总结](https://github.com/Jorungandr/cncleanr/blob/v0.2.8/docs/performance-final.md)
