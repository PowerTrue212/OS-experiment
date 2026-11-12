# 功能模块二：进程创建

[PROMPT]

阅读 `kern/process/proc.c`、`proc.h`、进程入口和中断返回代码，在 Lab 4 标记处实现内核线程创建与初始化，按分工填写学号 `2512075`。

[RELY]

沿用 `struct proc_struct`、`struct context`、`struct trapframe`、进程链表与哈希表，以及 `kmalloc`、内核栈分配、`get_pid`、`wakeup_proc`、`forkret` 和 `forkrets` 等接口。

[GUARANTEE]

完成 `alloc_proc`、`proc_init`、`kernel_thread`、`do_fork`、`copy_thread` 和 `copy_mm`，保留接口签名。

[SPECIFICATION]

- 完成进程控制块初始化、内核栈分配、`copy_mm`、`copy_thread`、`do_fork`、`kernel_thread` 和 `proc_init`。
- 正确设置父进程、PID、链表、初始上下文与 trapframe，并处理分配失败后的清理。
- 本实验先支持共享内核地址空间的内核线程，不把占位的 `copy_mm` 描述为已经支持用户进程地址空间复制。
- PCB 初始状态为 `PROC_UNINIT`，PID 尚未分配；创建成功返回新 PID，分配失败返回负错误码。
- `idleproc` 使用当前启动栈并成为 `current`；`initproc` 由 `kernel_thread` 创建，并进入进程表。
- 新线程第一次运行时，经 `forkret`、`forkrets` 和 `__trapret` 恢复预设现场；未支持的用户地址空间复制应返回错误。
- 使用课程提供的检查程序验证进程创建过程。
