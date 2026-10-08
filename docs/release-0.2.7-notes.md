# 中文

- 支持一个约数前缀搭配“左右”：`约15%左右` 返回 `0.15 / approx`。
- 仍拒绝混合不等式、重复前缀或后缀，以及 `±` 表达；约数不转换为确定区间。
- 同步双语 README 和帮助文档。
- 203 项测试及五组跨平台检查通过；已安装版本的财报、科研、企鹅观测数据验收和帮助页示例通过。
- 同批科研普通表达从 376 个增加至 377 个；37 个区间及其他特殊表达的处理保持不变。

GitHub 发布，未提交 CRAN。CRAN 仍为 0.2.5。

# English

- Accepts one approximation prefix paired with `左右`: `约15%左右` returns `0.15 / approx`.
- Mixed inequalities, repeated prefixes/suffixes, and plus/minus expressions remain invalid. Approximation does not define a deterministic interval.
- Updates bilingual README and help documentation.
- 203 assertions and five cross-platform jobs passed, along with installed-package validation on financial, scientific, and penguin data and runnable help examples.
- Scientific scalar expressions accepted in the same sample increased from 376 to 377; all 37 intervals and remaining special-expression outcomes are unchanged.

GitHub release only. No CRAN resubmission; CRAN remains at 0.2.5.
