# 分批清洗、连续筛选与诊断导出

[English](cleaning-workflows_EN.md) | [完整可运行示例](../inst/examples/chunked-cleaning.R)

原始清洗示例从 GitHub v0.2.14 起提供。当前仓库新增分批汇总，使用 0.2.19
已有的 `cn_summary()`，不改变解析规则；运行前需安装 0.2.19 或更新的包。
现有 v0.2.19 标签／附件仍包含旧示例，
不含此次新增的累计流程；请在含本轮改动的 checkout 根目录运行：

```sh
Rscript inst/examples/chunked-cleaning.R
```

或安装包含本轮改动的 GitHub `main` 后运行安装包内的更新示例：

```r
source(system.file("examples", "chunked-cleaning.R", package = "cncleanr"),
       encoding = "UTF-8")
```

人为构造的八行数据供三种解析函数复用，不计入真实数据覆盖量。
脚本用一次性临时目录验证 CSV，返回各函数的状态和问题表；临时文件在结束时删除。
实际保存文件时选择明确的新路径，确认不会覆盖原有数据。

## 1. 分批时先取出问题，再合并普通表

`cn_problems()` 的行号只对应当前输入批次。不要指望 `rbind()` 或 `c()`
自动合并 `problems` 属性，也不能简单把批内下标当成全局行号。

```r
rows <- batches[[i]]                 # 该批在原表中的数据行位置
parsed <- suppressWarnings(parse_cn_number(raw$text[rows]))
p <- cn_problems(parsed)
source <- rows[p$index]              # 从批内位置映射回源表
review <- data.frame(
  source_row = source,
  id = raw$id[source],
  original = raw$text[source],
  reason = p$reason
)
```

对每批都生成相同结构的问题表，零错误时保留零行表而不是遗漏这个分支。
然后分别合并普通数值／数据表与问题表。完整脚本还检查空批次与无错误批次，
并逐列对比整列解析的结果。整列对照仅用于验收；生产分批清洗不必重复解析整列。
对于已经合并的普通表，使用显式源 ID／问题表关联，不要重新依赖诊断属性。

## 只保留分批汇总，不保留各批解析结果

完整脚本中的局部 `summarize_batches()` 是示例代码，不是新增包接口。它在每批
解析后立即调用 `cn_summary()`，只累加四项计数和按原因命名的频数，不保存
各批解析对象或逐行问题表。用 `setdiff()` 加入新原因，保留跨批首次出现顺序。

运行脚本后可查看示例返回值：

```r
result <- source("inst/examples/chunked-cleaning.R", encoding = "UTF-8")$value
result$number$summaries$mixed$counts
#>   total parsed missing failed
#> 1     8      4       2      2
result$number$summaries$mixed$reasons
```

数量、区间分别位于 `result$quantity`、`result$range`。空批次不增加计数；正常缺失
不算失败。同一源行出现在多个批次时按出现次数计数，不做去重。若生产任务要求每条
源记录只统计一次，需先保证批次不重叠；跨批的顺序也决定原因的首次出现顺序。

累计计数用 double 避免普通整数相加溢出；超过 2^53 后不能保证逐整数精确。
额外状态随不同失败原因数增长，解析临时内存随当前批次增长，不承诺固定内存。
本演示原文仍在内存中；实际文件分块需自行每次读入下一批。无需强制调用 `gc()`。

仅需汇总时不必保留逐行明细；若还需排查原文错误，应在释放当前批次前把问题表
另行写出，不能从累计频数恢复原始行号。脚本中的整批对照及多个场景只用于验收，
生产代码不应为了汇总再重复解析整表。脚本其他清洗／CSV 分支仍保留普通结果表。

## 2. 先区分“缺失”和“解析失败”，再删除 NA

二者都可能得到 `NA`，但只有失败行出现在问题清单中：

```r
status <- rep("parsed", nrow(raw))
status[is.na(values)] <- "missing"
status[review$source_row] <- "needs_review"
```

先保存完整 `review`。只保留 `!is.na(values)` 会同时删除正常缺失与错误行；
随后只检查清洗结果的诊断，不能证明原始输入没有错误。
示例的源行 2、5 是错误，3、7 是正常缺失。数量／区间结果分别检查
`value`／`lower` 列，不能将整个数据框的 `is.na()` 矩阵作为行筛选传给 `cn_subset()`。

## 3. 连续筛选时同步维护来源向量

对单个未修改的解析结果使用 `cn_subset()`，其问题下标始终对应当前结果：

```r
source_rows <- seq_along(raw$text)
selected <- cn_subset(parsed, first)
source_rows <- source_rows[first]
selected <- cn_subset(selected, keep)
source_rows <- source_rows[keep]
selected <- cn_subset(selected, ordering)
source_rows <- source_rows[ordering]
p <- cn_problems(selected)
original_rows <- source_rows[p$index]
```

这里的 `parsed` 是该流程起点的完整解析结果，不是附加 ID 列后的普通合并表。
每次重排都要同步更新来源向量；不能多次操作后只用最后一次的 `rows` 找源行。
重复取同一个错误源行，应保留重复的问题记录，不能按源行随意去重。
完整示例最终问题位于当前行 4、5、6，分别来自源行 5、2、5。

## 4. CSV 分别保存数值和问题，不保存 R 属性

至少分别导出结果表与问题表，并保留原文、源 ID、数据行位置、字段与原因。
示例还导出重复筛选后的问题表，读回核对数值、逻辑边界、限定词、ID、状态、
原文、原因和源行号，包括含引号和换行的原文。源行号不是 CSV 物理文件行号。

`read.csv(..., colClasses="character", na.strings=character())` 避免自动转换编号与源缺失标记。
CSV 本身不保留 `problems`；`cn_problems()` 不能从读回的 CSV 自动恢复诊断。
Excel 等软件自动打开文件还可能改变显示类型，不能替代这里的文本往返检查。

往返检查只针对示例中的数值。普通 CSV 可能损失 double 尾数、负零和 NA／NaN
区别；无损保存 R 解析对象请用 RDS，见 [CSV 保存边界](csv-cleaning.md#csv-不是无损的-r-对象备份)。
文本不等式的无穷边界仍需保留包含标志，不能只导出 `lower`／`upper`。

回归测试直接运行同一个脚本，五平台 CI 也执行它；不是另写一套与文档不同的流程。
补充回归还覆盖乱序／重复源行、不规则和空批次、限定数量与区间，以及 RDS
保存 double 边界值、NaN、负零和诊断属性。三接口只在共同支持的精确输入上
直接对比数值；限定词和范围的不同返回语义不是接口不一致。

## 分批汇总验收（2026-10-18）

当前仓库的累计汇总示例已通过[五平台检查](https://github.com/Jorungandr/cncleanr/actions/runs/39092573242)，
各通过 1442 项断言，Linux PDF／HTML 检查通过；新增部分的范围与限制见
[汇总验收记录](summary-validation.md#incremental-example-on-main-after-v0219)。
这不是新版发布，固定 v0.2.19 附件不包含此次示例更新。

## 历史一致性验收（2026-10-18）

新增工作流边界测试与双语 README 原文执行检查，完整验收见
[一致性记录](workflow-contract.md)。五平台包检查各通过 1301 项断言；
这不是新版发布，原有 v0.2.18 附件保持不变，其中仍为 1181 项断言。

## 历史验收记录（2026-10-15）

示例验收提交：`0574b41d7e4cf4a2f6772ff3de3949a76ee67e8e`。
[五平台 CI](https://github.com/Jorungandr/cncleanr/actions/runs/38690442453)
均为 OK，各通过 795 个断言；Linux PDF／HTML 手册检查通过。
本地对工作树源码包执行 `--as-cran --no-manual` 为 OK（不含远程 incoming 或本地 PDF）。
这是示例／测试更新，没有修改 R/C 解析代码、版本或既有发布附件；不是新的 CRAN 验收。
