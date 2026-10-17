# cncleanr 0.2.18

修复三个解析器接收异常数值转换结果的问题。自定义 `as.double()` 方法必须返回
与输入等长、无类别和维度的 double 向量，否则明确报错；SPSS 数值准备也复用
此校验。合法方法仅调用一次，警告正常传出。无新增依赖，无 C 修改。

All three parsers reject malformed numeric S3 conversion results. Methods must
return a plain, dimensionless double vector of the original length; numeric
SPSS preparation shares this check. Valid methods still run once, with warnings
preserved. No new dependencies or C changes. No CRAN submission.
