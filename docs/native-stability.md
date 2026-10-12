# Native stability audit / 原生稳定性验收

2026-10-12，cncleanr 0.2.9。本轮只做正确性和原生安全检查，不扩充语法，
不继续性能调优，不提交 CRAN。

## 发布完成 / Published

[GitHub v0.2.9](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.9)
已于 2026-10-12 正式发布，固定标签指向
`761dffa4cadb7748a8b0242d5bfac512142f08e2`，旧标签和附件未改动。
正式源码附件为 34,641 字节，GitHub digest 和正式发布后重新下载文件的
SHA-256 均与下文已检查文件一致。在独立库
`outputs/native-stability/public-library/` 安装后确认 0.2.9，三个公开解析函数、
科学记数区间及非法 UTF-8 回归均通过。双语 README 和 Release 说明已同步。
CRAN 未提交。

Published at the fixed commit above, without moving prior tags. The public
34,641-byte source attachment was downloaded again after publication; both
its checksum and GitHub digest match the checked archive below. Isolated
installation confirmed 0.2.9 and passed all three parser smoke checks plus
malformed UTF-8 rejection. Bilingual documentation is synchronized. No CRAN
submission was made.

## 实际修复 / Demonstrated fix

旧版共享 C 规范化允许被标为 UTF-8 的非法字节继续进入后续文本操作。
针对截断序列的回归先在已发布 0.2.8 上失败，再在修复后的 0.2.9 上通过。
修复在现有字符扫描中验证续字节和码点范围，拒绝截断、孤立续字节、
过长编码、代理码点和大于 U+10FFFF 的编码；读取下一字节前先检查终止符。
三个公开解析函数共用该入口，非法缺失标记也会报错。

Malformed UTF-8 previously passed through native normalization. The regression
failed against installed 0.2.8 and passed after validating sequences in the
existing native scan. All three parsers share this fix, including malformed
missing-value markers. No additional runtime dependency or second parser was added.

编码错误即使 `strict = FALSE` 也会中止，不转换成普通 `problems` 行，
不返回可用的部分结果。有效 UTF-8 和 Latin-1 转换保留原有行为。
对于非法编码，旧 R 的 `chartr()` 在不同平台可能拒绝或接受某些过长编码；
本轮有意统一为明确拒绝，而不是保证损坏文本与旧行为完全相同。
这不是对此前 Rterm 退出崩溃原因的重新诊断。

Encoding errors stop even in non-strict mode without partial results. Valid
UTF-8 and Latin-1 behavior is preserved. Rejection of malformed input is
intentional, not a claim of identical behavior for damaged text or a fix for
the earlier Rterm shutdown issue. See R's [encoding validation documentation](https://stat.ethz.ch/R-manual/R-devel/library/base/html/validUTF8.html).

## 可复现回归 / Reproducible regressions

`tests/testthat/test-native-stability.R`：固定种子 20261012，4,016 个混合输入，
包含随机格式组合、杂乱文本、区间和长文本；另有 factor、重复批次、空输入、
数值非有限值、自定义缺失标记和八种表头单位。测试参照环境同时关闭数值 C
路径并使用原来的 R 字符规范化；递归调用、数量和区间端点也通过参照环境。
比较完整结果、属性、名称、原文/行号/错误原因、警告和严格错误。
原生直接接受的结果另与 R 参照比较，包括负零倒数，防止回退隐藏错误接受。

The fixed-seed corpus compares complete outcomes against a test-only R
reference that also routes recursive calls and endpoint parsing through the
reference environment. Direct native acceptance is checked separately, including
negative zero. Twelve malformed byte sequences, short prefixes, long buffers,
Latin-1 and native argument validation are covered. The seed is restored after
generation; no test-only switch is exposed in the package API.

运行完整测试 / Run the full suite with an installed candidate:

```r
library(cncleanr, lib.loc = "outputs/native-stability/library")
testthat::test_dir("tests/testthat", reporter = "summary", stop_on_failure = TRUE)
```

Windows 本地使用 `docs/run-r.ps1`，清除子进程不适用的 `LANG/LC_ALL/LC_CTYPE`
后运行，避免继承 `C.UTF-8` 导致 Windows 启动区域设置警告。

## 已完成检查 / Completed validation

- 正式源码包 `outputs/native-stability/artifacts/cncleanr_0.2.9.tar.gz`：
  `R CMD check --as-cran --no-manual` 为 OK，退出码 0，
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 509`（原有 339 项，加本轮 170 项）。
- 本地没有检查 PDF 手册或远程 incoming；关闭远程 incoming，仅依赖索引
  下载失败的外部警告不改变最终 OK。日志在 `outputs/native-stability/check/cncleanr.Rcheck/`。
- 保留的公开多领域/多来源数据回归、100,000 混合单元格、20,000 不同数值、
  长非法文本、清洗示例及 CSV 往返全部通过，没有新增或声称新增数据来源。
- 三个解析函数在单独 R 进程中开启 `gctorture(TRUE)`，各重复三次的
  全角数值、近似数量和共享单位区间检查通过，结束时恢复垃圾回收设置。
- 解析源码提交 `d53ff0b2ef42dbc1c710a894f1df67be7685acfc` 的
  [五项平台 CI](https://github.com/Jorungandr/cncleanr/actions/runs/38254533930)
  均成功、每项 509 个断言通过。四项为 OK；Linux release 只有缺少 HTML Tidy
  的 NOTE，PDF 手册为 OK。
- 同一源码的 [R-hub 检查](https://github.com/Jorungandr/cncleanr/actions/runs/38254537724)：
  clang-ASAN、clang-UBSAN 和 Valgrind 均为 OK、509 项通过。Valgrind 首次在
  依赖下载阶段失败，尚未运行包检查；重试后完整检查通过。已检查真实日志，
  示例、基础回归和 testthat 的 Valgrind 摘要均为 `0 errors from 0 contexts`，
  definitely/indirectly/possibly lost 均为 0 字节。
- 最终标签提交 `761dffa4cadb7748a8b0242d5bfac512142f08e2` 的
  [CI run 38255408250](https://github.com/Jorungandr/cncleanr/actions/runs/38255408250)
  五项再次通过、每项 509 个断言，Linux release 的 PDF 手册为 OK，
  仍只有缺少 Tidy 的 NOTE。已核对其原生源码和测试与 R-hub 检查点完全一致，
  且最终源码包暂存文件与标签对应的包文件逐一校验一致。

The archive, full local tests and retained data audits passed. Five platform
jobs passed; Linux release had only the missing-Tidy NOTE and passed the PDF
manual check. Smoke checks for all three parsers also passed under forced
garbage collection in a separate R process. ASAN, UBSAN and Valgrind passed.
Valgrind's first attempt failed during dependency downloads; the retry completed
all checks with zero errors and zero definitely/indirectly/possibly lost bytes
in the inspected example/test summaries. Final-tag CI passed all five jobs again;
native sources/tests match the R-hub checkpoint and staged package files match
the checked final-tag payload.

SHA-256 of the exact checked archive:

```text
CACD16D3E7F2163DB56E4883BC7BF0BAC819CACDA7FF49F9BB0890BFCECA501B
```

## 原生检查入口与限制 / Native-check entry point and limitations

复用已有工作流，无需新建检查框架 / Reuse the existing workflow:

```sh
gh workflow run rhub.yaml --ref main -f config=clang-asan,clang-ubsan,valgrind
```

平台用途见 [R-hub 官方容器列表](https://r-hub.github.io/containers/)。原生源码或
边界逻辑更新后应重新运行，查看真实日志，不能只看绿色徽标。
这些检查只说明已执行输入未报告对应错误，不能证明不存在任何内存错误，
也不构成新的性能承诺。发布标签、最终提交 CI 和下载安装结果见上文。

Native checks cover executed cases only, not a proof that every possible input
is memory-safe. No performance guarantee is added. Publication and downloaded
asset verification are recorded above.
