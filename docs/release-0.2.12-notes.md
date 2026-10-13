# cncleanr 0.2.12

## 中文

本次集中修复正确性和工程验收问题，不扩充功能或重启性能调优。

- 拒绝百分比与金额/数量混合的区间，保留合法共享单位和万/亿区间。
- 修复 factor/空向量名称丢失、小数空格分组不一致及端点诊断错误。
- 极端数值按最终倍率救回可表示结果；最终非零下溢明确报告，不再返回零。
- 限制异常区间分隔符候选；新增独立答案回归，保留 C/R 差异与编码测试。
- 修复真实数据审计入口，校验加载版本与快照哈希，增加源码附件验收入口。
- 同步中英文文档、编译说明、诊断属性限制和 CRAN 草稿；不提交 CRAN。

兼容性：新增单位冲突、最终下溢及过多分隔符原因；部分旧“分组错误”
改为准确的端点原因。普通数值转换、公共签名及未决语义保持不变。

## English

Consolidated correctness and release-validation hardening, not new syntax or
another performance campaign. Fixes incompatible range units, factor/empty
names, fractional grouping, grouped endpoint diagnostics and extreme scaled
conversion. Final nonzero underflow is now reported instead of silently becoming
zero. Malformed separator expansion is bounded. Independent gold tests augment
native/R differential and encoding regressions.

Current data audits load the matching installed version; snapshot hashes and
source-asset verification are executable. Bilingual docs and CRAN draft are
updated. Existing APIs, ordinary rounding and undecided semantic policies remain.
New reasons cover incompatible units, final underflow and excessive separators;
grouped endpoint failures now report their actual category. No CRAN upload.

Validation evidence: [systematic hardening record](https://github.com/Jorungandr/cncleanr/blob/main/docs/systematic-hardening.md).
