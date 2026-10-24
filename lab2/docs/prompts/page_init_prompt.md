[PROMPT]
任务：在 riscv64-ucore Lab2 的 kern/mm/pmm.c 中，从预留骨架实现 static void page_init(void)，完成物理内存探测、Page 描述符初始化与可用页注册。请直接修改实际文件，保留 lab2 注释并将 YOUR CODE 替换为 2511794。只补齐本函数，不改 pmm_init、init_memmap、其他分配器或固定测试。

[RELY]
请先阅读 kern/mm/pmm.c、pmm.h、memlayout.h、mmu.h、kern/driver/dtb.h 和 libs/defs.h，以工程中的真实定义为准，不重复定义已有宏和结构。
- PGSIZE=4096，PGSHIFT=12；DRAM_BASE=0x80000000；PHYSICAL_MEMORY_END=0x88000000；PHYSICAL_MEMORY_OFFSET=0xffffffff40000000。
- nbase=DRAM_BASE/PGSIZE。pages、npage、va_pa_offset 已在 pmm.c 定义；end 为 extern char end[] 链接符号。
- struct Page 的字段为 ref、flags、property、page_link；SetPageReserved 与 set_page_ref 使用框架实现。
- get_memory_base()/get_memory_size() 返回 DTB 解析结果；可调用 panic、cprintf、init_memmap 和 pa2page。
- PADDR(kva) 检查内核地址后减 va_pa_offset；pa2page(pa) 返回 pages + PPN(pa) - nbase。
- ROUNDUP/ROUNDDOWN 使用 typeof(a)，end 需先转 uintptr_t 再参与按页取整。

[GUARANTEE]
必须补齐接口：static void page_init(void);
不修改其函数签名，不新增另一套 Page 数组或内存分配公共接口。

[SPECIFICATION]
## page_init
Pre-Condition：dtb_init 和 init_pmm_manager 已运行；DTB 信息可能有效也可能无效；入口已建立内核高地址映射。
Post-Condition：正常返回后，va_pa_offset、物理页号上界 npage、按页对齐的描述符数组 pages 正确；只有排除启动保留区、内核镜像、描述符数组后的完整页面被登记为空闲。虚拟地址、物理地址、页号和 Page* 不得混用。
Case 1：内存基址、长度非零，且基址不低于 DRAM_BASE。先设置偏移，读取并校验内存信息；令 mem_end=min(base+size, PHYSICAL_MEMORY_END)，npage=ROUNDDOWN(mem_end,PGSIZE)/PGSIZE。pages=ROUNDUP((uintptr_t)end,PGSIZE)，数组长度为 npage-nbase；逐项清零 flags/property/ref 并设置 Reserved。free_start=ROUNDUP(PADDR(pages+(npage-nbase)),PGSIZE)，free_end=npage*PGSIZE。仅在 free_start<free_end 时，调用 init_memmap(pa2page(free_start),(free_end-free_start)/PGSIZE)。输出实际探测范围。
Case 2：基址或长度为零、基址低于 DRAM_BASE。panic 终止，不继续建立描述符数组或登记空闲页；已经设置的偏移无需撤销。
Case 3：有效范围中没有剩余完整页。保留描述符的 Reserved 状态，不以零页数调用 init_memmap。
Requirements：不得把描述符个数写为 npage；不得把内核和数组存储区登记为空闲；空闲起点向上、末端向下按页对齐。输出当前源码的编译与运行结果，不预先填写通过。集成测试需在 Best-Fit 模块补齐后进行，不修改两个固定测试来绕过编译错误。
