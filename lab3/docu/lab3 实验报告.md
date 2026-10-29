# 实验报告（初稿）

## 实验基本信息

| 项目 | 内容 |
|------|------|
| 实验名称 | Lab 3：断，都可以断（中断与异常处理） |
| 小组成员 | 2512075-詹力臻、2511440-张博翔、2511794-宋昕睿 |
| 整理日期 | 2026-10-29 |

### 小组分工

| 成员 | 负责的练习/模块 |
|------|----------------|
| 2512075-詹力臻 | 功能模块一：Trap 上下文恢复与 Trap 入口 |
| 2511440-张博翔 | Lab 2 代码接入；功能模块二：中断与异常处理 |
| 2511794-宋昕睿 | 整体调试、测试材料与报告整合 |

## 一、实验目的

1. 理解 RISC-V 中断、异常和 Trap 的关系，了解主要控制寄存器的作用。
2. 建立 Trap 入口、现场保存、处理、恢复和返回的完整流程。
3. 实现时钟中断、断点异常和非法指令异常处理，并通过运行和测试验证。
4. 在 Lab 2 物理内存管理的基础上，理解内存操作与中断保护的关系。

## 二、实验环境

- 系统环境：Windows 下的 WSL（ReductWSL）。
- 交叉工具链：SiFive RISC-V GCC/GDB 工具链。
- 模拟器和固件：QEMU 4.1.1、OpenSBI v0.4。
- 源码目录：`lab3/code`；运行及评分使用该目录的临时副本。

| 成员 | AI 编程工具 | 底层模型 | 备注 |
|------|------------|---------|------|
| 2512075-詹力臻 | Codex | GPT-6 sol | 模块一实现与验证 |
| 2511440-张博翔 | Codex | GPT-6.1 Terra | 模块二实现与验证 |
| 2511794-宋昕睿 | DeepSeek Harness、Codex | DeepSeek v4.1 flash、GPT-5.6 Terra | 调试与报告整合 |

## 三、实验整体逻辑分析

### 3.1 本章节的逻辑主线

Lab 3 要解决的是：CPU 正在执行程序时，如果发生中断或异常，内核如何接管处理，处理完成后又如何回到原来的执行位置。Lab 2 提供了物理内存管理基础，本实验在此之上建立 Trap 处理流程。

RISC-V 将中断和异常统称为 Trap。时钟中断来自当前指令之外；断点、非法指令等异常由当前执行的指令触发。发生 Trap 时，硬件先记录原因和返回位置，并跳转到 `stvec` 指定的入口；其余通用寄存器由软件保存。

### 3.2 功能的逐步实现

1. **接入物理内存管理。** 补充 Lab 2 的 `page_init()` 和 Best-Fit，让内核能初始化可用物理页；保留 Lab 3 新增的中断保护。
2. **建立 Trap 入口和恢复流程。** 利用已有 `SAVE_ALL` 保存现场，将 Trap frame 交给 C 语言处理函数，再通过 `RESTORE_ALL` 和 `sret` 返回。
3. **按类型处理中断和异常。** `trap_dispatch()` 根据 `cause` 分发；时钟中断安排下一次事件，断点和非法指令异常调整返回位置。
4. **编译与验证。** 先检查现场恢复及异常返回，再检查时钟能否持续触发，最后观察正常运行和关机结果。

核心流程如下：

```text
Trap 发生 → 硬件记录状态并跳转 stvec → __alltraps
          → SAVE_ALL 保存现场 → trap() / trap_dispatch()
          → 中断或异常处理 → RESTORE_ALL 恢复现场 → sret
```

## 四、实验内容与实现

### Lab 2 代码接入

**负责人：** 2511440-张博翔

#### 功能说明

`pmm.c` 中的 `page_init()` 从设备树读取物理内存基址和大小，设置虚实地址偏移及物理页号上界，在内核镜像之后建立 `Page` 描述符数组，再把排除内核和描述符占用后的完整页面交给分配器。接入时按照 Lab 3 已有的 `KERNTOP` 和 `PHYSICAL_MEMORY_OFFSET` 计算物理内存上界，并检查设备树范围和描述符空间。

`best_fit_pmm.c` 接入 Best-Fit 管理函数和 `best_fit_pmm_manager`，`init_pmm_manager()` 选择该管理器。申请时选择足够大的最小块；释放时按地址插入并合并相邻空闲块。Lab 3 原有的 `local_intr_save()`、`local_intr_restore()` 和分配器测试函数保持不变。

#### 验证与接入问题

首次接入时，Lab 3 的两个 Trap 处理函数尚未实现，完整源码还不能编译。为单独验证物理内存部分，在临时副本中使用占位处理函数，并在 `pmm_init()` 后结束运行。64、128、256 MiB 三种 QEMU 内存配置均通过 Best-Fit 自检；额外申请、释放三页后，分配地址处于可管理范围，空闲页数也恢复。256 MiB 配置被限制到内核当前支持的 `0x87ffffff` 上界。

接入规格见 [Lab 2 代码接入规格](prompt/lab2_代码接入_prompt.md)。两个 Trap 模块完成后，又进行了完整编译与测试，结果见第五部分。

### 功能模块一：Trap 上下文恢复与 Trap 入口功能

**负责人：** 2512075-詹力臻。

#### 模块功能描述

需要补充的汇编功能位于 `kern/trap/trapentry.S`：

```text
RESTORE_ALL：从 Trap frame 恢复处理器状态
__alltraps：保存现场并调用 trap(struct trapframe *tf)
```

Trap frame 按 36 个 `uintptr_t` 槽位组织，在 RV64 中占 288 字节：前 32 个槽位对应通用寄存器，后 4 个依次保存 `sstatus`、`sepc`、`stval` 和 `scause`。已有的 `SAVE_ALL` 将现场保存到栈上，`sp` 指向 Trap frame；其中进入前的 `sp` 通过 `sscratch` 保存到对应槽位。

`__alltraps` 使用 `mv a0, sp` 将 Trap frame 地址作为第一个参数，再调用 `trap()`。C 处理函数返回后进入 `__trapret`，由 `RESTORE_ALL` 恢复状态并执行 `sret`。恢复时先写回 `sstatus` 和 `sepc`，再恢复通用寄存器，最后恢复原来的 `sp`：其他读取仍需以当前 `sp` 指向的 Trap frame 为基址。

#### 提示词与规格（整理版）

独立文件：[trap_entry_prompt.md](prompt/trap_entry_prompt.md)。

````markdown
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
````

#### 实现与验证

本轮在已有 `SAVE_ALL` 基础上补全入口和恢复代码，没有修改 `SAVE_ALL`、`struct trapframe` 或 `trap()` 的签名。仓库测试通过断点触发 Trap，检查返回后寄存器值是否保持，并检查断点后的执行流；该项结果为 35/35。

### 功能模块二：中断与异常处理功能

**负责人及本轮代码实现：** 2511440-张博翔。

#### 模块功能描述

需要实现的接口位于 `kern/trap/trap.c`：

```c
void interrupt_handler(struct trapframe *tf);
void exception_handler(struct trapframe *tf);
```

`trap_dispatch()` 通过 `tf->cause` 的最高位判断中断或异常。`interrupt_handler()` 取出原因编号并分支处理：S 模式时钟中断调用 `clock_set_next_event()` 设置下一次事件，然后让 `ticks` 增加一次。每达到 `TICK_NUM` 的整数倍调用 `print_ticks()`；累计输出达到 `SHUTDOWN_AFTER` 次时调用 `sbi_shutdown()`。其他已列出的类型输出提示，未知中断输出 Trap frame。

`exception_handler()` 处理非法指令和断点异常，先输出发生位置，再检查指令首半字的低两位：低两位为 `11` 时按 4 字节处理，其他情况按 2 字节处理，并相应更新 `tf->epc`。本实验的异常测试使用内核地址空间中可读取的 2 字节和 4 字节指令；其他未单独处理的异常使用 `print_trapframe(tf)` 输出信息。

当前框架和练习文字没有给出 `SHUTDOWN_AFTER` 的具体数值，本次设为 10：每 100 次中断输出一次，累计输出 10 次后关机。如课程另有明确数值，应按课程要求调整。

#### 提示词与规格（整理版）

独立文件：[interrupt_exception_prompt.md](prompt/interrupt_exception_prompt.md)。

````markdown
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
````

#### 实现与验证

非法指令测试检查异常发生后是否继续执行，并检查其他类型的处理与兜底输出，结果为 25/25。时钟测试检查是否持续设置下一次事件，直到至少发生 200 次时钟中断，结果为 40/40。另在临时副本中分别触发 4 字节断点和 2 字节非法指令，两次异常后均执行到后续测试输出。

## 五、测试与验证

测试使用 `lab3/temp` 内的源码副本，运行仓库的 `make grade`；评分过程的临时目录也放在 `lab3/temp`。测试结果：

```text
trap entry, register restore, and breakpoint EPC: PASS (35/35)
illegal instruction EPC advance and return: PASS (25/25)
re-armed supervisor timer and repeated trap return: PASS (40/40)
Total Score: 100/100
```

在另一份未注入评分测试的源码副本中运行 `make qemu`，Best-Fit 自检通过，时钟统计输出 10 次 `100 ticks` 后正常关机。异常指令长度检查也在临时副本中进行，测试副本和脚本在验证后已清理。

`make qemu` 和 `make grade` 的终端截图由调试与报告负责人补充。

## 六、实验总结与收获

### 对操作系统的理解

1. **中断与异常。** 中断通常由时钟或外设等事件触发；异常与当前执行的指令有关。二者都需要内核接管，但原因和后续处理方式不同。
2. **硬件记录与软件保存。** 硬件设置 `sepc`、`scause` 等状态并跳转入口；通用寄存器需要入口汇编保存到 Trap frame，处理完成后再恢复。
3. **时钟与调度。** 周期性时钟中断为操作系统获取控制权提供机会；本实验只统计中断次数，尚未实现时间片轮转或进程调度。
4. **临界区保护。** Lab 3 的物理内存分配和释放接口通过保存、关闭并恢复本地中断状态，避免相关操作被本地中断打断；这不等同于解决多核并发访问。

本实验还没有实现完整的用户态栈切换、安全读取用户指令、多核同步和进程调度，这些内容需要结合后续实验继续学习。

### AI 协作开发

实现前需要明确 Trap frame 的实际布局、允许修改的位置和各函数接口；测试后还要对照运行结果检查寄存器恢复、返回位置和时钟重设。提示词与规格在本报告中以整理版展示，不能替代对代码和测试结果的复核。
