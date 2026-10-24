#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <buddy_pmm.h>
#include <tree_buddy_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <riscv.h>
#include <dtb.h>

// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;


static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    // Lab2 T4: use Best-Fit by default; keep the team's Buddy implementations.
#if defined(PMM_USE_LIST_BUDDY) && defined(PMM_USE_TREE_BUDDY)
#error "Select at most one Buddy implementation"
#elif defined(PMM_USE_LIST_BUDDY)
    pmm_manager = &buddy_pmm_manager;
#elif defined(PMM_USE_TREE_BUDDY)
    pmm_manager = &tree_buddy_pmm_manager;
#else
    pmm_manager = &best_fit_pmm_manager;
#endif
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}

//lab2 function1 2511794
/* page_init - 根据设备树报告的物理内存信息建立 Page 描述符布局，并把排除
 * OpenSBI、内核镜像和描述符数组之后完整空闲页交给当前 pmm_manager。
 * 无参数、无返回值，由 pmm_init() 调用。 */
static void page_init(void) {
    /* 1. 内核虚拟地址与物理地址之间的固定偏移。必须最先设置，
     *    后面所有 PADDR 都用它。 */
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    /* end 是链接脚本给出的内核镜像结尾虚拟地址 */
    extern char end[];

    uint64_t mem_base = get_memory_base();
    uint64_t mem_size = get_memory_size();

    /* 2. 设备树信息无效则终止初始化，绝不带着错误布局继续 */
    if (mem_base == 0 || mem_size == 0 || mem_base < DRAM_BASE) {
        panic("page_init: invalid physical memory info (base=0x%lx, size=0x%lx)",
              mem_base, mem_size);
    }

    /* 可管理物理内存上界：不越过设备树报告的末端，也不越过框架声明的上限 */
    uint64_t mem_end = mem_base + mem_size;
    if (mem_end > PHYSICAL_MEMORY_END) {
        mem_end = PHYSICAL_MEMORY_END;
    }

    cprintf("physical memory map:\n");
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_base,
            mem_end - 1);

    /* 3. npage 是可管理的物理页号上界（不是页数），末端向下按页对齐 */
    npage = ROUNDDOWN(mem_end, PGSIZE) / PGSIZE;

    /* 4. Page 描述符数组紧接内核镜像之后，起点按页对齐。
     *    end 是 char[] 数组符号，先转成整数类型，否则 ROUNDUP 里的
     *    typeof(end) 是数组类型，强制转换不合法。 */
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);

    /* 描述符数组覆盖物理页号区间 [nbase, npage)。先把每个描述符都置为
     * 保留状态，防止尚未完成布局的页面被提前分配。 */
    size_t nr_desc = npage - nbase;
    size_t i;
    for (i = 0; i < nr_desc; i++) {
        struct Page *p = pages + i;
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
        SetPageReserved(p);
    }

    /* 5. 空闲区起点：描述符数组末尾的虚拟地址经 PADDR 转成物理地址，
     *    再向上按页对齐；终点是可管理物理内存末端（已是页对齐的 npage*PGSIZE） */
    uintptr_t free_start = ROUNDUP(PADDR(pages + nr_desc), PGSIZE);
    uintptr_t free_end = npage * PGSIZE;

    /* 只有非空的完整页面区间才交给 pmm_manager */
    if (free_start < free_end) {
        init_memmap(pa2page(free_start), (free_end - free_start) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
