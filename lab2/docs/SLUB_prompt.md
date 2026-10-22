[PROMPT]

**任务**：
在现有 ucore 内存管理框架中实现一个简化的 SLUB 小对象内存分配模块，并接入现有内核。

**操作要求**：
- 只能在实验项目 `lab2/code` 下进行操作。
- 必须直接修改项目中的实际文件。
- 保留已有 PMM 和 Buddy System 实现。
- SLUB 应建立在现有页分配接口之上，不依赖某一种具体 PMM 算法的内部实现。
- 只修改 SLUB 实现和接入所需内容。
- 按照 git 规范保持修改范围清晰，允许用户自行检查和回退。

**输出要求**：
- 完成 SLUB 模块实现和必要接入。
- 使用工程中真实存在的类型、宏和接口。
- 保证项目能够正常编译运行。
- 实现阶段允许进行必要的基本自检和运行验证；完整专项测试由后续独立 Prompt 完成。


[RELY]

1. 现有物理页分配接口：`code/kern/mm/pmm.h`

    struct Page *alloc_pages(size_t n);
    void free_pages(struct Page *base, size_t n);
    size_t nr_free_pages(void);

2. 页面大小和地址对齐相关定义：`code/kern/mm/mmu.h`

包含：

    PGSIZE
    PGSHIFT

等相关定义。

3. 链表接口

链表节点：

    struct list_entry {
        struct list_entry *prev, *next;
    };

可用链表操作包括：

    list_init
    list_add
    list_add_before
    list_add_after
    list_del
    list_del_init
    list_empty
    list_next
    list_prev

其他所需的地址转换、Page 描述符和辅助接口，应直接读取当前工程中的真实定义后使用，不自行假设不存在的 API。


[GUARANTEE]

必须实现 SLUB 所需的主要接口：

    [slub_init]
    [slub_alloc]
    [slub_free]
    [其他实际需要暴露的接口]

允许增加必要的：
- cache 数据结构
- slab metadata
- static 辅助函数
- 模块内部状态和宏

不得修改现有公共 PMM 接口的函数签名。


[SPECIFICATION]

## SLUB 整体行为

**Post-Condition**:
- 在现有页分配器之上提供小于页面粒度的对象分配能力。
- 对小内存请求，在没有合适空闲 object 时，可以申请新的物理页并将其中可用区域划分为若干等大的 object。
- 一张物理页作为一个 slab，由对应 cache 管理。
- 每个 cache 管理固定大小的 object。
- 本模块主要负责小于一页的对象分配；对于当前 slab size class 无法容纳的请求，可以根据现有 PMM 接口采用合理处理方式，但不得破坏 SLUB 小对象管理语义。


## SLUB 初始化

**Post-Condition**:
- 各 size class 对应的 cache 被正确初始化。
- 初始时不必预先占用物理页。


## 对象分配

**Pre-Condition**:
- 请求大小合法。

**Post-Condition**:
- 请求被映射到能够容纳它的合适大小 object。
- 优先从已有 slab 的空闲 object 中分配。
- 若当前 cache 没有可用 object，则从底层 PMM 申请新的 page 并初始化为 slab。
- slab 所在页面保持页对齐；slab 内各 object 的起始地址满足正确的内存对齐要求。
- 空闲 object 可以利用自身空间维护 freelist，而被分配后的整个 object 空间可供调用者使用。


## 对象释放

**Pre-Condition**:
- `ptr` 为此前由 SLUB 成功分配的 object 起始地址。

**Post-Condition**:
- 根据 `ptr` 所在页面恢复其所属 slab 和 cache。
- object 被重新加入对应 slab 的空闲结构。
- 当 slab 中不存在已使用 object 时，将该 slab 从 cache 中移除，并把整张 page 归还底层 PMM。
- SLUB 不依赖底层 PMM 的具体分配算法。


## slab 与 cache 管理

**Post-Condition**:
- 一个 cache 可以管理多张 slab。
- 每张 slab 记录足以支持 object 分配、释放和整页回收的状态。
- slab metadata 与 object 区域不能重叠。
- object 区域满足正确的地址对齐要求。


## slub_check

**Post-Condition**:
- 保留可正常编译调用的测试入口。
- 完整专项测试不要求在本次实现中完成。