# 功能模块一：虚拟页管理

[PROMPT]

阅读 `kern/mm/pmm.c`、`pmm.h` 和 `mmu.h`，在 Lab 4 标记处实现 `page_insert` 与 `page_remove`，保留标记并按分工填写学号 `2511440`。

[RELY]

`get_pte` 可按虚拟地址查找页表项，并在 `create` 为真时分配缺失的中间页表。使用已有的 `pte_create`、`pte2page`、引用计数和页面分配接口，以及 `tlb_invalidate`。

[GUARANTEE]

实现接口 `int page_insert(pde_t *, struct Page *, uintptr_t, uint32_t)` 和 `void page_remove(pde_t *, uintptr_t)`，不修改课程提供的测试函数。

[SPECIFICATION]

- 输入页目录、目标页、虚拟地址和权限；成功后页表指向指定页，返回 0。

- 利用 `get_pte` 查找或创建页表项，根据 Sv39 页表项格式写入物理页号和权限。
- 处理新建映射、替换不同物理页、对同一物理页更新权限以及删除不存在的映射，正确维护引用计数。
- 引用数归零时释放物理页，页表项变化后刷新 TLB；分配页表失败时返回错误并清理本次新增的页表页。
- 上级页表项已经是大页叶子项时，不把它当成下一级页表使用；不在本任务中拆分大页。
- 删除没有映射的地址应直接返回；用原有测试检查结果，并说明测试范围。
