[PROMPT]
任务：读取当前 lab2/code/kern/mm/slub.c、slub.h，针对已实现的简化 SLUB 单独设计并补齐专项测试，在实际源文件中完善 slub_check()，不要重写分配器主体。此提示词用于本次整理后的测试规格，不是对既往生成对话的逐字复原。
保留现有测试和公共接口，只增补必要的 static 测试辅助函数。如发现算法错误，先指出具体失败场景及原因，不通过弱化断言、修改固定页分配测试等方式掩盖问题。

[RELY]
- slub_init()/slub_alloc(size_t)/slub_free(void*)/slub_check() 是现有接口。
- 页面大小为 PGSIZE；alloc_pages、free_pages、nr_free_pages 为通用 PMM 接口。不要读取某一 PMM 的私有状态。
- 阅读当前 slub_sizes、SLUB_ALIGN、SLUB_HEADER_SIZE、slub_cache 和 slub_slab 的真实定义。不要假定一页的全部 4096 字节都能放对象。
- 当前小对象走尺寸类和单页 slab，大对象有页头并申请连续多页；slab 首部保存 cache/page/freelist/inuse/capacity/nr_pages。
- 使用工程断言和 cprintf；测试缓冲也要考虑早期内核启动栈容量，不能随意放巨型局部数组。

[GUARANTEE]
保留并完善 void slub_check(void)，可新增静态测试辅助函数。slub_init/slub_alloc/slub_free 的公共签名及页分配接口不得修改。由 kern_init 在 pmm_init 和 slub_init 之后调用检查入口。

[SPECIFICATION]
## slub_check
Pre-Condition：物理页管理器与 SLUB 已初始化，分配器无并发使用者。
Post-Condition：全部有效测试对象释放；测试后 nr_free_pages 与开始前相同；各组断言通过后才输出对应成功标记。
1. 尺寸与边界：检查 0、1 字节、每个尺寸类边界及边界两侧的请求；0 返回 NULL，其余成功对象满足 16 字节对齐。对完整申请区间写入并读回不同模式，核对对象不重叠，不覆盖 slab 元数据。对齐和相邻边界可发现错误舍入及越界。
2. freelist 与扩展：申请超过单张 slab 容量的同尺寸对象，确认扩展到新页；释放部分对象后验证复用。分别释放各 slab 的最后一个对象，确认物理页可独立归还。不能只验证分配成功而不检查页数恢复。
3. cache 隔离：不同尺寸类同时存活，交叉写入、读取、释放；用非首个对象地址释放，检查通过指针找回 slab/cache 的逻辑。
4. 大对象：申请超过最大尺寸类、超过两页的连续对象，考虑页头占用，写满申请长度并读回，核对与其他对象不重叠，释放后页数恢复。
5. PMM 共存：SLUB 对象与直接 alloc_pages(1) 的页面同时存活，写入不同模式，确认地址区间和内容不互相影响；分别归还，检查计数。
6. 混合与乱序释放：跨多个尺寸、多个 slab 申请，乱序释放后仍能正确读取存活对象，最后全部归还。该过程用于发现错误链表迁移、对象复用及泄漏。
Requirements：失败返回不可当作通过；测试结束不能留下分配；不构造违反当前合法指针约定的任意释放然后声称具备生产级指针检测。真实编译并运行后记录版本、输出及失败原因，不编造截图或通过结论。
