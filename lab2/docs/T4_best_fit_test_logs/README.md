# T4 测试记录

2026-10-22，助手对小组分支 `lab2-t3-t4-2511440` 的当前源码执行测试。基准提交及源码哈希在 `source-audit.log` 中。测试完成后未再修改两个内核源码文件。

2026-10-24 整理小组报告时，仅将 `pmm.c` 的预留学号注释补为 `2511794`，函数体和分配逻辑没有变化。本目录原始测试日志及当时的源码哈希保持原样，不能将注释变化后的整文件哈希说成与原记录逐字相同。整合报告见 [Lab2 实验报告](../../lab2%20实验报告.md)。

## 结果与文件

- `build.log`：当前源码从头编译成功。
- `qemu.log`：未注入额外测试的内核输出，实际管理器为 Best-Fit，内置检查和 SLUB 检查成功。
- `regression-build.log`、`regression-qemu.log`：隔离副本的额外回归，所有断言通过，之后 SLUB 检查也成功。
- `grade.log`：项目课程评分 `20/20`，包括 Page Init 和 Best-Fit 两项，各 10 分。不能把该分数解释为 Buddy/SLUB 或整个 Lab2 的全部验收。
- `console-summary.log`：本次可见终端实际输出的摘要，由运行脚本直接产生。
- `terminal-history.txt`：截图时读取的真实终端历史，仅去掉屏幕行宽产生的行尾空格和末尾空白行。
- `source-audit.log`：两个固定测试函数及队友 `page_init()` 与基准版本一致的检查，以及被测源码 SHA256。
- `terminal-exit-status.txt`：测试脚本整体退出码为 0。
- `qemu-exit-status.txt`、`regression-exit-status.txt`：均为 124，表示自测完成后脚本按预定的 8 秒超时结束仍在空转的内核。
- `snapshot-path.txt`：本次 Linux 临时构建目录，后续可能被系统清理。复现不依赖该目录继续存在。

正式截图是上一级的 `T4_best_fit_test_result.png`，由 Windows 实际屏幕抓取，包含管理器名称、内置检查、额外回归和课程评分。`regression-window.png` 是同一窗口较大字号的回归部分截图。截图没有重绘或拼接。

`[2] Unmodified kernel` 指没有注入额外回归代码的当前仓库源码副本，不是修改前的原始版本。课程评分也在这份源码副本上运行。仅回归副本追加了 `best_fit_regression.c.txt`，并在其 `pmm_init()` 中临时调用；正式仓库内核没有额外回归入口。

## 复现

在 ReductWSL 中运行：

```bash
bash /mnt/d/OS/OS-experiment/lab2/docs/T4_best_fit_test_logs/run_t4_tests.sh
```

脚本设置当前机器的交叉工具链路径，复制当时的源码到新建的 `/tmp/ucore-t4-2511440.*` 目录，从头编译并运行。仓库跟踪的 `bin/`、`obj/` 不参与测试，也不会被覆盖。评分依赖 `bc`，本次已补装；QEMU 为 `/usr/local/bin/qemu-system-riscv64` 4.1.1。

如需在独立 Windows 终端中运行，可使用同目录 `run_visible.ps1`；`capture_terminal.ps1` 抓取名为 `T4 Best-Fit` 的实际终端窗口。重新执行会更新当前目录下的测试日志及退出状态。课程评分使用固定的 `/tmp/lab2_grade`，不要同时运行多份评分任务。

## 首轮记录

`attempt1-terminal-io/` 保留第一轮记录：编译成功，但可见终端中的 QEMU 未产生串口输出，脚本按缺少成功标记判定失败。之后给自动化 QEMU 明确设置了 `/dev/null` 标准输入，重新完整执行并通过。没有为解决此问题修改内核算法。

`wsl-stderr.log` 保存 WSL 的 localhost 代理提示；它与内核分配器测试无关。
