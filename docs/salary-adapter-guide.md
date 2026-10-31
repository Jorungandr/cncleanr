# 薪资字段示例适配器

[English](salary-adapter-guide_EN.md)

这是 GitHub 仓库中的独立示例，不是 cncleanr 的第七个公开函数，也不包含在
已安装包的 docs 目录中。先取得仓库代码，安装 cncleanr 0.2.25 或匹配的开发版，
从仓库根目录执行：

```r
source("docs/salary-adapter.R", local = TRUE, encoding = "UTF-8")
```

## 完整字段解析和复核

```r
result <- salary_example(c("月薪3-5万元", "15-25K·13薪",
  "底薪5000+提成", "面议", NA_character_), currency = "CNY")
result$data
result$review
stopifnot(identical(result$data$status,
  c("parsed", "needs_context", "conditional", "negotiated", "missing")))
stopifnot(identical(result$review$index, 2:4))
```

第一行是每月 30000—50000；第二行缺少周期，金额暂不输出，13 薪声明仍保留。
第三行无法确定总收入，第四行面议不等于零，真正缺失的第五行不进入复核表。
仅 `status == "parsed"` 的金额可以用于后续业务处理；比较时还须确认 period 和 currency 相同。

`currency` 是调用方提供的三位大写来源标签，不验证 ISO 登记、不换汇、不自动识别币种。
留空则不推断 CNY/TWD；明显的 RMB／币种标签冲突会被拒绝。

## 明确的字段上下文

```r
monthly <- salary_example("15-25K·13薪", context_period = "month", currency = "CNY")
stopifnot(monthly$data$lower == 15000, monthly$data$upper == 25000,
          monthly$data$advertised_payments == 13L, monthly$data$period == "month")
```

只有来源确实定义该字段为月薪时，才传 `context_period="month"`。可选周期为
hour/day/month/year；显式文本与上下文冲突会进入复核，不覆盖文本。
`月薪`、`年薪`、`日薪`、`时薪`、`每小时` 和 `/月`、`/年`、`/天`、`/小时`
是支持的包装形式；前后周期同时存在时必须一致。`周结` 不等于周薪，首版保留复核。

N 薪前须有中点 `·`、星号 `*` 或空白分隔，N 为可表示的正整数；没有默认 12 薪。
`advertised_payments` 仅记录声明，不证明每笔等额或保证发放，也不自动生成年薪。
N 薪与已明确的年／日／小时周期并列时，保留条件复核，不相乘或自行解释。

薪资金额末尾的裸 `+`（包括全角加号）可能表示未说明的收入组成，因此进入
conditional 复核，不输出金额。需要明确下限时使用“以上”，例如 `月薪3000元以上`。
该策略只用于此示例，普通 `parse_cn_range("10万+")` 的行为不变。

金额中的 K/k 映射为 1000，然后交给现有 `parse_cn_range()` 批量处理。
保留单值、区间、以上／以下边界及包含标志；不自行补零下界。全角字符和所列
破折号可规范化，但数字间空白仍须通过原解析器的分组校验，不拼接任意数字。

底薪、提成、奖金、绩效、税前／税后、试用／转正等条件，以及未知尾文、W/M、
百分比、0 或负数金额不输出可用薪资数值。没有整段招聘公告扫描或自动选取第一个金额。
`na` 仅按规范化后的完整原字段匹配，调用方若明确将“面议”列为缺失，则遵从该策略。
输入限无维度的字符／因子向量；编码等整批错误仍可中止调用。

## 结果结构与保存

结果为普通 list：data 保留 index/raw、金额上下界、包含标志、period、
advertised_payments、currency、status；review 保留 index/raw/reason，并保留重复行。
除 parsed 外金额及包含标志为 NA。不要把 data 当作原解析结果传给
`cn_problems()`、`cn_subset()` 或 `cn_summary()`；直接使用此例的 review 表。
重排时按 index 显式维护来源关系。

```r
write.csv(result$data, "salary-data.csv", row.names = FALSE, na = "", fileEncoding = "UTF-8")
write.csv(result$review, "salary-review.csv", row.names = FALSE, na = "", fileEncoding = "UTF-8")
saveRDS(result, "salary-example.rds")
stopifnot(identical(readRDS("salary-example.rds"), result))
```

上述文件写入当前目录并覆盖同名文件；CSV 不是无损 R 对象备份。需要保留原始
NA、诊断和全部数值位时使用自己保存的 RDS。示例 source 时只定义函数，不自动写文件。

来源与人工分类见[适配评估](salary-support-assessment-2026-10-30.md)和
[19 个来源片段说明](fixtures/salary-source-cases-README.md)。合成边界与来源样本分开验证，
不能把这 19 个选择性样本的通过结果当作真实招聘市场准确率。
