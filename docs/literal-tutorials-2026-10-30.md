# Literal bilingual tutorial validation / 双语教程原文执行检查

Source checkpoint: e6c96e3212a7f77e21f2c2592189703d615c4df5.

## Change / 更新

The existing docs/readme-audit.R now also executes the literal R fences in both
financial-table and business-workflow tutorial editions. No duplicate framework,
new package dependency, parser change or public API is introduced. The existing
five-platform CI already sources this audit, so all four tutorials are covered
without adding jobs.

Each tutorial has an isolated temporary directory and evaluation environment;
the audit restores its starting directory and removes its owned temporary tree.
Installation fences are counted and deliberately not executed. Unexpected R
warnings/errors fail validation. Business import blocks read the attributed
22-case fixture copied to their documented relative path, not a full snapshot.

财报教程的金额／每股收益／百分比按原文代码运行，并执行已有数值和源行号断言。
另读回实际导出的两个 CSV，核对原文、源行、单位、数值及问题原因。业务教程
直接运行两版原始 R 代码块；完整 6347 案例仍为上一轮的本地真实快照验证，
本轮不能把 22 个离线案例算作新增真实数据。

## Local checks / 本地检查

Installed cncleanr 0.2.25, Windows R 4.6.1, optional units 1.0.1:

| Document | Runnable R blocks | Installation blocks not executed |
| --- | ---: | ---: |
| Chinese README | 14 (includes one expected error) | 3 |
| English README | 14 (includes one expected error) | 3 |
| Chinese financial table tutorial | 3 | 1 |
| English financial table tutorial | 3 | 1 |
| Chinese business tutorial | 2 | 0 |
| English business tutorial | 2 | 0 |

38 runnable blocks locally, including ten newly automated tutorial blocks.
README optional units blocks may be explicitly skipped where units is absent;
none of the ten tutorial blocks requires that optional package.

Two failure probes modified disposable document copies only:

* Export one fewer financial result row: the source-text/export alignment check
  rejected it.
* Add an unexpected warning to a business import block: the warning handler
  rejected it.

Both checks failed for the intended reason, and tracked source files remained
unchanged. The final clean-source local audit passed without R warnings. The
first draft's read-back coercion of CSV's literal NA marker was corrected in
the audit; it was not a production parser defect.

Production R/src/DESCRIPTION/NAMESPACE and package tests remain identical to
v0.2.25. No new package version, tag, archive replacement, benchmark, sanitizer
claim, new data collection or CRAN submission.

## GitHub results / GitHub 结果

Run 41075540419 succeeded on all five jobs: Ubuntu devel 124130596588,
Windows release 124130596975, Ubuntu release 124130597063, Ubuntu oldrel-1
124130597135, macOS release 124130597342. The final macOS conclusion was
independently confirmed with its job API after a slow aggregate status request.
Downloaded Ubuntu logs explicitly show all four literal tutorial editions with
3/3/2/2 runnable blocks, Status OK, 1832 passing package assertions, PDF manual
OK and 22 passing offline business cases. Existing extended audits also ran.

The final evidence-only documentation commit does not change the validated
auditor, tutorial code or workflow. Main is updated; v0.2.25's public tag and
archive remain unchanged.
