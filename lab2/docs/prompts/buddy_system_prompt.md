[PROMPT]

**任务**：
在现有 ucore 物理内存管理框架中实现 Buddy System 物理页分配模块，并接入现有 `pmm_manager`。

**操作要求**：
- 只能在实验项目 lab2/code 下进行操作
- 必须直接修改项目中的实际文件。
- 保留已有代码和已有分配算法。
- 只修改 Buddy System 实现和接入所需的内容。
- 按照 `git` 的规范进行工作，保持修改范围清晰，使用户可以通过 Git 检查和回退本次修改；未经用户明确要求，不主动回退或覆盖已有修改。

**输出要求**：
- 完成 Buddy System 模块实现并接入内核。
- 使用工程中真实存在的类型、宏和接口。
- 保证项目能够正常编译和运行。
- 本 Prompt 主要负责 Buddy System 的实现；完整的专项测试将在后续测试 Prompt 中补充。


[RELY]

Buddy System 可以依赖现有物理内存管理框架。

主要相关内容：

1. **struct Page**：`code/kern/mm/memlayout.h`
```c
    struct Page {
        int ref;                        // page frame's reference counter
        uint64_t flags;                 // array of flags that describe the status of the page frame
        unsigned int property;          // the num of free block, used in first fit pm manager
        list_entry_t page_link;         // free list link
    };
```

2. **struct pmm_manager**：`code/kern/mm/pmm.h`
```c
    struct pmm_manager {
        const char *name;
        void (*init)(void);
        void (*init_memmap)(struct Page *base, size_t n);
        struct Page *(*alloc_pages)(size_t n);
        void (*free_pages)(struct Page *base, size_t n);
        size_t (*nr_free_pages)(void);
        void (*check)(void);
    };
```
3. **已有 PMM 实现与注册方式**

`code/kern/mm/default_pmm.c` 中通过以下形式提供物理内存管理器：
```c
    const struct pmm_manager default_pmm_manager = {
        .name = "default_pmm_manager",
        .init = default_init,
        .init_memmap = default_init_memmap,
        .alloc_pages = default_alloc_pages,
        .free_pages = default_free_pages,
        .nr_free_pages = default_nr_free_pages,
        .check = default_check,
    };
```
现有 `pmm.c` 通过当前 `pmm_manager` 统一调用物理内存管理接口。

4. **list**：`code/libs/list.h`

链表节点：
```c
    struct list_entry {
        struct list_entry *prev, *next;
    };
```
可用链表操作包括：
```c
    list_init
    list_add
    list_add_before
    list_add_after
    list_del
    list_del_init
    list_empty
    list_next
    list_prev
```
已有 `default_pmm.c` 和 `best_fit_pmm.c` 可以作为模块组织、Page 状态维护和 `pmm_manager` 接入方式的参考。


[GUARANTEE]

必须实现 Buddy System 对应的物理内存管理接口：

    void buddy_init(void);
    void buddy_init_memmap(struct Page *base, size_t n);
    struct Page *buddy_alloc_pages(size_t n);
    void buddy_free_pages(struct Page *base, size_t n);
    size_t buddy_nr_free_pages(void);
    void buddy_check(void);

并提供对应的 `pmm_manager` 实例。

具体函数是否需要声明为 `static`，以及头文件与管理器实例的组织方式，应根据工程现有 PMM 模块的实际组织方式确定。

允许增加必要的：
- static 辅助函数
- 模块内部状态
- 内部数据结构和宏

不得修改现有公共物理内存管理接口的函数签名。


[SPECIFICATION]

## Buddy System 整体行为

**Post-Condition**:
- 可用物理页被组织成大小为 2 的幂的 Buddy block。
- 能够完成 block 的分配、分裂、释放和伙伴合并。
- 对外保持现有物理内存管理接口语义。
- 对于大小为 `2^k` 页的合法 Buddy block，其起始物理页号必须满足 `2^k` 页对齐，使伙伴关系可以由物理页号的二进制关系唯一确定。


## buddy_init_memmap

**Pre-Condition**:
- `base` 指向连续空闲物理页的起始位置。
- `n > 0`。

**Post-Condition**:
- `[base, base+n)` 的所有页面都被纳入 Buddy System 管理。
- 这些页面被组织成一个或多个合法的 Buddy block。
- 不遗漏、不重复管理页面。
- 每个大小为 `2^k` 页的 block，其起始物理页号必须能够被 `2^k` 整除。
- 当整个初始空闲区不能直接构成单个合法 Buddy block 时，应划分为多个满足大小和物理页号对齐要求的合法 block。


## buddy_alloc_pages

**Pre-Condition**:
- `n > 0`。

**Post-Condition**:
- 成功时返回能够容纳至少 `n` 页的连续物理块。
- 当 `n` 不是 2 的幂时，应分配能够容纳 `n` 页的最小合法 Buddy block。
- 必要时能够从更大的 Buddy block 分裂得到所需 block。
- 分裂产生的所有 block 仍需满足对应大小的物理页号对齐要求。
- 无法满足请求时返回 `NULL`，且不破坏已有状态。
- 空闲页数量应减少实际被占用的 Buddy block 页数，而不是仅减少请求的 `n`。


## buddy_free_pages

**Pre-Condition**:
- `base` 对应此前成功分配的内存块。
- `n > 0`，并与此前的分配请求相匹配。

**Post-Condition**:
- 释放后的 block 重新变为空闲状态。
- 当原请求不是 2 的幂时，释放时必须采用与分配时一致的 Buddy block 大小。
- 空闲页数量应恢复实际被释放的 Buddy block 页数。
- 若其真正的伙伴 block 同样空闲，应进行合并。
- 合并后若新的 block 仍存在可合并伙伴，应继续向更大的 block 合并。
- 不能仅因为两个 block 在物理地址上相邻就进行合并。
- 真正的伙伴关系应建立在相同 block 大小、正确物理页号对齐和二进制伙伴关系之上，可以利用物理页号的二进制性质确定唯一 Buddy


## buddy_nr_free_pages

**Post-Condition**:
- 返回当前 Buddy System 中实际空闲的物理页总数。
- 返回值应与初始化、分配和释放过程中实际 Buddy block 的页数变化保持一致。


## buddy_check

**Post-Condition**:
- 保留符合 `pmm_manager` 接口要求并能够正常编译、调用的检查入口。
- 完整的 Buddy System 专项测试逻辑由后续独立的测试 Prompt 补充。
