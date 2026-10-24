
### 功能模块一 · 任务一：实现物理内存探测与页描述符初始化

**负责人：** 【2511794-宋昕睿】

**任务：** 在 `kern/mm/pmm.c` 中实现 `static void page_init(void)`：根据设备树提供的物理内存信息建立可管理物理页的描述符布局，并把排除 OpenSBI、内核镜像和描述符数组占用空间后的完整空闲页面交给当前 `pmm_manager` 管理。该函数不接收参数、不返回结果，由 `pmm_init()` 调用；成功返回时应正确设置 `va_pa_offset`、`npage` 和 `pages`，输出探测到的物理内存范围，并完成当前物理内存管理器初始空闲区的注册。

#### 一、任务规格（spec）

本任务使用"规格化 prompt"：把框架的接口约束、可用符号、边界情形全部写进 prompt，再让 AI 产出实现。prompt 的骨架如下（节选）：

```
任务：修改文件 kern/mm/pmm.c，实现 static void page_init(void)，
      完成物理内存探测与 Page 描述符初始化。
操作要求：必须在项目中修改实际文件，保留 pmm.c 中的现有代码，
      只在 page_init 的函数体位置补全；不修改 pmm_init()、init_memmap()、
      init_pmm_manager() 等既有函数，也不修改其他文件。
[RELY]    可用宏：PGSIZE/ROUNDDOWN/ROUNDUP/PPN/DRAM_BASE/
          PHYSICAL_MEMORY_OFFSET/PHYSICAL_MEMORY_END/PADDR/pa2page/
          SetPageReserved/...
          可调用：get_memory_base()/get_memory_size()/panic()/cprintf()/
          init_memmap()
          全局量：pages/npage/va_pa_offset/nbase；链接符号 end
[SPEC]    Case 1（信息有效）：设 va_pa_offset → 输出范围 →
          npage = ROUNDDOWN(min(base+size, PHYSICAL_MEMORY_END), PGSIZE)/PGSIZE →
          pages = ROUNDUP(end, PGSIZE) → [nbase, npage) 全部置 Reserved →
          free_start = ROUNDUP(PADDR(pages+(npage-nbase)), PGSIZE) →
          free_end = npage*PGSIZE → 非空才 init_memmap(pa2page(free_start), n)
          Case 2（base/size 为 0 或 base < DRAM_BASE）：panic，不再设置任何状态
          Case 3（free_start >= free_end）：不调用 init_memmap
```

三种情形与实现落点：

| 情形 | 触发条件 | 实现落点 |
| --- | --- | --- |
| Case 1 | `base != 0 && size != 0 && base >= DRAM_BASE` | 正常流程，注册空闲区 |
| Case 2 | 基址或大小为 0，或基址低于 `DRAM_BASE` | `panic(...)` 终止初始化 |
| Case 3 | 算出的空闲区起点不小于终点 | `if (free_start < free_end)` 跳过 `init_memmap` |

#### 二、核心函数理解

`page_init()` 在物理内存管理初始化链中的位置：

```
kern_init() → pmm_init() ─┬─ init_pmm_manager()   选定分配器并 init()
                          ├─ page_init()          ← 本任务：探测 + 建描述符 + 注册空闲区
                          └─ check_alloc_page()   让分配器自测
```

它要回答三个问题：**这台机器有多少物理内存（探测）→ 每一页的状态记在哪里（描述符数组）→ 哪些页现在可以分配（空闲区）**。

实现分五步，**顺序不能交换**：

| 步骤 | 做的事 | 为什么必须在这个位置 |
| --- | --- | --- |
| 1 | `va_pa_offset = PHYSICAL_MEMORY_OFFSET` | `PADDR` 的定义就是 `kva - va_pa_offset`，且不校验该变量是否已初始化；放在后面会导致所有物理地址计算错误 |
| 2 | 读 `get_memory_base()/get_memory_size()`，校验后输出范围 | 信息无效必须尽早终止，否则后续会以更难排查的方式崩溃 |
| 3 | `npage = ROUNDDOWN(mem_end, PGSIZE) / PGSIZE` | `npage` 是**物理页号上界**，描述符数组长度与 `pa2page()` 的越界检查都依赖它 |
| 4 | `pages = ROUNDUP((uintptr_t)end, PGSIZE)`，并把 `[nbase, npage)` 全部置 Reserved | `init_memmap()` 内有 `assert(PageReserved(p))`，要求描述符在交给分配器前已标记保留 |
| 5 | 由描述符数组末尾算出 `free_start`，与 `free_end` 比较后调用 `init_memmap()` | 空闲区必须排除前四步占用的全部空间，且只在区间非空时注册 |

两个关键量的关系：数组长度是 `npage - nbase`（**不是** `npage`），因为 `pages[i]` 对应物理页号 `nbase + i`（`pa2page()` 即 `&pages[PPN(pa) - nbase]`）；而 `nbase = DRAM_BASE / PGSIZE = 0x80000`。

#### 三、实现代码

`kern/mm/pmm.c` 第 64–124 行（插在框架预留的 `//lab2 function1 YOUR CODE` 位置，相邻函数未改动）：

```c
static void page_init(void) {
    /* 1. 虚实偏移必须最先确定，后面所有 PADDR 都依赖它 */
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    extern char end[];              /* 链接脚本给出的内核镜像结尾虚拟地址 */

    uint64_t mem_base = get_memory_base();
    uint64_t mem_size = get_memory_size();

    /* 2. 设备树信息无效则终止初始化 */
    if (mem_base == 0 || mem_size == 0 || mem_base < DRAM_BASE) {
        panic("page_init: invalid physical memory info (base=0x%lx, size=0x%lx)",
              mem_base, mem_size);
    }

    uint64_t mem_end = mem_base + mem_size;
    if (mem_end > PHYSICAL_MEMORY_END) {
        mem_end = PHYSICAL_MEMORY_END;
    }

    cprintf("physical memory map:\n");
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_base,
            mem_end - 1);

    /* 3. npage 是物理页号上界（不是页数），末端向下按页对齐 */
    npage = ROUNDDOWN(mem_end, PGSIZE) / PGSIZE;

    /* 4. 描述符数组紧接内核镜像，起点按页对齐 */
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);

    size_t nr_desc = npage - nbase;
    size_t i;
    for (i = 0; i < nr_desc; i++) {
        struct Page *p = pages + i;
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
        SetPageReserved(p);
    }

    /* 5. 空闲区起点：数组末尾 VA → PA → 向上对齐；终点为页对齐的物理末端 */
    uintptr_t free_start = ROUNDUP(PADDR(pages + nr_desc), PGSIZE);
    uintptr_t free_end = npage * PGSIZE;

    if (free_start < free_end) {
        init_memmap(pa2page(free_start), (free_end - free_start) / PGSIZE);
    }
}
```

#### 四、四类地址表示的分工

本任务的核心难点是**不把虚拟地址、物理地址、物理页号、描述符地址混用**：

| 概念 | 单位 | 本函数中的出现 | 用途 |
| --- | --- | --- | --- |
| 内核虚拟地址 | 字节（`0xFFFFFFFFC...`） | `end`、`pages`、`pages + nr_desc` | 内核可直接解引用 |
| 物理地址 | 字节（`0x802...`） | `mem_base`、`mem_end`、`free_start`、`free_end` | 作为 `pa2page()` 的输入、与 `DRAM_BASE` 比较 |
| 物理页号 PPN | 页（`>>12`） | `npage`、`nbase` | 描述符数组的下标基准与越界检查 |
| `Page` 描述符地址 | `struct Page *` | `pages`、`p` | 分配器操作的对象 |

转换链：`VA --PADDR--> PA --PPN--> PPN --pa2page--> Page*`，反向为 `Page* --page2pa--> PA`。

`free_start` 那一行同时出现三种表示，是检验是否真正理解的分界线。

#### 五、验证过程与结果

```bash
cd /mnt/e/OS/RISCV/labcode/lab2
make clean && make qemu
```

关键输出：

```
DTB Init
HartID: 0
DTB Address: 0x82200000
Physical Memory from DTB:
  Base: 0x0000000080000000
  Size: 0x0000000008000000 (128 MB)
  End:  0x0000000087ffffff
DTB init completed
(THU.CST) os is loading ...
Special kernel symbols:
  entry  0xffffffffc02000d8 (virtual)
  etext  0xffffffffc020173a (virtual)
  edata  0xffffffffc0206018 (virtual)
  end    0xffffffffc0206078 (virtual)
Kernel executable memory footprint: 24KB
memory management: default_pmm_manager
physical memory map:
  memory: 0x0000000008000000, [0x0000000080000000, 0x0000000087ffffff].
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0205000
satp physical address: 0x0000000080205000
```

逐项核对：

| 检查项 | 期望 | 实际 | 结论 |
| --- | --- | --- | --- |
| 探测范围输出 | `0x8000000, [0x80000000, 0x87ffffff]` | 一致 | `mem_base`/`mem_size`/上界均取对 |
| 分配器自检 | `check_alloc_page() succeeded!` | 出现 | 描述符布局与空闲区边界正确 |
| 启动页表位置 | 应小于 `pages` 起点 | `0x80205000 < 0x80207000` | 页表落在内核镜像内，未被算入空闲区 |
| panic | 不应出现 | 未出现 | DTB 校验分支未误触发 |

**布局推导**（由 `end = 0xFFFFFFFFC0206078` 推出）：

| 量 | 值 | 说明 |
| --- | --- | --- |
| `pages` | `0xFFFFFFFFC0207000`（PA `0x80207000`） | `ROUNDUP(end, 4096)` |
| 描述符个数 | `0x88000 - 0x80000 = 32768` | `npage - nbase` |
| `sizeof(struct Page)` | 40 B | `ref(4)+pad(4)+flags(8)+property(4)+pad(4)+page_link(16)` |
| 数组占用 | `32768 × 40 B = 0x140000`（1.25 MiB） | 从空闲区中扣除 |
| 数组末尾 | PA `0x80347000` | 空闲区起点（已页对齐） |
| 空闲区 | `[0x80347000, 0x88000000)` = **31929 页** | ≈124.7 MiB |

```
0x80000000 ┌──────────────┐
           │ OpenSBI 2MiB │  保留
0x80200000 ├──────────────┤
           │ 内核镜像     │  保留（end = 0x80206078）
0x80207000 ├──────────────┤
           │ Page 描述符  │  保留（32768×40B = 0x140000）
0x80347000 ├──────────────┤
           │              │
           │ 空闲区       │  交给 init_memmap，31929 页
           │              │
0x88000000 └──────────────┘
```

`check_alloc_page()` 的判据说明：它调用 `default_check()`，把空闲页**逐页全部分配**再**全部释放**，中途核对每个空闲块首页的 `property`、`nr_free` 计数的增删、以及链表总长与 `nr_free_pages()` 是否一致。描述符数组位置错、空闲区边界错、`npage` 算错、Reserved 状态不对，任何一处都会在这里 assert 失败。

#### 六、实现时想清楚的几个易错点

1. **`va_pa_offset` 必须第一句**：`PADDR` 不校验该变量，未初始化时会算出 `0xFFFFFFFF...` 量级的"物理地址"。
2. **`npage` 是上界不是页数**：写成 `npage` 作数组长度会多算 524288 个描述符、多占约 20 MB，直接覆盖其他数据。
3. **描述符必须先 Reserved 再注册**：`init_memmap()` 内部 `assert(PageReserved(p))`，同时 `property` 必须清零（只对空闲块首页有意义，残留值会让分配器误判块长）。
4. **`init_memmap()` 的页数参数不能为零**：它有 `assert(n > 0)`，所以空区间必须在调用前拦住；该守卫同时保证 `pa2page()` 中 `PPN(pa) < npage` 不触发 panic。
5. **尾页不能计入空闲区**：`npage` 由 `ROUNDDOWN(mem_end, PGSIZE)` 得到，`free_end = npage * PGSIZE` 因此天然对齐，不足一页的尾巴被自动排除。

#### 七、遇到的问题与解决

**问题 1：`ROUNDUP(end, PGSIZE)` 编译报 `cast specifies array type`**

```
kern/mm/pmm.c:98:28: error: cast specifies array type
    pages = (struct Page *)ROUNDUP(end, PGSIZE);
libs/defs.h:62:13: note: in expansion of macro 'ROUNDUP'
```

- **现象**：`make` 直接失败，报错指向宏内部的 `(typeof(a))`。
- **原因**：`end` 是链接符号 `extern char end[]`，在表达式里会退化为指针参与运算，但 `typeof(end)` 取的是**声明类型 `char[]`**，于是 `ROUNDUP` 展开为 `(char[])(...)` —— C 不允许以数组类型作为强制转换的目标类型。
- **解决**：传给宏之前先转成整数类型：`ROUNDUP((uintptr_t)end, PGSIZE)`，此时 `typeof` 为标量类型，宏合法。

**问题 2：任务一代码无法单独编译——整个内核停在 `free_list` / `nr_free` 未定义**

- **现象**：`make` 停在 `kern/mm/best_fit_pmm.c`，报 `'free_list' undeclared`、`'nr_free' undeclared`，四个错误全部落在 `basic_check()` / `best_fit_check()` 内。
- **原因**：这两个是框架给的测试函数（**不允许修改**），它们直接引用了 Best-Fit 模块内部的定义（`static free_area_t free_area;` 加 `#define free_list ...`）。而 Best-Fit 的完整实现属于任务二，尚未编写，于是四个测试函数引用的名字无定义，编译中断。
- **结论**：这不是 `page_init()` 的问题，而是实验代码骨架的形态——**任务一在编译期依赖任务二的模块**。
- **解决**：在不改动两个测试函数、不实现算法的前提下，于 `best_fit_pmm.c` 顶部临时补上三行名字定义，让编译通过（此时 `init_pmm_manager()` 仍指向 `default_pmm_manager`，这两个测试函数不会被执行，不影响 `page_init()` 的验证）；并在注释中标注"任务二接手必须删除"。验证完成后撤回该临时改动，只提交 `pmm.c`。

#### 八、知识点与 OS 原理的对应

| 本实验中的点 | OS 原理中的概念 | 关系与差异 |
| --- | --- | --- |
| `phys[mem_base, mem_end]` + `npage` | 物理内存的发现与地址空间上界 | 原理课上默认"内存大小已知"；实验里必须从**设备树**读出，并处理"报告值 > 框架上限"的情况 |
| `struct Page` 数组 | 页帧数据库（page frame database） | 原理讲"每页一个描述符"，实验给出了具体布局：数组紧接内核镜像、每项 40 B、下标 = `PPN - nbase` |
| `SetPageReserved` | 页帧状态机 / 保留区 | 原理里保留区是静态划分的概念；实验里用标志位表达，且必须"先标记后注册" |
| `init_memmap()` | 空闲链表建立 | 原理讲空闲链表/位图两种组织；本实验用侵入式双向链表（`list.h`） |
| `PADDR` / `va_pa_offset` | 逻辑地址与物理地址的分离 | 原理讲地址转换的抽象；实验里在"内核恒等映射 + 固定偏移"这一特例下，转换退化为一次减法 |
| `npage` 越界检查 | 物理地址合法性校验 | 原理强调访问越界属于未定义行为；实验用 `panic` 显式 fail-closed |
| DTB 探测 | 硬件自描述（firmware-provided memory map） | 原理课通常讲 BIOS/E820 或 ACPI；RISC-V 上是 OpenSBI 传递的 DTB |

#### 九、原理中有、本实验未覆盖的部分

1. **页表建立与地址翻译的完整流程**：本实验只用到 lab1 遗留的启动页表（一个 1 GiB 大页映射内核），`satp` 切换与 TLB 刷新（`sfence.vma`）虽有涉及，但"为进程建立页表、页表遍历、缺页异常"没有实现。
2. **虚拟内存的管理策略**：按需调页、页面置换算法（LRU/Clock）、Swap、写时复制（COW）等均未涉及。
3. **内存分区与 NUMA**：真实内核有 zone（DMA/DMA32/Normal）、节点与迁移类型；本实验只有单一物理地址区间。
4. **并发与锁**：本实验在单 hart（`Current Hart: 0`）上启动，分配器没有加锁；原理中的自旋锁/每 CPU 缓存（per-CPU pageset）未覆盖。
5. **碎片化治理**：First-Fit 只做相邻合并；真正的内存规整（compaction）、迁移、SLAB/SLUB 对象缓存不属于任务一。
6. **用户态接口**：`brk`/`mmap`/`munmap` 等"把内存交给用户进程"的路径完全没有触及。
7. **物理内存热插拔与容错**：内存坏页隔离、ECC、内存热添加等未涉及。

#### 十、结论

任务一交付的是 `kern/mm/pmm.c` 中的一个函数 `page_init()`（第 64–124 行），约 61 行。它利用设备树报告的物理内存范围，把 `Page` 描述符数组紧接内核镜像摆放（32768 个、1.25 MiB），将该区间 `[nbase, npage)` 全部初始化为保留状态，最后把描述符数组之后 `[0x80347000, 0x88000000)` 的 31929 个完整页注册给当前物理内存管理器。

验证结果：`physical memory map: memory: 0x8000000, [0x80000000, 0x87ffffff]` 与 `check_alloc_page() succeeded!` 均符合预期，且启动页表物理地址 `0x80205000` 小于描述符数组起点 `0x80207000`，证明页表与内核镜像都被正确排除在空闲区之外。
