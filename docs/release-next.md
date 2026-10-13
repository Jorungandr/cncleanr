# 下一版发布准备 / Next-release preparation

0.2.12 已完成 GitHub 发布，系统整改与最新验收见[系统整改记录](systematic-hardening.md)。
GitHub 0.2.12 is published; its hardening/check evidence is recorded there.
The 0.2.11 and older publication sections below are historical.

## 当前发布状态 / Current publication status

2026-10-13：[GitHub v0.2.11](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.11)
已发布，固定标签为 `c27d054238cc6f13e96c308826e8cd22ea2830d7`。
最终源码附件、五项 CI、下载校验和独立安装已验收，详见
[区间缺失标记与发布验收 / range missing markers and release validation](range-missing.md)。
本轮 592 项断言通过，C 源码不变；历史原生工具结果保留在
[原生稳定性记录](native-stability.md)，不是本轮重新检查。本次未提交 CRAN。
GitHub v0.2.11 is published at the fixed commit above; the checked source asset,
five CI jobs, downloaded checksum and isolated installation were verified.
592 assertions passed. C sources are unchanged; previous native-tool results
are retained as historical evidence, not a rerun. No CRAN submission was made.

## 准备阶段历史 / Preparation-stage history

以下保留 0.2.8 发布前的准备记录；其中候选状态和 v0.2.7 指历史时点，不是当前状态。
The 0.2.8 preparation notes below are historical: candidate status and v0.2.7 refer
to the pre-publication snapshot, not the current release.

## 用户可见变化 / User-facing changes

- 仍维护一个 R 包和原有公开函数；数值解析与字符规范化使用注册的 C 函数。
- 常见数值保留原生结果，仅未处理行进入完整 R 解析；重复复杂文本按条件去重。
- 闭区间批量切分、共享单位传播和候选统计，明显区间跳过无效的数量解析尝试。
- 完整保留原文、行号、名称、缺失标记、表头单位及严格错误顺序。
- 源码安装新增 C 编译工具要求，没有新增运行时 R 依赖。

- One R package and the existing public functions remain; registered C routines
  handle numeric parsing and character normalization.
- Mixed numeric batches reuse accepted results; repeated fallback text can be
  deduplicated without losing original rows.
- Closed-range processing batches splitting, shared-unit propagation and
  candidate counting, avoiding redundant quantity parsing for obvious ranges.
- Original text, indices, names, missing markers, header units and strict error
  order are retained. Source installation needs C build tools; runtime R
  dependencies are unchanged.

安装渠道及编译要求见 [中文 README](../README.md#安装) 和
[English README](../README_EN.md#installation)。性能计时、适用范围及限制见
[性能收尾报告 / performance closeout](performance-final.md)。

## 已核对的状态 / Verified state

截至上述日期，CRAN 的 [DESCRIPTION](https://cran.r-project.org/web/packages/cncleanr/DESCRIPTION)
为 0.2.5，GitHub 正式版为 [v0.2.7](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.7)。
两者均不包含本轮 C 加速。`main` 现为 0.2.8 发布候选版，尚未创建 v0.2.8 发布；
复现开发代码仍应记录提交 SHA，不能只看 `packageVersion()`。
CRAN was verified at 0.2.5 and GitHub at v0.2.7; neither includes this native
optimization round. Development code is now a 0.2.8 release candidate, not a
published v0.2.8 release; record its commit SHA as well as its version.

解析源码验收点：`2d977584b539427ad6b47800763d3e24af184bc7`。
[CI run 38244901525](https://github.com/Jorungandr/cncleanr/actions/runs/38244901525)
的五项任务均成功：

| 环境 / Environment | 包检查 / Package check | 断言 / Assertions |
| --- | --- | ---: |
| Windows, R-release | OK | 339 |
| macOS, R-release | OK | 339 |
| Linux, R-devel | OK | 339 |
| Linux, R-oldrel-1 | OK | 339 |
| Linux, R-release | 1 NOTE | 339 |

五项均确认编译、安装、加载、示例和测试成功。Linux R-release 的 PDF 手册检查通过；
唯一 NOTE 是缺少 `tidy` 而跳过 HTML 校验。它不是解析或编译错误，但不能写成“五项均零 NOTE”。
All five jobs passed compilation, installation, loading, examples and tests.
Linux R-release passed the PDF manual check. Its only NOTE was skipped HTML
validation due to unavailable `tidy`; do not describe all jobs as NOTE-free.

## 正式发布前 / Before release

1. 已将版本号和 NEWS 更新为 0.2.8 发布候选；按该版本构建、独立安装和检查，证据见 [0.2.8 候选验收](release-0.2.8-report.md)。
   候选提交 `a6f7ce6` 的五项 CI 已通过，包括 Linux PDF 手册；唯一 NOTE 为缺少 HTML Tidy。
2. 从最终源码包记录校验和，确认与 GitHub 标签和附件一致；保留旧标签与发布附件作为回退依据。
3. 创建 GitHub 正式发布需维护者明确确认；若计划更新 CRAN，需重新获取最终包的预检查结果，
   不能复用旧版邮件，并在提交前核对 CRAN 状态及政策。

Choose the next version, rebuild and check that exact archive, record its
checksum, and keep prior release artifacts. GitHub release publication requires
maintainer confirmation. A CRAN update additionally needs fresh pretests and
submission-time checks; historical emails are not final-package evidence.

本次仅准备 0.2.8 候选包，未创建标签或正式发布、未上传 CRAN。性能迭代已经结束；
这些待办属于发布验证和文档维护，不是继续调优。
This preparation sets the candidate version to 0.2.8 but does not publish a
tag/release or submit to CRAN. Remaining work is release verification and
maintenance, not speed tuning.
