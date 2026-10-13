# Range endpoint missing markers / 区间端点缺失标记验收

2026-10-13，cncleanr 0.2.11。维护者已批准本轮缺失标记检查/修复和完整 GitHub
流程；不增加语法或依赖，不调优运行速度，不提交 CRAN。

## 发布完成 / Published

[GitHub v0.2.11](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.11)
已正式发布，固定标签指向 `c27d054238cc6f13e96c308826e8cd22ea2830d7`。
正式源码附件为 37,195 字节，GitHub digest 与发布后重新下载文件的 SHA-256
均与下文已检查文件一致。在独立库 `outputs/range-missing/public-library/`
安装后确认 0.2.11，53 项缺失标记回归及三个公开解析函数冒烟检查通过。
中英文 README、帮助页和 Release 说明已同步，旧标签/附件未改动；未提交 CRAN。

Published at the fixed commit above. The 37,195-byte public source asset was
downloaded after publication; its checksum and GitHub digest match the checked
archive. Isolated installation confirmed 0.2.11 and passed 53 endpoint-marker
assertions plus smoke checks for all three parsers. Bilingual docs/help are
synchronized. Previous releases were preserved; no CRAN submission was made.

## 原因与修复 / Root cause and fix

在正式安装的 0.2.10 上复现：`parse_cn_range("0-5万", na = "0")`
错误返回 0 到 50000；分组端点也可能被补单位后恢复为有效数值。
旧逻辑仅在补共享单位后的文本上检查标记，原来的 `0` 已变成 `0万`。
新增回归先在旧版失败，修复后通过。

修复复用两个候选路径共有的单位传播函数：从原始规范化端点保存缺失判断，
追加共享单位后将已标记端点恢复为 `NA`，再走既有数值校验。
后置缺失检查、整单元格优先、原始行号/原文、严格错误顺序保留。
分组恢复路径中未修复的失败仍保留既有分组诊断，不另造错误协议。

The original normalized endpoint is checked before suffix propagation and kept
missing afterward; existing post-propagation checks remain. The shared helper
fixes ordinary and grouped candidate paths without changing the API or C code.
Existing diagnostic conventions and original source rows are preserved.

标记按文本匹配，不按数值等价判断：`na = "0"` 不自动匹配显式 `0万`。
若设置 `na = "0万"`，补单位后的 `0万` 仍会被现有后置检查识别。
某端点缺失意味着不能确定区间，非严格模式记录问题并返回全 NA 行，严格模式报错；
若整个单元格匹配 `na`，仍是没有解析问题的普通缺失值。

Matching is textual, not numeric equivalence. An invalid/missing endpoint means
the range cannot be completed, whereas a whole-cell marker remains ordinary
missing data without a parsing problem. Numeric pass-through is unchanged.

## 检查 / Validation

- `tests/testthat/test-range-missing.R` 新增 53 项断言：金额/百分比、左右端点、
  全角与空格、负零、科学记数、分组路径、补单位后标记、整单元格优先、
  factor、1,200 条混合重复输入、原文/行号和严格错误。
- 本地完整测试通过；对正式源码文件独立运行
  `R CMD check --as-cran --no-manual` 为 OK、退出码 0，
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 592`（原有 539，加本轮 53）。
  本地没有检查 PDF 或远程 incoming。
- 既有公开多领域/多来源审计、100,000 混合单元格、20,000 不同数值、
  长非法文本和 CSV 往返通过；没有新采集数据或覆盖旧版本输出。
- 源码暂存文件逐一核对与固定提交对应文件一致；本轮 C 源码未改动，
  未重新执行上一轮原生工具检查，不把旧 ASAN/UBSAN/Valgrind 结果称为本轮结果。

Final checked archive:
`outputs/range-missing/artifacts/cncleanr_0.2.11.tar.gz`

SHA-256:

```text
3444FB65E6FDBD109CB76F7E293F034AE2417B27FE7469869D2D648114919166
```

Logs: `outputs/range-missing/check/cncleanr.Rcheck/`.
The exact archive passed local checks and retained data/CSV audits. No local
PDF, remote incoming, new data collection or fresh native-tool results are claimed.

## 最终提交 CI / Final-commit CI

提交 `c27d054238cc6f13e96c308826e8cd22ea2830d7` 的
[CI run 38337472324](https://github.com/Jorungandr/cncleanr/actions/runs/38337472324)
五项任务均成功，每项 592 个断言，实际日志已核对。Windows、macOS、
Linux devel/oldrel-1 为 OK；Linux release 仅缺少 HTML Tidy 的 NOTE，
PDF 手册为 OK。正式发布与附件下载/安装结果见上文。

All five final-commit jobs passed 592 assertions. Linux release passed PDF
generation with only the missing-Tidy NOTE. Public-asset verification is
recorded above.
