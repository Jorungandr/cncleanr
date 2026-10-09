# 本地 R 退出异常与批量稳定性检查

2026-10-09，Windows 11、R 4.6.1。检查日志位于
`outputs/validation-2026-10-08/cncleanr.Rcheck/`。

## 最小复现

| 独立进程 | 退出码 |
| --- | ---: |
| 基础 Rscript | 0 |
| 只加载 cncleanr 并解析 `3万` | 0 |
| 只加载本地 rlang 1.3.0 | -1073741819 |
| 只加载本地 cli 3.6.6 | -1073741819 |
| 只加载本地 testthat 3.3.2 | -1073741819 |
| 全部 testthat 断言（209 项通过） | -1073741819 |
| 只加载 otel、brio、magrittr 或 R6 | 0 |

Windows Application 事件记录崩溃模块 `ucrtbase.dll`、异常 `0xc0000005`。
事件中的模块位置不是根因证明，不能据此删除或替换系统 DLL。
不加载 cncleanr、不执行任何解析测试也能复现，说明 cncleanr 不是必要触发条件。
Rscript 与 Rterm 都会复现；清除 LANG/LC_ALL/LC_CTYPE 后仍复现。

从 CRAN 下载匹配 R 4.6 的 rlang 1.3.0 和 cli 3.6.6 二进制到独立库，
安装及 MD5 检查成功后仍复现同一退出码。没有覆盖用户原有库。
这排除了“仅原有安装文件损坏”这一解释，但未区分 R、依赖原生代码、系统运行库或外部注入问题。
额外尝试的 R 4.5 rlang 二进制无法加载，退出码 1，不是可用替代方案。
没有修改测试入口绕过退出，也没有将 1 ERROR 改称通过。

复跑最小进程检查（不下载、不安装、不修改包）：

```powershell
./docs/diagnose-r-exit.ps1
```

默认使用 `D:/R/R-4.6.1/bin/Rscript.exe` 和已下载的
`outputs/environment-diagnosis/library`；可用 `-Rscript`、`-Library` 指定其他已准备的环境。
该脚本输出每个子进程的退出码；不能用整个 PowerShell 脚本的退出码代替逐项结果。

## 不依赖 testthat 的压力检查

`batch-stability.R` 使用基础 R 的 `stopifnot`，在独立进程验证：

- 100000 项重复混合输入，三个解析器的值与全部异常索引一致。
- 20000 个不同的数值文本，与独立整数序列预期一致。
- 混合有效输入与超过 10000 字符的无效文本，异常只定位到对应行。

```powershell
Rscript --vanilla docs/batch-stability.R outputs/validation-2026-10-08/library
```

本地断言通过，进程退出码为 0。这是合成稳定性检查，不计入真实数据覆盖量，
也不是内存泄漏测量、速度基准或完整 CRAN 检查。
CI 清洗示例步骤也运行同一脚本。
提交 `06df855` 的[五平台检查](https://github.com/Jorungandr/cncleanr/actions/runs/37887435018)
已全部成功，每个平台的清洗示例及批量检查步骤均成功。

## 全新 R 安装对照

2026-10-09 经用户确认，在 `outputs/environment-diagnosis/fresh-R-4.6.1/`
安装官方 R 4.6.1，安装程序退出码 0。安装包 MD5
`7907f3a20ec8ec88cd0da279024b8e27` 与 CRAN 公布值一致。
禁用默认版本登记、文件关联和快捷方式；不覆盖 `D:/R/R-4.6.1`。
安装程序会创建该独立副本的卸载记录，诊断目录暂时保留，不自动删除。
官方校验入口：[安装包指纹](https://cran.r-project.org/bin/windows/base/md5sum.R-4.6.1.txt)。

使用新 R 和独立下载的 R 4.6 rlang 二进制，只保留诊断库与新 R 基础库，
仍出现 `-1073741819`。切换 C locale 或将进程 PATH 限为 Windows 系统目录也仍复现。
原安装与新安装 `bin/x64/R.dll` 的 SHA-256 一致：
`01a74425b34c3db9bfe0eda380c9ebcbe6dc664ccbf16d4f95a63218f30dff94`。
这进一步排除了“只需重新安装同版本 R 即可解决”的解释，尚未证明是具体哪个系统组件。

新 R 运行 `batch-stability.R` 全部通过，退出码 0。
整包检查使用独立 rlang/cli 库，但 testthat 及其他测试依赖仍来自原用户库，
不能将其称为全依赖隔离环境。日志保存在
`outputs/environment-diagnosis/fresh-check/cncleanr.Rcheck/`。
新 R 的整包检查仍是 `Status: 1 ERROR`：209 项断言通过后测试进程异常退出。
本轮关闭远程 incoming 检查、跳过 PDF 手册；依赖索引查询也出现网络访问诊断。
不能把本轮本地检查说成完整通过，远程五平台成功与本地退出问题应分别记录。
未修改系统 DLL、未更改原依赖库、未跳过或改写包测试来规避错误。
