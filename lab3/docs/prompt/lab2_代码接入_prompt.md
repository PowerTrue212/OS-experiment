# Lab 2 代码接入 Lab 3：任务规格

以下规格根据本次接入要求整理。Lab 2 的原有提示词见 `lab2/docs/prompt/page_init_prompt.md` 和 `lab2/docs/lab2 实验报告.md` 中的 Best-Fit 部分。

[PROMPT]

在 Lab 3 框架中接入 Lab 2 的物理内存初始化和 Best-Fit 分配器，保留 Lab 3 原有的中断保护和分配器测试。修改范围限定在 Lab 3 的物理内存管理代码。

[RELY]

- Lab 2 的 `kern/mm/pmm.c`、`kern/mm/best_fit_pmm.c` 及其已有提示词。
- Lab 3 的 `struct Page`、`pmm_manager`、`PADDR`、设备树接口、地址布局和中断保护接口。
- Lab 3 已提供的 `basic_check()`、`best_fit_check()`。

[GUARANTEE]

- `lab3/code/kern/mm/pmm.c`：补充 `page_init()`，并选择 Best-Fit 管理器。
- `lab3/code/kern/mm/best_fit_pmm.c`：补充 Best-Fit 管理函数、内部状态和管理器注册。
- 保持 Lab 3 的内存分配和释放时中断保护；保留原有固定测试函数。

[SPECIFICATION]

- `page_init()`：先设置虚实地址偏移，读取设备树内存范围，校验范围和描述符空间；初始化 `Page` 数组并注册完整可用页，不能把内核或描述符占用的页面当作空闲页。使用 Lab 3 已定义的地址布局计算可管理上界。
- Best-Fit：选择足够大的最小空闲块，拆分剩余空间；释放时按地址登记并合并相邻空闲块，维护空闲页数量。
- 验证：在临时副本中编译并运行物理内存检查；记录 Lab 3 未完成的 Trap 函数对正式构建的影响，不把临时占位代码作为正式实现。
