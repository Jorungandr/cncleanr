# 按配置清洗 CSV 并输出复核与汇总

[English](table-cleaning-guide_EN.md)

从完整仓库根目录运行，需要已安装 cncleanr 0.2.25。
示例函数 `clean_cn_csv()` 位于 `docs/table-cleaning.R`。

```r
source("docs/table-cleaning.R", local = TRUE, encoding = "UTF-8")
```

`spec` 每行配置一个字段。`column` 指定 CSV 列名，`parser` 选择 `number`、
`quantity` 或 `range`，`unit` 填明确的金额表头单位或空字符串。
例如下面的 amount 按百元换算，interval 按千元换算，estimate 保留原有限定词。

```r
raw <- data.frame(
  id = c("0001", "0001", "0003", "0004"),
  amount = c("3", "bad", "暂无", "4百元"),
  estimate = c("约3万", "5万+", "暂无", "wrong"),
  interval = c("大于3", "3-5", "暂无", "bad")
)
input <- tempfile(fileext = ".csv")
write.csv(raw, input, row.names = FALSE, fileEncoding = "UTF-8")
spec <- data.frame(
  column = c("amount", "estimate", "interval"),
  parser = c("number", "quantity", "range"),
  unit = c("百元", "", "千元")
)
output_dir <- tempfile("cleaned-run-")
result <- clean_cn_csv(input, spec, output_dir, id_column = "id", chunk_size = 2L)
result$summary
result$review
stopifnot(identical(result$review$source_row, c(2L, 4L, 4L)))
stopifnot(identical(result$cleaned$amount__value, c(300, NA, NA, 400)))
```

用于自己的数据时，将 `input` 换成 CSV 路径，`output_dir` 换成一个新输出目录。
上例使用 R 临时目录，会话结束后可能被清理。文件须为 UTF-8，字段名须唯一。
损坏的编码、引号或字段数量会停止导入。
数据按文本导入，保留前导零、重复 ID 和原文。百分比字段应按来源定义带 `%`，
表头单位可用元、百元、千元、万／万元、亿／亿元、万亿／万亿元。

## 输出内容

| 文件 | 内容 |
| --- | --- |
| `cleaned.csv` | 原始列、`.source_row`、各配置列的数值／限定词／边界和状态 |
| `review.csv` | 原始数据行、ID、字段、原文和失败原因，每个失败字段一条记录 |
| `summary.csv` | 每列的 total、parsed、missing 和 failed 数量 |
| `reasons.csv` | 每列按失败原因累计的数量 |
| `result.rds` | 完整返回列表，含上述四张表及 spec |

派生列形如 `amount__value`、`estimate__qualifier`、`interval__lower`、
`interval__upper_inclusive` 和 `amount__status`。状态为 parsed、missing 或
needs_review。原数据中的同名列和 `.source_row` 会明确报告冲突。
百元、千元等金额表头换算后的数值以元表示，summary 的 unit 列保留配置的源表头单位。
复核表按配置字段及源行顺序输出，重复 ID 按位置保留。source_row 是数据记录
位置，多行 CSV 单元格可能占多个物理文本行。`id_column = NULL` 时复核 ID 为缺失。

```r
restored <- readRDS(file.path(output_dir, "result.rds"))
stopifnot(identical(restored, result))
review <- read.csv(file.path(output_dir, "review.csv"), colClasses = "character",
  na.strings = character(), fileEncoding = "UTF-8")
stopifnot(identical(review$id, c("0001", "0004", "0004")))
```

CSV 的数值写出可能舍入末位，空单元格也会合并部分缺失表示。保留原文、状态、
限定词和边界标志，并使用自己保存的 RDS 保留精确 R 对象。
输出文件先写入相邻临时目录，全部成功后发布到新目录。已有目录会报告错误。

`chunk_size` 控制解析批次，默认每批 10000 行。输入 CSV 和最终结果整体保留在
内存中，逐字段累计汇总。需要复核时，所有问题记录会保留到导出完成。
