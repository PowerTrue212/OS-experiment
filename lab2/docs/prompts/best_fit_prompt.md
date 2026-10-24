[PROMPT]

我正在完成 riscv64-ucore Lab2 的“实现 Best-Fit 连续物理内存分配算法”任务。请先阅读项目中的实际代码，再直接修改文件，不能只在回答中给出代码。

源码修改范围只有两个文件：

1. `kern/mm/best_fit_pmm.c`：在标有 `lab2` 和 `YOUR CODE` 的位置实现完整的 Best-Fit 管理模块。实验骨架只提供 `basic_check()` 和 `best_fit_check()`，内部状态、五个管理函数和 `best_fit_pmm_manager` 注册结构需要自行补齐。
2. `kern/mm/pmm.c`：在 `init_pmm_manager()` 中将默认管理器切换为 `best_fit_pmm_manager`，使内核运行时实际使用并检查 Best-Fit。

参考 `kern/mm/default_pmm.c` 的 First-Fit 实现以及 `pmm.h` 的接口约定，沿用项目现有的页描述符、双向链表和断言工具。实验代码标记使用 `//lab2 function2-2 2511440`。不要修改 `basic_check()`、`best_fit_check()` 的任何内容，也不要修改其他同学负责的物理内存探测、Buddy、SLUB 或评分脚本。

实现采用按地址排序的空闲块链表。Best-Fit 的选择规则是：在所有长度不小于申请页数的空闲块中，找出长度最小的块；找到恰好满足需求的块可以提前结束遍历。请把地址有序插入和前后邻块合并写成一个公共辅助函数，让初始化登记和释放页面共用。

[RELY]

以仓库中的实际声明为准，重点阅读以下文件：

- `kern/mm/pmm.h`：物理内存管理器接口和公共分配、释放接口。
- `kern/mm/memlayout.h`：`struct Page`、状态位和 `free_area_t`。
- `libs/list.h`：双向链表操作。
- `kern/mm/default_pmm.c`：完整的 First-Fit 参考实现。
- `kern/mm/best_fit_pmm.c`：待完成骨架以及两个不可修改的测试函数。
- `kern/mm/pmm.c`：当前管理器选择方式及 `page_init()` 对管理器的调用方式。

`pmm_manager` 的接口为：

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

框架中的 `alloc_pages()`、`free_pages()` 和 `nr_free_pages()` 会转发到当前 `pmm_manager`。因此，只实现文件而不切换管理器，不能完成这项任务。

页描述符包含以下成员：

```c
struct Page {
    int ref;
    uint64_t flags;
    unsigned int property;
    list_entry_t page_link;
};

typedef struct {
    list_entry_t free_list;
    unsigned int nr_free;
} free_area_t;
```

每个 `Page` 描述一个物理页。链表中只挂各个空闲块头页的 `page_link`，不是把块内所有页面逐个挂入链表。头页的 `property` 表示这个块包含多少个连续页，`PG_property` 表示该页是空闲块头页。

使用项目已有的 `PageReserved()`、`PageProperty()`、置位和清位宏、`set_page_ref()`、`le2page()`，不要重复定义它们。注意 `list_add(head, elm)` 插在 `head` 后面，`list_add_before(head, elm)` 插在 `head` 前面；删除节点后可用 `list_del_init()` 使其自环。

测试会直接保存、替换和恢复空闲链表及计数。实现必须提供以下内部状态；骨架若没有定义，就自行新增，若已有则保留且不要重复定义：

```c
static free_area_t free_area;
#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)
```

这两个宏必须仍可作左值使用，不能改为只读函数。物理页描述符数组的有效范围根据实际框架确定，本项目为 `[pages, pages + (npage - nbase))`。

[GUARANTEE]
必须实现并注册以下管理接口；辅助函数与内部状态按实际需求增加：
```c
static void best_fit_init(void);
static void best_fit_init_memmap(struct Page *base, size_t n);
static struct Page *best_fit_alloc_pages(size_t n);
static void best_fit_free_pages(struct Page *base, size_t n);
static size_t best_fit_nr_free_pages(void);
extern const struct pmm_manager best_fit_pmm_manager;
```
保留框架 basic_check()、best_fit_check() 并将后者用于管理器的 check 回调。


请保证以下约束：

1. `basic_check()` 和 `best_fit_check()` 逐字保留；不要删断言、改预期结果或通过改测试让实现通过。
2. 只修改上述两个源码文件。不要改动 `page_init()`，不要改 Buddy、SLUB 或评分器。
3. `free_list` 始终按空闲块起始地址升序排列。每个空闲块内部的物理页连续，各块之间不重叠；不同空闲块之间可以隔着已经分配的页面。
4. 只在空闲块头页设置 `PG_property` 和有效的块长度；块内其他页的 `PG_property` 清零，`property` 为 0。被分配的页面不能继续带有空闲块头标记。
5. `nr_free` 始终等于链表中所有空闲块的 `property` 之和。两个物理相邻的空闲块要及时合并；合并只改变表示方式，不重复增减空闲页计数。
6. 分配失败返回 `NULL`，空闲链表、页状态和计数均保持不变。不能因为空闲页总数足够，就忽略是否存在足够大的连续空闲块。
7. 在登记和释放页面时检查 `n > 0`、起始描述符属于有效数组、剩余描述符数量不少于 `n`。先检查长度，再形成 `base + n`。按前后邻块的范围检查可检测的空闲区间重叠，避免将同一段空闲区间重复插入链表。
8. 断言和状态位只能发现部分非法释放，不要声称它们能够替代完整的分配记录，或检测所有重复释放和错误指针。
9. 若 `pmm.c` 已有 Buddy 的条件选择路径，保留这些路径，使没有选择宏时默认运行 Best-Fit；不要引入原项目不存在的 Buddy 头文件。若同时提供多种 Buddy 选择宏，冲突组合应在编译时报错。
10. 不新增平衡树等复杂结构，先完成符合框架约定的链表实现。测试和截图必须来自实际运行，不能编造通过结果。

[SPECIFICATION]

### 1. 定义管理函数和公共辅助函数

实现以下五个函数，可以另外增加 `static` 辅助函数：

```c
static void best_fit_init(void);
static void best_fit_init_memmap(struct Page *base, size_t n);
static struct Page *best_fit_alloc_pages(size_t n);
static void best_fit_free_pages(struct Page *base, size_t n);
static size_t best_fit_nr_free_pages(void);
```

公共辅助函数负责把一个已经设置好头页长度的空闲块插入链表，再合并前后相邻块：

- 找到第一个起始地址不小于 `base` 的后继，确定前驱。
- 插入前，检查前驱的结束位置不超过本块起点、本块结束位置不超过后继起点。
- 按地址插入一次；若前驱与本块相邻，合并到前驱，并把合并后的前驱作为当前块。
- 再检查当前块与后继是否相邻，若相邻则继续合并。
- 被吞并的旧头页清除 `PG_property`，将 `property` 置 0，并从链表摘除，避免留下失效标记和链接。
- 该辅助函数不修改 `nr_free`，页数只由调用它的登记或释放函数增加一次。

### 2. `best_fit_init()`

初始化 `free_list` 为表头自环的空链表，将 `nr_free` 设为 0。

### 3. `best_fit_init_memmap(base, n)`

`page_init()` 调用它登记一段可分配的连续页面，调用前这些页面应处于 Reserved 状态。

- 完成范围检查，并逐页断言 `PageReserved(p)`。
- 逐页清理 `flags`、`property` 和引用计数，初始化链表节点。
- 令 `base->property = n`，只给头页设置 `PG_property`。
- `nr_free` 增加 `n`，调用公共辅助函数插入并合并。
- 支持分多次登记物理相邻的可用范围；登记顺序不必按地址升序，也不能因此留下相邻却分开的空闲块。

### 4. `best_fit_alloc_pages(n)`

- 断言 `n > 0`。若 `n > nr_free`，直接返回 `NULL`。
- 遍历空闲链表，在 `property >= n` 的候选中保留最小块。遇到 `property == n` 时立即停止；大小相同可以保留最先找到的块。
- 如果没有候选，返回 `NULL` 且不修改状态。
- 找到候选后先保存原块长度和原链表位置，再摘除该块。
- 若原块大于 `n`，从 `base + n` 建立剩余块，长度为原长度减 `n`，设置新头页标记，并放回原位置，保持地址有序。
- 清除被分配头页的 `PG_property`，把它的 `property` 置 0，使被分配的页面不再表示空闲块；不要改动属于剩余块的新头页。
- `nr_free` 减少 `n`，返回原块头页。分配区间的引用计数保持框架要求的初始值 0。

### 5. `best_fit_free_pages(base, n)`

- 完成范围检查，逐页检查页面既非 Reserved，也不是空闲块头页。
- 清理这段描述符的状态、长度、引用计数和链表节点。
- 设置 `base->property = n` 和头页标记，`nr_free` 增加 `n`。
- 调用公共辅助函数，完成地址有序插入、可检测的重叠检查及前后合并。
- 同时邻接前后两个空闲块时，最终合成一个块，只有最前面的头页保留长度与头标记。

### 6. `best_fit_nr_free_pages()` 与注册

`best_fit_nr_free_pages()` 返回 `nr_free`。定义：

```c
const struct pmm_manager best_fit_pmm_manager = {
    .name = "best_fit_pmm_manager",
    .init = best_fit_init,
    .init_memmap = best_fit_init_memmap,
    .alloc_pages = best_fit_alloc_pages,
    .free_pages = best_fit_free_pages,
    .nr_free_pages = best_fit_nr_free_pages,
    .check = best_fit_check,
};
```

注意 `best_fit_check` 的声明顺序：可以把注册结构放在测试函数后，也可以添加不改变测试函数内容的 `static` 前向声明。

在 `pmm.c` 中包含已有的 Best-Fit 头文件，并使 `init_pmm_manager()` 默认设置 `pmm_manager = &best_fit_pmm_manager`。保留项目原有的初始化、输出和可选管理器路径。

### 7. 验证与交付

实现完成后先检查源码差异，确认两个框架测试没有变化，且修改范围符合要求。若仓库跟踪了 `bin/`、`obj/` 等编译产物，可以将当前源码复制到隔离测试目录构建，避免把无关产物带入提交。

- 编译内核，处理与本次修改有关的错误。
- 启动 QEMU，确认实际输出的管理器名称为 `best_fit_pmm_manager`，内置页面分配检查成功，并核对后续 SLUB 检查及是否出现断言或 panic。
- 运行项目提供的 `make grade`，记录真实评分和退出状态。若环境缺少依赖或某项失败，保留错误并说明原因，不能写成通过。
- 在验证通过后截取真实运行窗口，截图要能看清管理器名称和检查结果，保存为 `lab2/docs/T4_best_fit_test_result.png`；同时保存原始测试日志，便于核对。
- 将本提示词保存为 `lab2/docs/prompts/best_fit_prompt.md`。汇报修改内容、验证结果和交付物位置，不自动提交或推送仓库。
