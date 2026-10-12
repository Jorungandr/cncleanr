# Range endpoint grouping / 区间端点分组验收

2026-10-12，cncleanr 0.2.10。本轮修复已有区间/三位空格分组规则的漏判，
不改数值、数量接口，不增加新语法、依赖或性能承诺，不提交 CRAN。

## 发布完成 / Published

[GitHub v0.2.10](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.10)
已正式发布，固定标签指向 `c46519ccb9ba8163dae0452b994d230afa194c2b`。
正式附件为 36,146 字节，其 GitHub digest 与发布后重新下载文件的 SHA-256
均与下文检查文件一致。在独立库 `outputs/range-grouping/public-library/`
安装后确认版本 0.2.10，30 项分组区间断言和精确数值/近似数量冒烟检查通过。
中英文 README、帮助页和 Release 说明已同步；旧标签和附件未改动，未提交 CRAN。

Published at the fixed commit above. The 36,146-byte public source asset was
downloaded again after publication; its checksum and GitHub digest match the
exact checked archive below. Isolated installation confirmed 0.2.10 and passed
all 30 grouped-range assertions plus number/quantity smoke checks. Bilingual
documentation and help are synchronized; prior releases were preserved.
No CRAN submission was made.

## 原因与修复 / Root cause and fix

0.2.9 将单个数值的空格分组校验直接用于整个区间：
`1 234-2 345`、`1 234元-2 345元` 被误判为非法分组。
已在正式安装的 0.2.9 上复现，并确认新增已知答案回归在修复前失败。

保留普通规范化区间路径；仅对原先因整体分组失败的行，使用保留空格的
端点原文重试既有候选解析。只在共享单位查找时规范化，不先拼接端点数字。
两个端点必须各自通过原有数值校验；合法但颠倒的端点报告既有颠倒原因，
无法修复的行保留原有问题。结果回填后统一生成原始顺序的诊断。

Whole-string grouping validation incorrectly treated two valid endpoints as
one number. The narrow recovery path now checks retained endpoint text with
the existing parser; only suffix lookup is normalized. Invalid groups remain
invalid, reversed bounds are diagnosed explicitly, and original row diagnostics
are preserved. Ordinary ungrouped parsing and native C sources are unchanged.

Examples:

```r
parse_cn_range("1 234-2 345", strict = TRUE) # 1234 .. 2345
parse_cn_range("1 234-2 345万元", strict = TRUE) # 12340000 .. 23450000
# Invalid grouping / 非法分组：
suppressWarnings(parse_cn_range("1 23-2 345"))
# Reversed bounds / 上下界颠倒：
suppressWarnings(parse_cn_range("2 345-1 234"))
```

## 回归覆盖 / Regression coverage

`tests/testthat/test-range-grouping.R` 新增 30 项断言，覆盖：

- 六种空格与七种分隔符的 42 种组合、全角数字、共享单位和单位内部空格。
- 小数、科学记数负号、负端点、会计括号和百分比。
- 非法分组、多分隔符、缺失端点、上下界颠倒、重复值、factor 和缺失整单元格。
- 500 条不同金额区间，以预先给定的数值上下界为答案，不只比较两条实现路径。
- 1,200 条混合重复区间，覆盖原生/回退批量去重后的完整原文、错误位置、
  错误原因和严格模式顺序。

Thirty new assertions include known numeric answers, not just native/R
agreement. Existing 509 assertions remain, for 539 total. The retained
fixed-seed native/R differential suite also passes with the updated range logic.

## 本地与平台检查 / Local and platform checks

最终源码包：`outputs/range-grouping/final-artifacts/cncleanr_0.2.10.tar.gz`。
SHA-256:

```text
E03499BC593CED259722D56CD406ABDF9957A2820D9041022171EE8608AD2315
```

- Windows 11、R 4.6.1、现有 GCC 15.2 UCRT：对该文件独立运行
  `R CMD check --as-cran --no-manual`，OK，退出码 0，539 项通过。
  日志：`outputs/range-grouping/final-check/cncleanr.Rcheck/`。
  本地未验证 PDF 或远程 incoming；依赖索引下载曾出现外部警告，最终检查为 OK。
- 保留的公开多领域/多来源审计、100,000 混合单元格、20,000 不同数值、
  长非法文本、清洗示例和 CSV 往返通过。版本门槛改用 R 版本对象比较，
  审计输出仍按实际包版本命名；没有新采集数据或覆盖历史版本输出。
- 固定源码提交 `c46519ccb9ba8163dae0452b994d230afa194c2b` 的
  [CI run 38259093127](https://github.com/Jorungandr/cncleanr/actions/runs/38259093127)
  五项任务均成功、每项 539 个断言。Windows、macOS、Linux devel/oldrel-1
  为 OK；Linux release 仅缺少 HTML Tidy 的 NOTE，PDF 手册为 OK。
- 暂存包文件逐一校验与固定提交的对应文件一致。早期 533 项候选文件
  `outputs/range-grouping/artifacts/` 不是正式发布附件。

The exact final archive passed local checking, retained data/CSV audits and
five CI jobs (539 assertions each). Linux release passed PDF generation with
only the missing-Tidy NOTE. Local PDF/remote incoming checks are not claimed.
Staged payload files match the fixed source commit. The earlier 533-assertion
candidate is historical, not the release attachment.

本轮没有改动 C 源码，未重新运行上一轮 ASAN/UBSAN/Valgrind；
[0.2.9 原生检查](native-stability.md) 是历史证据，不将其称为本轮 539 项的
原生工具检查。发布与正式附件下载安装结果见上文。

C sources are unchanged. Previous ASAN/UBSAN/Valgrind results belong to 0.2.9,
not a rerun of the current 539 assertions. Publication/download verification
is recorded above.
