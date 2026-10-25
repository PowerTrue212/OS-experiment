[PROMPT]

**任务**：
针对 `lab2/code` 中已经实现并接入内核的简化 SLUB 分配器设计并实现一组独立的专项测试，用于验证其对象分配、释放、slab 扩展与回收、大对象处理以及与底层 PMM 的交互是否正确。

当前 SLUB 已经能够通过基本 `slub_check()`，本次任务需要在此基础上设计更完整的测试，而不是重新实现 SLUB。

**操作要求**：
- 只能在实验项目 `lab2/code` 下进行操作。
- 必须先阅读当前真实的 `kern/mm/slub.c`、相关头文件和调用位置，理解实际接口、size class、slab 布局和大对象处理方式。
- 主要新增或完善测试逻辑，不重写 SLUB 主体实现。
- 不修改 Buddy System、First-Fit、Best-Fit 等 PMM 实现。
- 如果测试失败，首先判断问题来自测试代码还是 SLUB 实现，并明确说明失败场景和原因。
- 未确认 SLUB 主体存在缺陷前，不得对其进行大规模修改。
- 按照 git 规范保持修改范围清晰，允许用户自行检查和回退。

**输出要求**：
- 完成 SLUB 专项测试并直接修改实际项目文件。
- 保证项目能够正常编译和在 QEMU 中运行。
- 明确报告每类测试覆盖的行为以及最终结果。
- 测试结束后必须恢复测试前的内存状态，不得因为测试永久占用物理页。


[RELY]

当前工程中已经存在：

- `kern/mm/slub.c`
- `slub_init`
- `slub_alloc`
- `slub_free`
- `slub_check`

当前实现具有以下基本语义：

- SLUB 建立在现有 PMM 页分配接口之上。
- 一张 slab 使用一张物理页。
- 同一 slab 中的 object 大小固定。
- 空闲 object 利用自身空间组成 freelist。
- 一个 cache 可以管理多张 slab。
- 当一张 slab 中所有 object 都被释放后，该 slab 对应的整张物理页会归还底层 PMM。
- 较大的内存请求通过现有页分配接口处理。
- SLUB 不依赖 Buddy System 的内部实现。

底层物理页接口包括：

    struct Page *alloc_pages(size_t n);
    void free_pages(struct Page *base, size_t n);
    size_t nr_free_pages(void);

页面大小和地址相关定义以当前工程中的真实 `PGSIZE`、`PGSHIFT` 及相关宏为准。

测试前必须读取当前 `slub.c` 的真实实现，不要自行假设：
- size class 的具体取值；
- slab header 大小；
- object 对齐方式；
- 大对象阈值；
- 大对象 metadata 的具体布局。


[GUARANTEE]

主要完善当前 SLUB 的专项测试入口：

    slub_check

允许根据测试需要增加：
- static 测试辅助函数；
- 临时测试数组；
- 断言；
- 必要的调试输出。

不得改变：
- `slub_alloc` 和 `slub_free` 的公共接口；
- PMM 的公共接口；
- Buddy System 主体实现。

如果发现 SLUB 实现确有缺陷，应先给出能够稳定复现该缺陷的测试，再进行最小范围修复。


[SPECIFICATION]

## 测试整体要求

**Pre-Condition**:
- PMM 已完成初始化。
- SLUB 已完成初始化。
- 基本的页分配与释放功能可正常工作。

**Post-Condition**:
- 所有测试均完成后，`nr_free_pages()` 应恢复到测试开始前的值。
- 测试期间产生的所有 SLUB 对象和底层物理页必须被正确释放。
- 不同有效分配之间不得发生内存重叠。
- 测试不得破坏后续内核运行状态。


## 不同大小对象分配

验证多个不同大小的小对象请求。

测试应覆盖：
- 很小的对象；
- 位于某个 size class 边界附近的对象；
- 跨越不同 size class 的对象；
- 接近 SLUB 小对象上限的对象。

需要验证：
- 每次分配均返回有效地址；
- 返回地址满足当前实现规定的对齐要求；
- 不同同时存活的对象空间不发生重叠；
- 对象能够正常写入和读取。


## 同一 cache 的连续分配

对属于同一 size class 的请求连续进行多次分配。

需要验证：
- 多个对象可以从同一 slab 中正常取得；
- 返回的 object 地址不同；
- 每个 object 的数据互不干扰；
- freelist 状态不会导致重复分配仍在使用的 object。


## freelist 释放与复用

分配多个同一大小 object，释放其中部分对象，再进行新的同尺寸分配。

需要验证：
- 被释放 object 能重新进入空闲结构；
- 后续分配可以合理复用空闲 object；
- 尚未释放的 object 不得被重复返回；
- 释放和再次分配不会破坏其他对象中的数据。


## 多 slab 扩展

对同一个 cache 连续申请足够多的 object，使单个 slab 无法容纳全部对象。

需要验证：
- 当已有 slab 没有空闲 object 时，会从底层 PMM 获取新的 page 并建立新的 slab；
- 多张 slab 可以同时存在并正常提供 object；
- 所有返回 object 互不重叠；
- 底层空闲物理页数量出现符合 slab 扩展行为的变化。


## slab 整页回收

创建至少一张实际使用中的 slab，并最终释放其中全部 object。

需要验证：
- slab 中仍存在已使用 object 时，不能提前归还整张 page；
- 最后一个 object 被释放后，空 slab 可以从 cache 中移除；
- 对应 page 被归还给底层 PMM；
- `nr_free_pages()` 能反映整页归还。


## 多张 slab 的独立回收

构造同一 cache 下至少两张 slab。

需要验证：
- 清空其中一张 slab 时，只回收该 slab；
- 另一张仍含有效 object 的 slab 继续正常工作；
- 不能因为同属一个 cache 而错误释放仍在使用的 page。


## 不同 cache 之间的隔离

同时申请属于不同 size class 的对象。

需要验证：
- 不同 cache 的 slab 和 freelist 状态彼此独立；
- 释放一个 cache 中的 object 不影响另一个 cache 中仍然有效的 object；
- 不同大小对象中的数据互不破坏。


## 地址恢复与释放

针对小对象释放路径进行验证。

需要验证：
- `slub_free(ptr)` 能够由合法 object 指针恢复其所属 slab；
- 能够进一步识别正确的 cache；
- object 被归还到正确的 freelist；
- page 内存在多个 object 时，释放其中一个不会误回收整张 slab。


## 大对象请求

根据当前实现实际定义的大对象阈值构造超过小对象管理范围的请求。

需要验证：
- 大对象能够通过底层页分配机制正确获得连续内存；
- 分配结果能够正常读写；
- 大对象释放后，其占用的底层物理页能够恢复；
- 大对象路径不会破坏已有小对象 cache/slab 状态；
- 不要在测试中硬编码 Buddy System 的内部页数取整规则，应以当前 SLUB 和 PMM 的真实接口语义为准。


## 混合分配与释放

混合执行：
- 不同大小的小对象分配；
- 多 slab 分配；
- 大对象分配；
- 非顺序释放。

需要验证：
- 所有存活对象的数据保持正确；
- 分配区间互不重叠；
- 中间释放不会破坏其他对象；
- 全部释放后物理页总数恢复。


## 内存状态恢复

测试开始时记录：

    size_t free_before = nr_free_pages();

完成所有测试并释放所有对象后验证：

    nr_free_pages() == free_before

若不相等，应定位仍被占用的 slab、大对象或测试自身遗漏的释放，而不是直接修改 PMM。


## 测试结果

测试全部通过时应输出明确标志，例如：

    slub extended tests succeeded!

如果测试失败：
- 输出或保留能够定位失败类别的信息；
- 判断属于测试预期错误、测试资源清理错误还是 SLUB 实现缺陷；
- 修复后重新进行完整编译和 QEMU 验证。