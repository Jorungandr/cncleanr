# 薪资表达适配评估 / Salary adaptation assessment

历史评估提案：用户随后确认按独立示例适配器继续实现，现有六个函数不变。
该评估原先尚无实现；现可查看[中文用法](salary-adapter-guide.md) /
[English guide](salary-adapter-guide_EN.md)。没有修改包、依赖、版本或发布附件。

## 已核对的真实表达

核对日期：2026-10-30。以下为五个公开页面的 19 个选定薪资表达／数值片段，
不是随机样本、当前有效职位数量或完整可再分发数据集。不保存联系人、简历或整页招聘正文。
历史公告只证明这种表达存在，不代表仍在招聘。片段必须连同来源上下文解释。

| 来源 | 样本数 | 选定表达及上下文 | 首版建议 |
| --- | ---: | --- | --- |
| [剧星传媒招聘页](https://www.visionstar.cn/recruitment?page=12) | 5 | `6-9K·13薪`、`9-12K·14薪`、`6-8K`、`15-25K·13薪`、`2-3K`；选定薪资片段没有显式计价周期 | 缺周期上下文时复核，不能擅自当作月薪 |
| [独角招聘列表](https://www.dujiao.net/job?page=3&title=%E6%96%87%E6%A1%88) | 5 | `12K-20K/月`、`8K-15K/月`、`140-160/天`、`15K-20K/月`、`15K-25K/月 · 13薪` | 可作为单一、周期明确的区间候选；13薪单列 |
| [北京师范大学人事处](https://hr.bnu.edu.cn/rczp/rczpxx/985gcry/985dytj/60524.htm) | 3 | 数值片段 `20-30万元`、`10-20万元` 在原文属于年薪；`3-5万元` 属于按实际工作时间调整的客座岗位月薪 | 前两项结合年薪上下文可结构化；第三项不能忽略调整条件 |
| [寻乌县官方岗位信息](https://www.xunwu.gov.cn/xwxxxgk/rsjycy/202606/c109ede3fa994645b0c5000e464a47b0.shtml) | 4 | 每小时 35—40 元、月度 4000—6000 元，以及试用／转正分阶段、底薪另加提成奖金两种情形 | 前两项可结构化；后两项复核，不截取第一个金额 |
| [高校公布的企业招聘 PDF](https://www.mmpt.edu.cn/__local/C/32/F5/B2244EE45E3D4C49D467013CE8B_86C58AC0_2BC45.pdf) | 2 | 4000—8000 元的底薪还附有提成和奖金；另有待遇面议 | 分别记为条件复杂／面议，不能当作确定总收入 |

人工适配分类：9 个候选可结构化、5 个缺周期上下文、4 个含额外条件需复核、
1 个面议。**这不是适配器测试通过率**：适配器尚未编写，也没有声称 19 个表达均可解析。
候选中的纯数字日薪仍需从字段元数据确认币种；“元”不能自动区分 CNY/TWD。

另在公开检索中发现小时计价、每周结算并存的招聘表达。结算周期与计价周期应分开，
“周结”不能改写成“周薪”。未成功读取正文的检索结果不计入上述 19 个已核对样本。

## 当前包的行为

对已安装 v0.2.25 做了九项只读核对：`月薪3-5万元`、`15K-25K/月·13薪`、
`15-25K`、`底薪5000+提成`、`面议` 五项均被保守拒绝；普通 `3-5万元`、
`15-25千元`、`20-25元`、`3万元以上` 得到既有预期结果。
这是有意限定的通用数值语法，**不计为五个缺陷**。不应为薪资场景放宽默认解析器，
否则普通数据中的 K、周期和加号可能被误解释，且原有诊断／汇总结构无法表示这些条件。

## 三种方案

1. **独立示例适配器（已选择）**：位于 docs，显式调用后才执行。先收集领域规则和
   复核经验；不加入 NAMESPACE，不改变原有六个函数或通用解析路径。
2. 新增薪资专用公开函数：领域语义和独立返回结构比较清晰，但会增加正式 API、
   文档与长期兼容承诺，留待示例成熟后再评估。
3. 给 parse_cn_range 增加薪资模式：调用表面简单，但返回值需要额外字段，容易与
   cn_summary/cn_subset 的现有结构约定冲突，不推荐首版采用。

## 首版采纳的范围

### 接受什么

只处理调用方已经选出的**薪资字段**，不扫描整篇招聘公告、不从多个金额中选一个。
完全匹配允许的“周期前缀＋金额表达＋周期后缀＋可选 N 薪”语法，前后周期必须一致。
月／年／日／小时保持原周期；缺少周期时仅允许使用调用方明确提供的字段上下文。

薪资字段中的 K/k 显式映射为 1000，之后复用 parse_cn_range 的金额、分组和边界
校验；不把 K/k 的解释加入普通数值函数。首版不支持 W/M 的推断，不合并数字之间
的任意空白，不丢弃未知尾文，也不把“约”或条件性金额静默改成精确区间。
明确的单值、闭区间及既有以上／以下等边界表达可复用原函数；保留包含标志，
不自行补零下界。0 或负数金额、异常端点、冲突周期和冲突单位进入复核，
不据此推断无薪／负薪身份。

### 返回什么

建议返回普通 list，包含 `data` 和 `review` 两张表；这是示例格式，不冒充现有解析结果：

* data：原始 index/raw、lower/upper、两端包含标志、period、
  advertised_payments（例如 13）、currency（只来自明确来源／调用方）、status。
* review：原始 index/raw、reason；保留重复输入，索引指向当前输入位置。
* status 区分 parsed、missing、needs_context、conditional、negotiated、invalid。
  除 parsed 外的金额字段置 NA，保留原文和明确的元数据供复核。面议不是零、也不是普通缺失。

不要对薪资表直接调用 cn_problems、cn_subset 或 cn_summary；这些函数继续用于未修改
的通用解析结果。示例自身的 review 显式保存领域复核原因。

例如，有明确月薪字段上下文时，`15-25K·13薪` 可表示 15000—25000、period=month、
advertised_payments=13；没有该上下文时标 needs_context，不猜月薪。`15K-25K/月 · 13薪`
本身含有月周期，不需要额外推断。N 薪只是原文声明，不证明每笔等额或保证发放。

### 不计算什么

不自动计算年薪、月薪折算、到手工资、奖金或提成，不把多阶段薪资压成区间，
不进行币种转换；不默认 12 薪，不将 13 薪再乘到已经写明的年薪上。
“底薪＋提成”、面议、试用／转正并列、按实际工作时间调整等情况统一保留复核信息。
示例本身也不承诺招聘信息真实或当前有效。

### 实现后的验证

先做来源样本人工预期及合成边界测试，分开报告；验证完整匹配、周期冲突、重复输入、
缺失和错误行号。对现有六个函数复跑 1832 项包断言和五平台 CI；已有 R/C 代码
应保持不变。检查适配器运行成本，但不重新启动通用解析算法的持续提速项目。
示例和中文／英文教程一起完成后，再判断是否值得成为正式包功能。

## English scope summary

This historical assessment preceded the example implementation; no package
release is involved. The user selected an
example adapter outside the six existing exports. Nineteen manually selected
expressions/fragments from five inspected pages yield nine straightforward
candidates, five needing period context, four conditional cases and one negotiated
case. These are design classifications, not measured parser accuracy.

The proposed adapter matches complete salary fields, retains explicit time bases,
records advertised installments separately and returns data/review tables. It
does not infer annual income, commissions, currency or missing pay periods.
The existing number/quantity/range parsers and diagnostic helpers stay unchanged.
