# Open-bound workflow validation

## Corrections

The business validator misclassified valid open bounds such as `大于3` and
`小于3`. Two assumptions caused the failures. Numeric comparison calculated
`Inf - Inf`, yielding NaN. Range validation required both endpoints to be
inclusive, even for explicit strict inequalities and infinite endpoints.

Numeric comparison now handles equal infinities directly and applies the
existing relative tolerance to finite pairs. Optional fixture columns
`expected_lower_inclusive` and `expected_upper_inclusive` specify `TRUE` or
`FALSE`. Blank cells and omitted columns retain closed-interval expectations.
Other flag strings raise an explicit error.

## Regression coverage

`docs/business-boundary-audit.R` builds sixteen synthetic cases covering open
positive and negative bounds, percentages, exact values through all three
parsers, missing values, failures and a business-review row. The audit checks
leading-zero identifiers, original multiline quoted text, review row mapping,
CSV numeric read-back and exact RDS object round-trips through the validator.

Three additional export scenarios cover parsed-only, missing-only and
business-review-only inputs. Four deliberate errors verify rejection of an
incorrect inclusion flag, the wrong infinity sign, an incorrect finite value
and an invalid flag token. Failure messages are checked for the intended cause.

Local validation passed the new regression audit, the existing 22-case offline
sample, and all 6347 cases from the retained business snapshots. The full audit
produced 427 review rows. Existing chunking, CSV and diagnostic workflow examples
passed, along with 46 executable bilingual README/tutorial blocks.

The new audit is included in the Ubuntu release independent-install CI step.
The Chinese and English business guides document the extended fixture fields.

## 中文记录

本轮修复业务验证脚本的两处误报，分别涉及无穷数比较和区间端点包含标志。
新增 16 个合成边界案例、3 种导出场景及 4 个错误预期测试。原有 6347 个业务
案例重新运行通过，复核表共 427 行。分块处理、CSV 导入导出、诊断行号和双语
教程的可运行代码也已验证。

## GitHub verification

Source `a80f3810050c692fffad7f1fe630c493263d9018` passed all five CI jobs on
Ubuntu release/devel/oldrel-1, Windows release and macOS release. Ubuntu release
logs confirm the sixteen-case boundary audit, three export scenarios, four
negative probes, existing 22-case offline sample, 1832 package assertions,
`Status: OK` and PDF manual OK.
[View run 43230207735](https://github.com/Jorungandr/cncleanr/actions/runs/43230207735).

The downloaded log is retained in ignored
`outputs/business-boundary-validation/ci-ubuntu.log`.
