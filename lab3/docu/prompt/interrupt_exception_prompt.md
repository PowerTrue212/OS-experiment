# 中断与异常处理：任务规格

[PROMPT]

补全 `kern/trap/trap.c` 中的 `interrupt_handler()` 和 `exception_handler()`，处理时钟中断、非法指令和断点异常，并对其他类型提供提示或 Trap frame 输出。

[RELY]

- `struct trapframe` 中的 `cause` 和 `epc`。
- `clock_set_next_event()`、`ticks`、`TICK_NUM`、`print_ticks()` 和 `sbi_shutdown()`。
- `IRQ_S_TIMER`、`CAUSE_ILLEGAL_INSTRUCTION`、`CAUSE_BREAKPOINT` 和 `print_trapframe()`。
- 当前实验在 QEMU 的内核地址空间测试 2 字节和 4 字节指令。

[GUARANTEE]

```c
void interrupt_handler(struct trapframe *tf);
void exception_handler(struct trapframe *tf);
```

保留已有 `trap_dispatch()` 和 `trap()` 的接口；可增加模块内部使用的辅助函数和常量。

[SPECIFICATION]

## `interrupt_handler(tf)`

**Pre-Condition**：`tf` 指向已保存的 Trap frame，`cause` 表示中断。

**Post-Condition**：根据中断类型完成处理并返回。时钟中断设置下一次事件，每次增加一次 `ticks`；每 `TICK_NUM` 次输出统计，达到 `SHUTDOWN_AFTER` 次统计后关机。

**Case**：其他已列出的中断输出类型；无法识别的中断输出原因和 Trap frame。

## `exception_handler(tf)`

**Pre-Condition**：`tf` 指向已保存的 Trap frame，`cause` 表示异常。

**Post-Condition**：非法指令和断点异常输出发生位置，按当前指令的 2 或 4 字节长度更新 `epc`；其他异常输出 Trap frame。

**Requirements**：`epc` 的更新要与实际指令长度一致，时钟中断不能只计数而遗漏下一次事件。
