# 新用户上手检查 / New-user onboarding review

## 安装与帮助 / Installation and help

从 GitHub v0.2.25 发布页重新下载源码附件，校验 SHA256 后，在单独创建的空 R 库
中强制编译安装成功。测试环境为 Windows、R 4.6.1、GCC 15.2。六个公开函数的
帮助入口、用法和返回值段落均可读取，从已安装帮助中提取的示例全部运行通过。

The tagged GitHub v0.2.25 source asset was freshly downloaded, SHA256-checked,
compiled and installed into a separate empty R library. All six exported help
topics were accessible. Their usage and return-value sections were checked,
and examples extracted from the installed help ran successfully.

Archive SHA256 is
`5CAC55025B15CE3EE1AFCD0D86160247309CB1809600D05C1F4F7E092BEEDAE6`.
The installation trial used this source asset. README installer blocks retain
their existing exclusion from the automated literal-example runner.

## 首页修正 / README corrections

修正 `unit` 只供数值解析使用的过时说明，补齐 `cn_subset()` 和 `cn_summary()`
速查项，移除安装段落残留的 v0.2.8 优化说明。安装指引明确区分 CRAN 与 GitHub
功能版本，并说明下载完整仓库、在含 `DESCRIPTION` 的根目录运行 CSV 和薪资教程。
发布记录入口也补充了 v0.2.25 的验收链接。中英文版本同步修改。

Both READMEs now describe `unit` across all three parsers, list all six exports,
and provide early links to CSV and salary workflows. Installation instructions
identify the versions required for header units, diagnostic subsetting and
summaries. Repository-based tutorial instructions explain how to obtain the
checkout and locate its root. The release-record page links to v0.2.25 evidence.

CRAN was checked as version 0.2.5 on 2026-11-13.
[CRAN package page](https://cran.r-project.org/web/packages/cncleanr/index.html).

## 示例与链接 / Examples and links

隔离依赖环境通过 44 个 README／教程代码块，可选 units 示例在两种语言中各跳过
一次并明确报告。补齐已有可选依赖后，46 个代码块全部通过。新增自动检查核对
两个 README 的六函数速查项和本地文件链接。帮助检查同时发现测试脚本最初依赖
终端标题的显示格式，随后改为检查 Rd 的用法和返回值结构，重新运行通过。

The isolated dependency environment passed 44 runnable blocks and reported one
optional units skip per language. With the existing optional dependencies
available, all 46 blocks passed. README checks now verify each export's reference
row and every local file link. The help audit initially assumed plain terminal
headings, then was corrected to inspect Rd section tags and rerun successfully.

Local downloads, installation libraries and the help-audit script are retained
under ignored `outputs/onboarding-2026-11-13/`.
