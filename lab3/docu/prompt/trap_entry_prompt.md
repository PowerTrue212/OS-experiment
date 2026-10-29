# Trap 入口与上下文恢复：任务规格

[PROMPT]

补全 `kern/trap/trapentry.S` 中的 `RESTORE_ALL` 和 `__alltraps`，使 Trap 发生后能够保存现场、调用 C 处理函数、恢复现场并返回。保留已有的 `SAVE_ALL` 和 Trap frame 结构。

[RELY]

- `SAVE_ALL` 已按 `struct trapframe` 的顺序将通用寄存器、`sstatus`、`sepc`、`stval` 和 `scause` 保存在栈上。
- `sp` 指向当前 Trap frame；`trap(struct trapframe *tf)` 接收 Trap frame 的地址。
- RISC-V 调用约定使用 `a0` 传递第一个参数；`sret` 根据 `sepc` 和 `sstatus` 返回。

[GUARANTEE]

- 补全 `RESTORE_ALL`，恢复返回所需的寄存器和状态。
- 补全 `__alltraps`，保存现场后将 Trap frame 传给 `trap()`，处理结束后进入 `__trapret`。
- 不改 `SAVE_ALL`、`struct trapframe` 或 `trap()` 的函数签名。

[SPECIFICATION]

## `__alltraps`

**Pre-Condition**：处理器已跳转到 Trap 入口，当前栈可供保存现场。

**Post-Condition**：现场形成 Trap frame，`trap()` 收到其地址；处理函数返回后，继续执行恢复和返回流程。

## `RESTORE_ALL`

**Pre-Condition**：`sp` 指向与 `SAVE_ALL` 对应的 Trap frame，处理函数可能已经调整其中的返回地址。

**Post-Condition**：恢复 `sstatus`、`sepc` 和通用寄存器，最终由 `sret` 返回。

**Requirements**：恢复偏移与保存布局一致；先完成以当前 `sp` 为基址的其他读取，最后恢复原来的 `sp`。
