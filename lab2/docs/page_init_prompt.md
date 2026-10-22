[PROMPT]
**任务**：修改文件 kern/mm/pmm.c，实现 static void page_init(void) 函数，完成物理内存探测与 Page 描述符初始化。该函数由 pmm_init() 调用，不接收参数、不返回结果。

**操作要求**：你必须在项目中修改实际文件，而不是仅展示代码。保留 pmm.c 中的现有代码，只在 page_init 的函数体位置补全；不要修改 pmm_init()、init_memmap()、init_pmm_manager() 等既有函数，也不要修改其他文件。

**输出要求**：直接进行文件操作。使用下面 [RELY]、[GUARANTEE]、[SPECIFICATION] 部分提供的信息，以工程真实代码为准，不要引入无关功能。

[RELY]
// 宏定义（请从 memlayout.h / pmm.h / mmu.h 复制真实定义）
#define PGSIZE              < >
#define PGSHIFT             < >
#define ROUNDUP(a, n)       < >
#define ROUNDDOWN(a, n)     < >
#define PPN(pa)             < >
#define DRAM_BASE           < >
#define PHYSICAL_MEMORY_OFFSET < >
#define PHYSICAL_MEMORY_END < >
#define KERNBASE            < >

// 地址转换与页面状态
#define PADDR(kva)          < >
#define KADDR(pa)           < >
#define pa2page(pa)         < >
#define SetPageReserved(page)   < >
#define ClearPageReserved(page) <  >
#define PageReserved(page)      < >
#define SetPageProperty(page)   < >
#define ClearPageProperty(page) < >
#define PageProperty(page)      < >
#define set_page_ref(page, v)   < >

// 数据结构
struct Page {
    int ref;
    uint64_t flags;
    unsigned int property;
    list_entry_t page_link;
};

// 可调用函数
uint64_t get_memory_base(void);
uint64_t get_memory_size(void);
void panic(const char *fmt, ...);
int cprintf(const char *fmt, ...);
static void init_memmap(struct Page *base, size_t n);

// 全局变量（已在 pmm.c 中定义）
struct Page *pages;
size_t npage;
uint64_t va_pa_offset;
const size_t nbase;   // DRAM_BASE / PGSIZE

// 链接符号
extern char end[];    // 内核镜像结尾的虚拟地址

[GUARANTEE]
必须实现或修改的接口：
```c
static void page_init(void);
```

你可以根据需要添加：
- 辅助函数（建议设为 static）
- 模块内部使用的宏定义
- 模块内部的静态变量

[SPECIFICATION]
## page_init
**Pre-Condition**:
- 已调用 dtb_init()，get_memory_base() 与 get_memory_size() 可能返回有效值或无效值。
- 已调用 init_pmm_manager()，pmm_manager 已指向当前物理内存管理器。
- va_pa_offset 尚未设置或为 0；pages 与 npage 尚未设置。
- 内核处于 Sv39 分页模式，虚拟地址与物理地址之间存在固定偏移。

**Post-Condition**:
- va_pa_offset 已设置为 PHYSICAL_MEMORY_OFFSET。
- npage 表示内核可管理的物理页号上界。
- pages 指向按页对齐的 Page 描述符数组首地址。
- 描述符数组覆盖物理页号区间 [nbase, npage)，每个描述符均已初始化为非空闲状态。
- 当前 pmm_manager 只接管排除 OpenSBI、内核镜像和描述符数组占用空间后、按页对齐的完整空闲页面。
- 设备树信息无效时通过 panic() 终止；没有可用完整页面时不调用 init_memmap()。

  **Case 1**:
  - 触发条件：get_memory_base() 返回的基址非 0，get_memory_size() 返回的大小非 0，且基址不小于 DRAM_BASE。
  - 执行行为：设置 va_pa_offset；读取并输出物理内存基址、大小和起止地址；以 min(base + size, PHYSICAL_MEMORY_END) 向下取整到页计算 npage；将 pages 设为 ROUNDUP(end, PGSIZE)；把 [nbase, npage) 内所有描述符的 flags、ref、property 清零并全部 SetPageReserved；计算描述符数组末尾虚拟地址 pages + (npage - nbase)，用 PADDR 转为物理地址后 ROUNDUP 到页，得到空闲区起点；以 npage * PGSIZE 作为空闲区终点；若起点小于终点，则调用 init_memmap(pa2page(起点), (终点 - 起点) / PGSIZE)。
  - 最终状态：va_pa_offset、npage、pages 正确；描述符数组覆盖 [nbase, npage)；仅描述符数组之后的完整空闲页被交给 pmm_manager。

  **Case 2**:
  - 触发条件：get_memory_base() 返回 0，或 get_memory_size() 返回 0，或基址小于 DRAM_BASE。
  - 执行行为：通过 panic() 终止初始化，不继续设置 pages、npage 或调用 init_memmap()。
  - 最终状态：内核在初始化阶段终止，不会进入带错误内存布局的后续流程。

  **Case 3**:
  - 触发条件：Case 1 计算得到的空闲区起点不小于空闲区终点。
  - 执行行为：不调用 init_memmap()，保留已设置的 va_pa_offset、npage、pages 和全部保留状态的描述符。
  - 最终状态：当前 pmm_manager 不接管任何空闲页；不会把不完整尾页或描述符数组占用页注册为空闲页。

**Requirements**:
- 必须先设置 va_pa_offset，再使用 PADDR；否则 PADDR 会因 va_pa_offset 未初始化而得到错误物理地址。
- 必须区分虚拟地址、物理地址、物理页号和 Page 描述符地址：pages 是虚拟地址，PADDR(pages + ...) 才是物理地址，pa2page() 的参数是物理地址。
- 所有描述符在交给 init_memmap() 之前必须先处于保留状态，防止未完成布局的页面被提前分配。
- 空闲区起点向上按页对齐，终点向下按页对齐；只有非空的完整页面区间才允许调用 init_memmap()。
- 不得把 OpenSBI 占用区、内核镜像、Page 描述符数组占用的页面注册为空闲页。