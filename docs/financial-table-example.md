# 从真实财报表格到清洗结果

[English](financial-table-example_EN.md)

需要 GitHub 版 cncleanr 0.2.6。安装：

```r
pak::pak("Jorungandr/cncleanr@v0.2.6")
```

## 1. 保留原文，明确每行单位

以下前四行取自[苏宁易购 2019 年年报](https://www.suning.cn/static/snsite/contentresource/2020-04-20/d4ce9420-8511-4ada-ac1a-7578761392c7.PDF)第 6 页的 2019 年列。
表头是“千元”，但每股收益明确使用“元/股”，净资产收益率使用百分比。
原文在发布验收时已核对；这不是自动 PDF 提取功能。
末三行是人为添加的演示数据，不是原财报错误。

```r
library(cncleanr)

raw <- data.frame(
  source_row = 1:7,
  metric = c("营业收入", "归母净利润", "基本每股收益", "净资产收益率",
             "演示：缺失", "演示：格式错误", "演示：单位冲突"),
  text = c("269,228,900", "9,842,955", "1.07", "11.77%",
           "暂无", "1 2", "3万元"),
  kind = c("amount", "amount", "eps", "ratio", "amount", "amount", "amount")
)
cleaned <- raw
cleaned$value <- NA_real_
cleaned$output_unit <- ifelse(raw$kind == "amount", "元",
                             ifelse(raw$kind == "eps", "元/股", "比例"))
problem_parts <- list()

for (kind in unique(raw$kind)) {
  rows <- which(raw$kind == kind)
  # 仅金额行继承千元；每股收益和百分比不继承。
  header_unit <- if (kind == "amount") "千元" else NULL
  parsed <- suppressWarnings(parse_cn_number(raw$text[rows], unit = header_unit))
  cleaned$value[rows] <- as.numeric(parsed)
  problems <- cn_problems(parsed)
  if (nrow(problems)) {
    # index 是分组输入中的位置，必须先映射回原表。
    problem_parts[[kind]] <- cbind(
      raw[rows[problems$index], c("source_row", "metric", "text")],
      reason = problems$reason
    )
  }
}
problem_rows <- do.call(rbind, problem_parts)
rownames(problem_rows) <- NULL
cleaned
problem_rows
```

## 2. 检查结果与异常

`cleaned$value` 应为：

```r
stopifnot(isTRUE(all.equal(cleaned$value,
  c(269228900000, 9842955000, 1.07, .1177, NA_real_, NA_real_, NA_real_))))
stopifnot(identical(problem_rows$source_row, c(6L, 7L)))
```

营业收入为 269,228,900,000 元，净利润为 9,842,955,000 元。
每股收益仍为 1.07 元/股；11.77% 变成比例 0.1177，不是 11.77。
缺失标记“暂无”得到 `NA`，但不是解析错误。
第 6 行空格分组无效，第 7 行万元与表头千元倍率冲突：两者都得到
`NA` 并进入 `problem_rows`，原文保留供人工核对。

这里抑制警告是为了集中查看问题表，不是忽略失败。真实流水线可保存：

```r
write.csv(cleaned, "cleaned.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(problem_rows, "problems.csv", row.names = FALSE, fileEncoding = "UTF-8")
```

上面的命令会写入当前工作目录；重复运行会覆盖同名文件。
如果任何异常都必须停止，可在核对后改用 `strict = TRUE`。
单位来自你对表格的判断，本包不识别每股收益、人数等业务含义，也不校验财报事实。
