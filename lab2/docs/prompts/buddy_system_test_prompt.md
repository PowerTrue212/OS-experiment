[PROMPT]

**任务**：
针对项目中已经实现的 Buddy System 物理页分配模块设计并实现专项测试。

**操作要求**：
- 必须读取当前项目中的真实 Buddy System 实现。
- 主要新增或完善测试，不重写 Buddy System 主体实现。
- 若测试发现实现错误，先明确指出失败场景和原因，不直接大规模重构算法。
- 必须直接修改项目中的实际测试代码。
- 保留已有测试。

**输出要求**：
- 测试能够随内核编译和运行。
- 覆盖 Buddy System 的核心行为和边界情况。
- 测试结束后恢复测试前的可用内存状态。
- 给出测试结果，并指出是否发现实现缺陷。

[RELY]

当前工程已经存在：

    buddy_pmm_manager
    buddy_init
    buddy_init_memmap
    buddy_alloc_pages
    buddy_free_pages
    buddy_nr_free_pages
    buddy_check

测试前请读取当前真实实现以及 `struct Page`、`struct pmm_manager` 和现有 PMM 测试代码。

[GUARANTEE]

主要完善：

    static void buddy_check(void);

可以根据需要增加本模块内部的 static 测试辅助函数。

不得改变 Buddy System 的公共接口。

[SPECIFICATION]

## Buddy System 测试

测试至少覆盖：

- 1、2、4 等 2 的幂页数分配；
- 3、5 等非 2 的幂请求，并验证实际占用块大小正确；
- 大块向小块的多级分裂；
- 真正伙伴块释放后的合并；
- 连续多级伙伴合并；
- 相邻但不是伙伴的块不能错误合并；
- 内存不足时分配失败且状态不被破坏；
- 不同分配之间不存在重叠；
- `nr_free_pages()` 与实际分配/释放的 Buddy block 大小一致；
- 测试结束后的空闲页总数与测试开始前一致。

对与物理页号对齐相关的行为，应验证大小为 `2^k` 页的合法 Buddy block 起始物理页号满足相应对齐关系。

Pre-Condition：Buddy 已实现并通过公共页分配接口接入；检查时只有本测试使用隔离 arena。
Post-Condition：每种请求的返回区间和计数符合伙伴块的实际大小；失败申请不改变原状态；测试区和原空闲结构完整恢复。
测试有效性：核对 3/5 页请求的真实占用可以发现取整计数错误；核对相邻非伙伴块可以发现按邻接错误合并；检查物理页号对齐和所有返回范围不重叠可以发现错误拆分；末尾比较总数可以发现页面泄漏。
