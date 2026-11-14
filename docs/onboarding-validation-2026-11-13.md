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

## GitHub verification

Source `e9fa0a2d8bf221401ee956affea593d49423e944` passed all five jobs on Ubuntu
release/devel/oldrel-1, Windows release and macOS release. Ubuntu release logs
confirm the six-export/local-link checks, fourteen runnable blocks per README,
1832 package assertions, `Status: OK` and PDF manual OK.
[View run 43393148151](https://github.com/Jorungandr/cncleanr/actions/runs/43393148151).
The downloaded log is retained in `outputs/onboarding-2026-11-13/ci-ubuntu.log`.

## 2026-11-14 pak 在线安装 / Online pak installation

两个 README 中的 GitHub 安装目标均已通过实际在线验证，在两个独立新建的 R 库中
完成下载、构建、安装和加载。目标提交由安装后的 DESCRIPTION 核对。

| Target | Installed commit |
| --- | --- |
| `Jorungandr/cncleanr@v0.2.25` | `821d560eff049dd953ba393dac2bb76d7a63541f` |
| `Jorungandr/cncleanr@main` | `549d973ae0152c54bbc9ab941d415428d025cc4f` |

Each target was downloaded, built and installed with `pak::pak()` into a
separate new library. The loaded package path and version were verified, along
with six exported functions, hundred-yuan parsing, quantity header conversion
and range header conversion. Both installations passed their six extracted help
examples and all 46 current README/tutorial blocks with optional dependencies.

另外从 CRAN 在线下载并向独立库安装了 pak 0.11.2，再用这份 pak 向第三个新建库
安装 main 成功。这个额外安装复用了前面已构建的 pak 缓存。pak 的 Windows 二进制
包在加载时提示由 R 4.6.2 构建，本机 R 4.6.1 上加载与安装实测通过。

A separate CRAN binary installation of pak 0.11.2 also succeeded. That fresh pak
installation installed main into a third new library using its existing build
cache. Loading pak reported that its binary was built under R 4.6.2. The local
R 4.6.1 installation and package smoke checks succeeded.

The Windows environment used the existing GCC 15.2 compiler configuration.
Repository main resolves to a moving commit, so the exact tested SHA is recorded
above. Installation scripts and full logs are retained under ignored
`outputs/pak-install-2026-11-14/`.
