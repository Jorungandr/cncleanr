# 0.2.8 发布包验收 / Release validation

## 发布完成 / Published

2026-10-12：[GitHub v0.2.8](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.8)
已正式发布，固定标签指向 `002fbbfa141edca7900d2645dac24feb72b6b7b7`。
最终提交的 [CI run 38250845508](https://github.com/Jorungandr/cncleanr/actions/runs/38250845508)
五项任务均成功，每项 339 个断言通过。Windows、macOS、Linux devel/oldrel-1
检查为 OK；Linux release 只有缺少 tidy 的 HTML 校验 NOTE，PDF 手册检查通过。
正式发布附件重新下载后的 SHA-256 与下文完全一致；在独立库安装后确认
版本 0.2.8，数值、数量、区间三个解析函数的安装后冒烟检查全部通过。
本次没有提交 CRAN。

Published on 2026-10-12 at the fixed commit above. All five final CI jobs
passed 339 assertions each; Linux release had only the missing-tidy NOTE and
passed the PDF manual check. The public source attachment was downloaded,
hash-verified and installed into an isolated library; version and smoke checks
for all three parsers passed. No CRAN submission was made.

## 最终发布文件 / Final release file

发布使用重新构建并检查的正式源码包：
`outputs/release-0.2.8/publish-artifacts/cncleanr_0.2.8.tar.gz`。
它包含正式版安装说明和 NEWS，不是下文保留的早期候选文件。

SHA-256:

```text
1AE8F2A98F2E0B4CA09E49199B22AE95399B9BDAA6A713130A78BF66213986CF
```

该文件的独立 `R CMD check --as-cran --no-manual` 为 `Status: OK`，
退出码 0，339 项断言通过。日志：
`outputs/release-0.2.8/publish-check/cncleanr.Rcheck/`。
本地未检查 PDF 手册和远程 incoming；最终提交的远程 CI 已核对，结果见上文。
The release archive above was rebuilt with final installation documentation and
NEWS, then checked independently: OK, exit 0, 339 assertions passed. It replaces
the earlier candidate as the release attachment. Candidate evidence below is
retained as history, not a claim that both archive hashes are identical.

## 候选阶段历史 / Candidate-stage history

2026-10-12。版本号和 NEWS 已更新为 0.2.8 发布候选；解析算法没有再次改动。
中英文 README 标明该候选尚未正式发布，v0.2.7 安装命令仍指向已有发布。
Version and NEWS now identify the 0.2.8 candidate. Parser algorithms are unchanged
from the performance closeout. Both READMEs distinguish it from released v0.2.7.

## 最终源码包 / Checked source archive

本地路径 / Local path:
`outputs/release-0.2.8/artifacts/cncleanr_0.2.8.tar.gz`

SHA-256:

```text
94D2455A406AD9BF63BC0E47BE212C6563F93BB86448DECFD2AB9382875402A7
```

该校验和对应本次构建、检查的具体文件，重新构建后不可假定校验和相同。
源码在干净的暂存目录构建，未包含编译对象或现有大型输出目录。
The checksum identifies the exact checked archive, not every future rebuild.
Build staging contains package sources only, excluding compiled objects and
the existing large output directories.

## 本地验收 / Local validation

Windows 11 x64，R 4.6.1，现有 GCC 15.2 UCRT，项目本地启动入口
`docs/run-r.ps1`。未安装编译器或修改系统配置。

- `R CMD build --no-manual` 成功。
- 对上述具体源码包执行 `R CMD check --as-cran --no-manual`，`Status: OK`，退出码 0。
- testthat：`FAIL 0 | WARN 0 | SKIP 0 | PASS 339`。
- 检查目录独立安装的包确认版本为 0.2.8，`NeedsCompilation: yes`。
- 三个公开解析函数的帮助页示例及基本安装后示例通过。
- 原有批量压力、公开多领域数据、多来源数据和 CSV 往返验证正常退出。

The exact archive built and checked successfully (`Status: OK`, exit 0), with
339 passing assertions. The check-installed package reports 0.2.8 and native
compilation metadata. Public help examples, smoke checks, retained open-data
audits, batch stress cases and CSV round trips passed. No new data sources or
runtime dependencies are claimed.

日志 / Logs: `outputs/release-0.2.8/check/cncleanr.Rcheck/`。
已安装候选库 / Installed candidate library:
`outputs/release-0.2.8/check/cncleanr.Rcheck/`。

本地跳过 PDF 手册和远程 incoming 检查。依赖发现期间 CRAN 索引下载失败，
随后使用已有依赖完成检查；该提示不是最终包检查的 ERROR/WARNING。
Local checks omitted the PDF manual and remote incoming checks. Repository-index
download failed during dependency discovery, but installed dependencies allowed
the completed check; this does not establish a new online CRAN pretest.

## 远程及发布状态 / Remote and publication status

解析源码验收点 `2d97758` 的五平台 CI 证据见
[发布准备记录](release-next.md)。它包含 Linux PDF 手册成功及缺少 `tidy` 的 HTML NOTE。
这是更改版本号之前的源码证据，不能冒充 0.2.8 的最终 CI 结果。
更新提交推送后仍需核对该提交的五平台 CI；正式发布前以最终提交结果为准。

0.2.8 候选提交 `a6f7ce6fdf002877ea456dd52d990779c469032e` 的
[CI run 38248983865](https://github.com/Jorungandr/cncleanr/actions/runs/38248983865)
已完成且整体成功。Windows、macOS、Linux R-devel、Linux R-oldrel-1
的包检查均为 `Status: OK`；Linux R-release 为 `Status: 1 NOTE`，
仅因缺少 `tidy` 跳过 HTML 验证。五项均为
`FAIL 0 | WARN 0 | SKIP 0 | PASS 339`，Linux R-release 的 PDF 手册检查通过。
逐项核对日志，而非只依赖总状态。上述源码包校验和仍保持不变。

Candidate commit `a6f7ce6fdf002877ea456dd52d990779c469032e` passed all five
jobs in run 38248983865. Four package checks reported OK; Linux R-release
reported one NOTE for unavailable HTML Tidy. All five reported 339 passing
assertions, and Linux R-release passed PDF manual generation. Individual logs
were verified. These results are candidate-commit evidence, not a CRAN pretest.

The five-platform result for parser checkpoint `2d97758` predates the version
bump; the separate run above verifies the actual candidate commit. No tag,
GitHub release or CRAN upload was created here.

保留已有标签和发布附件，不替换 v0.2.7。发布前记录最终提交 SHA，核对待上传
源码包与上述校验和一致；正式发布需维护者确认。
Keep existing release artifacts. Record the final commit and verify the archive
checksum before upload. Publication still requires maintainer confirmation.
