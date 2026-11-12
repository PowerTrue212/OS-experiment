# 功能模块三：进程调度

[PROMPT]

阅读进程控制块与调度接口，实现 `cpu_idle`、`schedule`、`proc_run` 和 `switch_to`，按分工填写学号 `2511794`。

[RELY]

使用 `proc_list`、`current`、`idleproc`、`PROC_RUNNABLE`、`need_resched` 和 `runs`；`struct context` 包含 `ra`、`sp` 和 `s0` 至 `s11`。使用 `local_intr_save`、`local_intr_restore`、`SATP_MODE_SV39` 和 `flush_tlb`。

[GUARANTEE]

完成 `cpu_idle`、`schedule`、`proc_run` 和 `switch_to`，保持现有接口。`cpu_idle` 放在 `kern/process/proc.c`，调度选择放在 `kern/schedule/sched.c`，寄存器切换放在 `kern/process/switch.S`。

[SPECIFICATION]

- 遍历进程链表寻找可运行进程，没有可运行进程时回退到 idle 进程。
- 在本地中断保护下切换 `current`，按已有 Sv39 页表接口切换地址空间并刷新 TLB。
- 汇编部分保存和恢复 `struct context` 中的 `ra`、`sp`、`s0` 至 `s11`，使执行流能够恢复。
- `cpu_idle` 仅在需要重新调度时调用 `schedule`；切换到当前线程自身时无需执行上下文切换。
- 使用课程提供的检查程序验证线程创建、轮转和上下文切换；报告如实记录运行结果。
