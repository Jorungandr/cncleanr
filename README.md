# cncleanr

[English](https://github.com/Jorungandr/cncleanr/blob/main/README_EN.md) | **中文**

[![R-CMD-check](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Jorungandr/cncleanr/actions/workflows/R-CMD-check.yaml)

`cncleanr` 用于安全解析中文表格、网页和统计公报中的紧凑数字、模糊数量及数值区间。

它不会只截取字符串中遇到的第一个数字。无法完整解释的非缺失值会变成 `NA`，同时产生警告并记录失败原因。

## 安装

### 正式版本

从 [CRAN](https://CRAN.R-project.org/package=cncleanr) 安装（2026-10-12 核对为 0.2.5；下文表头单位功能从 0.2.6 开始提供）：

```r
install.packages("cncleanr")
```

也可以从 GitHub 安装版本 v0.2.17，包含 SPSS 缺失值、带单位输入及既有诊断修复：

```r
install.packages("pak")
pak::pak("Jorungandr/cncleanr@v0.2.17")
```

### 开发版本与源码安装

需要后续开发改动时，可以安装开发分支（`main` 会随开发变化；可将 `main` 换成完整提交 SHA 来固定代码）：

```r
install.packages("pak")
pak::pak("Jorungandr/cncleanr@main")
```

开发版仍是一个 R 包、一套 R 接口，内含注册的 C 数值和字符规范化函数。源码安装必须先准备编译工具；没有可用编译器时会安装失败，不会自动改装为纯 R 版本。

从 0.2.9 开始，规范化会明确拒绝非法 UTF-8（如截断字节序列），而不是继续处理损坏的文本。
这是编码错误，不是普通的数值解析失败；`strict = FALSE` 也会报错，不会产生可继续使用的部分结果。
请先按数据实际编码正确导入或转换；有效 UTF-8 和 Latin-1 文本的处理不变。
从 0.2.13 起，错误会指出 `x` 或 `na` 中首个失败值的原始位置，例如
``Input `x` at position 3``，而不是去重或回退后的内部位置。

- Windows：安装与 R 版本匹配的 [Rtools](https://cran.r-project.org/bin/windows/Rtools/)。
- macOS：准备 Xcode Command Line Tools 和与 R 兼容的 C 编译器，参见 [R 官方安装说明](https://cran.r-project.org/doc/manuals/r-release/R-admin.html#macOS)。
- Linux：准备 C 编译器、`make` 和 R 开发文件，参见 [R 官方源码包安装说明](https://cran.r-project.org/doc/manuals/r-release/R-admin.html#Installing-packages)。

本包自身没有 Fortran、OpenMP 或额外运行时 R 依赖。若安装适合系统和 R 版本的预编译二进制包，不需要本地编译本包；GitHub `main` 安装属于源码安装，不要假设有对应二进制包。

安装后重启 R 会话，再检查实际加载的版本和路径：

```r
library(cncleanr)
packageVersion("cncleanr")
find.package("cncleanr")
parse_cn_number(c("3万", "１２．５％"))
#> [1] 30000.000     0.125
```

v0.2.8 为包含本轮优化的正式标签；源码安装需要上述编译工具。`main` 可能继续变化，需要复现时应使用固定标签或记录安装的提交 SHA。

### 性能与发布准备

跨平台验收和用户可见的更新摘要见[下一版发布准备](docs/release-next.md)。

开发版性能记录：[C 数值加速](docs/native-optimization.md)、[限定词与字符标准化优化](docs/qualifier-optimization.md)、[混合批次优化](docs/mixed-optimization.md)、[格式化数值优化](docs/formatted-optimization.md)。计时随格式和重复率变化，不保证所有输入达到相同耗时。

开发版已将全角字符和特殊负号转换合并为共享 C 扫描，供数字、数量和区间解析复用；空白分组检查仍保留。本地百万条全角样本耗时由 0.99 秒降至 0.66 秒，详见上述格式化数值性能记录。

空白清理也已复用该 C 扫描；数字之间的空白仍先检查分组合法性，不会把 `1 2` 悄悄解析成 `12`。

本轮性能调优收尾记录见[性能总结](docs/performance-final.md)：涵盖十万条、百万条以及三种解析函数，保留完整错误诊断。后续维护以正确性、兼容性和实际问题为主，不承诺所有格式统一低于 0.1 秒。

0.2.14 修复五千位等超长有效数字配合抵消指数时的误拒绝，并保留舍入临界点的尾数方向。
补救仅用于超长、极端数值的回退路径，普通数值快速路径不变；见[修复与性能验证](docs/long-decimal.md)。

## 企业营收清洗示例

本轮修复与检查记录见[系统整改](docs/systematic-hardening.md)，公开数据复现见[快照与审计入口](docs/data-audit-reproduction.md)。

完整案例：[真实财报清洗：表头单位、混合指标与异常定位](docs/financial-table-example.md)。

公开数据案例：[将缺失值、错误标记与长文本分开处理](docs/open-data-cleaning.md)。

CSV 工作流：[保留原文与编号、按列处理单位、导出异常清单](docs/csv-cleaning.md)。

进阶流程：[分批合并、连续筛选排序与 CSV 诊断保存](docs/cleaning-workflows.md)。
这些示例与测试随 0.2.14 一并提供，不改变分批合并及诊断保存的既有规则。

下面的流程保留原始文本，解析营收列，并把无法解析的记录定位回原始企业：

```r
library(cncleanr)

enterprises <- data.frame(
  company = paste0(c("甲", "乙", "丙", "丁", "戊"), "公司"),
  revenue_raw = c("3.2亿元", "约5万", "10万+", "暂无", "3万abc")
)

parsed <- suppressWarnings(parse_cn_quantity(enterprises$revenue_raw))
cleaned <- cbind(enterprises, parsed)
cleaned
#>   company revenue_raw   value qualifier
#> 1 甲公司     3.2亿元 3.2e+08      exact
#> 2 乙公司       约5万 5.0e+04     approx
#> 3 丙公司       10万+ 1.0e+05   at_least
#> 4 丁公司        暂无      NA       <NA>
#> 5 戊公司      3万abc      NA       <NA>

problems <- cn_problems(parsed)
problem_rows <- cbind(
  company = enterprises$company[problems$index],
  problems
)
problem_rows
#>   company index  value                                      reason
#> 1 戊公司      5 3万abc value does not match the supported number syntax

write.csv(
  cleaned,
  "enterprise_revenue_cleaned.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
```

这里使用 `suppressWarnings()`，是因为下一步会通过 `cn_problems()` 检查完整的结构化问题；如果不准备检查问题，不建议隐藏警告。

## 精确数字

```r
library(cncleanr)

parse_cn_number(c("1.25万", "￥3亿元", "12.5%", "１．２e５", "暂无"))
#> [1] 1.25e+04 3.00e+08 1.25e-01 1.20e+05       NA
```

支持的常见形式包括：

- `万`、`亿`、`万亿`，以及金额单位 `千元`（如 `1.5千元` 为 `1500`）；
- `元`、`人民币`、`￥`、`¥`、`RMB`、`CNY`、`块`和`块钱`；
- 百分数和科学计数法；
- 全角数字、标点、指数，以及 PDF 常见的异体负号；
- 普通空格、不间断空格、窄空格和全角空格组成的合法三位分组；
- 普通负数和会计括号负数；
- 可配置的缺失值标记。

数字间的空格只在构成合法三位分组时才会被接受：`1 234` 会解析为 `1234`，但 `1 2` 和 `12 34` 会报告错误，不会被静默拼接。

## 表头单位

表头注明“单位：千元”，单元格却只有数字时，可显式传入 `unit`：

```r
parse_cn_number(c("123.5", "1.5千元", "暂无"), unit = "千元")
#> [1] 123500   1500     NA
```

支持 `元`、`千元`、`万`、`万元`、`亿`、`亿元`、`万亿`、`万亿元`。
没有单位的值按表头换算；已有相同倍率的单位只换算一次（`万` 和 `万元`
视为同倍率）。不同倍率的显式单位、百分比会报告问题，不会自动覆盖。
不传 `unit` 时行为不变。传入 `unit` 时，数值型输入也进行换算，
`NA`/`NaN` 作为缺失值，`Inf`、`-Inf` 和换算溢出报告问题。
从 0.2.15 起，带类的数值输入也先调用 `as.double()`（包括适用的 S3 方法），
再按转换后的数值判断缺失和换算，保留原始名称；见[转换一致性验收](docs/numeric-conversion.md)。
本参数仅用于 `parse_cn_number()`，不自动读取或识别表头。
仅对适用的金额行或列传入表头单位；同表中的每股收益（元/股）、
人数或比率可能有自己的单位，不能整表统一乘以金额倍率。

## 导入类型与单位安全

从 0.2.17 起，三个解析接口都尊重 `haven_labelled_spss` 的 `na_values`／
`na_range`：例如定义为缺失的 97、99 不会再变成真实数值，字符型特殊缺失也不再
误列为解析错误。普通标签仍按原始编码处理，不把标签文字当数字；不传表头单位时
保留既有 NA／NaN／带标签 NA，表头换算仍按现有规则统一输出缺失值。

直接传入 `units` 对象现在会报错（包括空向量、无量纲单位），而不是静默丢弃单位。
请先明确转换到所需单位，再显式移除单位，例如：

```r
x <- units::set_units(c(1000, 2000), "m")
x <- units::set_units(x, "km")
parse_cn_number(units::drop_units(x))
#> [1] 1 2
```

这不是自动单位识别或金额转换。上述第三方包不是本包运行时依赖。
integer64 转 double 的精度警告仍会传出，不能保证大整数或金额的十进制精确性。
详细范围及复现见[导入类型验收](docs/import-types.md)。

## 模糊数量与不等式

GitHub 0.2.7 允许一个约数前缀搭配“左右”：`约15%左右` 返回
`value = 0.15`、`qualifier = "approx"`。混合不等式、重复前缀或后缀
仍报告问题；约数不自动转换为确定区间。此改动不在 0.2.6 中。

`parse_cn_quantity()` 保留原文中的约数与模糊限定含义。

```r
parse_cn_quantity(c("3万", "约3万", "超过2亿", "不少于5万", "10%以下"))
#>     value    qualifier
#> 1   3e+04        exact
#> 2   3e+04       approx
#> 3   2e+08 greater_than
#> 4   5e+04     at_least
#> 5   1e-01      at_most
```

六种 `qualifier` 的含义和边界如下：

| `qualifier` | 含义 | 边界语义 |
| --- | --- | --- |
| `exact` | 精确值 | 等于 `value` |
| `approx` | 约数 | 以 `value` 为近似值，不定义开闭边界 |
| `greater_than` | 大于 | `> value`，不包含边界 |
| `at_least` | 不小于 | `>= value`，包含边界 |
| `less_than` | 小于 | `< value`，不包含边界 |
| `at_most` | 不大于 | `<= value`，包含边界 |

常见不等式表达具有明确的边界含义：

- `大于3万`、`小于3万`：不包含边界；
- `超3万` 按“大于3万”处理，不包含边界；
- `不大于3万`、`不小于3万`：包含边界；
- `<`、`>`、`<=`、`>=`、`≤`、`≥` 及其全角形式也可以使用；
- `10万+` 按“不少于10万”处理；
- `50余`、`10万余`、`50余万` 和 `50余万元` 均保留“大于”的限定含义。

## 数值区间

`parse_cn_range()` 返回上下界以及边界是否包含在区间内。

```r
parse_cn_range(c("3万-5万", "3-5万", "10万元以上", "低于2亿"))
#>   lower upper lower_inclusive upper_inclusive
#> 1 3e+04 5e+04            TRUE            TRUE
#> 2 3e+04 5e+04            TRUE            TRUE
#> 3 1e+05   Inf            TRUE           FALSE
#> 4  -Inf 2e+08           FALSE           FALSE
```

`3-5万` 这类共享单位会自动应用到数据区间的两个端点；`3-5千元` 为 `3000` 到 `5000`。上下界颠倒或端点无法解析时会报告问题。
科学计数法中的符号不会被误认为区间分隔符，因此 `1e-3` 和 `1e-3-2e-3` 都可以正确解析。

从 0.2.10 开始，区间中的三位空格分组按两个端点分别校验：
`1 234-2 345` 返回 `1234` 到 `2345`，`1 234-2 345万元` 返回
`12340000` 到 `23450000`。`1 23-2 345` 仍报告非法分组，不会直接删除
空格拼接数字；`2 345-1 234` 报告上下界颠倒。单个约数不能替代确定区间。

从 0.2.11 开始，文本端点的缺失标记在补共享单位前后都检查。
设置 `na = "0"` 时，`0-5万` 会因缺失端点报告问题，不会把 `0` 补成
`0万` 后恢复成有效值；`strict = TRUE` 会报错。标记按规范化文本匹配，
不是数值相等比较，因此 `0万-5万` 不匹配标记 `"0"`。若整个单元格本身
匹配 `na`，仍按普通缺失值处理，不产生解析问题。

## 返回值速查

所有解析函数都保持输入顺序，每条输入对应一条结果；问题信息可以从结果对象中单独取出。

| 函数 | 返回值 |
| --- | --- |
| `parse_cn_number()` | 数值向量，每条输入对应一个值 |
| `parse_cn_quantity()` | 含 `value` 和 `qualifier` 两列的数据框 |
| `parse_cn_range()` | 含 `lower`、`upper`、`lower_inclusive` 和 `upper_inclusive` 四列的数据框 |
| `cn_problems()` | 含 `index`、`value` 和 `reason` 三列的数据框；没有问题时返回零行 |

数值型输入会直接转换为双精度数值并保留，包括 `Inf`、`-Inf` 和 `NaN`。
`parse_cn_quantity()` 将有限数值及 `Inf`、`-Inf` 标记为 `exact`，而
`NA`、`NaN` 的限定词为缺失。`parse_cn_range()` 将非缺失数值表示为包含
该值的点区间；由文本不等式生成的无穷边界表示开放区间，与数值型
`Inf`、`-Inf` 点输入不同。

## 查看解析问题

```r
result <- suppressWarnings(parse_cn_number(c("2万", "约3万", "abc")))
cn_problems(result)
#>   index value                                      reason
#> 1     2  约3万 value does not match the supported number syntax
#> 2     3   abc value does not match the supported number syntax
```

普通模式会把失败位置返回为 `NA`，保留其他可用结果，同时发出警告。清洗流程如果要求“任意一行失败就停止”，可以设置 `strict = TRUE`：

```r
parse_cn_number(c("2万", "abc"), strict = TRUE)
```

无论使用哪种模式，自定义缺失值（例如默认支持的 `"暂无"`）都不算解析失败。

### 筛选和排序时保留诊断

从 0.2.13 起，使用 `cn_subset()` 显式筛选、重排或重复取行；数字向量和数据框的返回类型不变：

```r
parsed <- suppressWarnings(parse_cn_number(c("bad", "2万", "wrong", "1万")))
rows <- c(3L, 2L, 1L, 3L)
selected <- cn_subset(parsed, rows)
cn_problems(selected)$index
#> [1] 1 3 4
cn_problems(selected)$value
#> [1] "wrong" "bad" "wrong"
clean <- cn_subset(parsed, !is.na(parsed))
sorted <- cn_subset(parsed, order(parsed, na.last = TRUE))
```

问题行号始终对应当前结果的位置；如需原始编号，保留 `rows` 并通过
`rows[cn_problems(selected)$index]` 映射回原输入。重复取行会重复对应的问题记录。
从 0.2.16 起，带类的数值下标先用 `as.double()` 转换一次再校验和筛选，
包括 integer64 下标；原始编号请随实际选择同步维护。见[系统检查记录](docs/system-audit.md)。
逻辑筛选必须与输入等长；数值索引支持整数、零和负索引，不接受缺失、非整数或越界值。
普通 `[]`、修改、合并结果仍不自动维护诊断；请先使用此函数，它不能修复已经丢失或过期的属性。
可运行示例和验证记录见[诊断工作流](docs/diagnostic-workflow.md)。

## 常见失败原因

`cn_problems()` 的 `reason` 可以直接用于定位以下问题：

| 情况 | 示例 | `reason` |
| --- | --- | --- |
| 不支持的语法 | `3万abc` | `value does not match the supported number syntax` |
| 数字空格分组无效 | `1 2` | `digits use invalid whitespace grouping` |
| 限定词重复或冲突 | `超过3万左右` | `multiple or conflicting qualifiers` |
| 区间上下界颠倒 | `5万-3万` | `range lower bound is greater than its upper bound` |
| 区间端点无效 | `3万-abc` | `one or both range endpoints are invalid` |
| 数值超出有限双精度范围 | `1e308万` | `value is outside the finite double range` |

遇到失败时，先在普通模式下调用解析函数并查看 `cn_problems()`；只有在清洗流程要求“任意一行失败就停止”时，才使用 `strict = TRUE`。

## 开发与测试

项目包含两套测试：

- `tests/parser.R`：无额外依赖的基础包检查；
- `tests/testthat/`：覆盖边界条件和错误行为的完整开发测试。

每次推送都会在 Linux、macOS 和 Windows 上运行 GitHub Actions 检查。

Windows 本地开发若在 R 退出时遇到 `cli` 引发的崩溃，可使用
[`docs/run-r.ps1`](docs/run-r.ps1) 启动 R：它仅在缺失时补齐架构环境变量，
不修改全局环境，并保留真实退出码。详情见[环境诊断](docs/environment-diagnosis.md)。

## 设计边界

结果使用双精度浮点数，不是任意精度整数或十进制金额；超过 `2^53` 的整数可能舍入。
从 0.2.12 起，`1e309%`、`1e-330万亿` 等先换算后可表示的值会保留；最终仍舍入为零的非零文本报告下溢，不再静默返回零。
小数部分不支持空格分组，`.1 234` 和 `0.1 234` 都会被拒绝。
百分比与金额/数量不能混成区间，例如 `3%-5元`；`3-5%` 和 `3万-5亿` 仍然有效。
区间候选分隔符超过八个时明确拒绝，以限制异常文本的资源消耗。

筛选或排序时用 `cn_subset()`；若使用普通 `[]` 或合并、修改结果，请事先提取 `cn_problems()`，这些操作不会自动维护诊断属性。
缺失标记按文本匹配，不按数值相等匹配；限定数量仍匹配整格文本。矩阵/数组沿用展平行为，建议显式传入目标列。
会计括号内单位的共享规则、无效 UTF-8 的整批中断策略保持不变。

当前 CI 覆盖 Linux 的 R release/devel/oldrel-1，以及 Windows/macOS 的 R release；并未验证每个旧 R 版本、区域设置或硬件架构。

`cncleanr` 专注于实际数据源中的阿拉伯数字加中文单位，例如 `3.2亿元`、`约5万` 和 `3万-5万`。中文文字数字（例如“一万三千”）暂不属于本包的核心范围。

## 许可证

MIT
