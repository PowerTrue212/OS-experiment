
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00003517          	auipc	a0,0x3
ffffffffc0200050:	cd450513          	addi	a0,a0,-812 # ffffffffc0202d20 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	10a000ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00003517          	auipc	a0,0x3
ffffffffc0200066:	cde50513          	addi	a0,a0,-802 # ffffffffc0202d40 <etext+0x24>
ffffffffc020006a:	0f6000ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00003597          	auipc	a1,0x3
ffffffffc0200072:	cae58593          	addi	a1,a1,-850 # ffffffffc0202d1c <etext>
ffffffffc0200076:	00003517          	auipc	a0,0x3
ffffffffc020007a:	cea50513          	addi	a0,a0,-790 # ffffffffc0202d60 <etext+0x44>
ffffffffc020007e:	0e2000ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00007597          	auipc	a1,0x7
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0207018 <free_area>
ffffffffc020008a:	00003517          	auipc	a0,0x3
ffffffffc020008e:	cf650513          	addi	a0,a0,-778 # ffffffffc0202d80 <etext+0x64>
ffffffffc0200092:	0ce000ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00007597          	auipc	a1,0x7
ffffffffc020009a:	17658593          	addi	a1,a1,374 # ffffffffc020720c <end>
ffffffffc020009e:	00003517          	auipc	a0,0x3
ffffffffc02000a2:	d0250513          	addi	a0,a0,-766 # ffffffffc0202da0 <etext+0x84>
ffffffffc02000a6:	0ba000ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00007597          	auipc	a1,0x7
ffffffffc02000ae:	56158593          	addi	a1,a1,1377 # ffffffffc020760b <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00003517          	auipc	a0,0x3
ffffffffc02000d0:	cf450513          	addi	a0,a0,-780 # ffffffffc0202dc0 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a069                	j	ffffffffc0200160 <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00007517          	auipc	a0,0x7
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0207018 <free_area>
ffffffffc02000e0:	00007617          	auipc	a2,0x7
ffffffffc02000e4:	12c60613          	addi	a2,a2,300 # ffffffffc020720c <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	41b020ef          	jal	ra,ffffffffc0202d0a <memset>
    dtb_init();
ffffffffc02000f4:	140000ef          	jal	ra,ffffffffc0200234 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	132000ef          	jal	ra,ffffffffc020022a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00003517          	auipc	a0,0x3
ffffffffc0200100:	d1450513          	addi	a0,a0,-748 # ffffffffc0202e10 <etext+0xf4>
ffffffffc0200104:	092000ef          	jal	ra,ffffffffc0200196 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	7fd000ef          	jal	ra,ffffffffc0201108 <pmm_init>
    slub_init();
ffffffffc0200110:	3e0010ef          	jal	ra,ffffffffc02014f0 <slub_init>
    slub_check();
ffffffffc0200114:	7b5010ef          	jal	ra,ffffffffc02020c8 <slub_check>
    cprintf("slub_check() succeeded!\n");
ffffffffc0200118:	00003517          	auipc	a0,0x3
ffffffffc020011c:	cd850513          	addi	a0,a0,-808 # ffffffffc0202df0 <etext+0xd4>
ffffffffc0200120:	040000ef          	jal	ra,ffffffffc0200160 <cprintf>

    /* do nothing */
    while (1)
ffffffffc0200124:	a001                	j	ffffffffc0200124 <kern_init+0x4c>

ffffffffc0200126 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200126:	1141                	addi	sp,sp,-16
ffffffffc0200128:	e022                	sd	s0,0(sp)
ffffffffc020012a:	e406                	sd	ra,8(sp)
ffffffffc020012c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020012e:	0fe000ef          	jal	ra,ffffffffc020022c <cons_putc>
    (*cnt) ++;
ffffffffc0200132:	401c                	lw	a5,0(s0)
}
ffffffffc0200134:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200136:	2785                	addiw	a5,a5,1
ffffffffc0200138:	c01c                	sw	a5,0(s0)
}
ffffffffc020013a:	6402                	ld	s0,0(sp)
ffffffffc020013c:	0141                	addi	sp,sp,16
ffffffffc020013e:	8082                	ret

ffffffffc0200140 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200140:	1101                	addi	sp,sp,-32
ffffffffc0200142:	862a                	mv	a2,a0
ffffffffc0200144:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200146:	00000517          	auipc	a0,0x0
ffffffffc020014a:	fe050513          	addi	a0,a0,-32 # ffffffffc0200126 <cputch>
ffffffffc020014e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200150:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200152:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200154:	7a0020ef          	jal	ra,ffffffffc02028f4 <vprintfmt>
    return cnt;
}
ffffffffc0200158:	60e2                	ld	ra,24(sp)
ffffffffc020015a:	4532                	lw	a0,12(sp)
ffffffffc020015c:	6105                	addi	sp,sp,32
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200160:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200162:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200166:	8e2a                	mv	t3,a0
ffffffffc0200168:	f42e                	sd	a1,40(sp)
ffffffffc020016a:	f832                	sd	a2,48(sp)
ffffffffc020016c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020016e:	00000517          	auipc	a0,0x0
ffffffffc0200172:	fb850513          	addi	a0,a0,-72 # ffffffffc0200126 <cputch>
ffffffffc0200176:	004c                	addi	a1,sp,4
ffffffffc0200178:	869a                	mv	a3,t1
ffffffffc020017a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020017c:	ec06                	sd	ra,24(sp)
ffffffffc020017e:	e0ba                	sd	a4,64(sp)
ffffffffc0200180:	e4be                	sd	a5,72(sp)
ffffffffc0200182:	e8c2                	sd	a6,80(sp)
ffffffffc0200184:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200186:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200188:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020018a:	76a020ef          	jal	ra,ffffffffc02028f4 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020018e:	60e2                	ld	ra,24(sp)
ffffffffc0200190:	4512                	lw	a0,4(sp)
ffffffffc0200192:	6125                	addi	sp,sp,96
ffffffffc0200194:	8082                	ret

ffffffffc0200196 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200196:	1101                	addi	sp,sp,-32
ffffffffc0200198:	e822                	sd	s0,16(sp)
ffffffffc020019a:	ec06                	sd	ra,24(sp)
ffffffffc020019c:	e426                	sd	s1,8(sp)
ffffffffc020019e:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02001a0:	00054503          	lbu	a0,0(a0)
ffffffffc02001a4:	c51d                	beqz	a0,ffffffffc02001d2 <cputs+0x3c>
ffffffffc02001a6:	0405                	addi	s0,s0,1
ffffffffc02001a8:	4485                	li	s1,1
ffffffffc02001aa:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001ac:	080000ef          	jal	ra,ffffffffc020022c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001b0:	00044503          	lbu	a0,0(s0)
ffffffffc02001b4:	008487bb          	addw	a5,s1,s0
ffffffffc02001b8:	0405                	addi	s0,s0,1
ffffffffc02001ba:	f96d                	bnez	a0,ffffffffc02001ac <cputs+0x16>
    (*cnt) ++;
ffffffffc02001bc:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001c0:	4529                	li	a0,10
ffffffffc02001c2:	06a000ef          	jal	ra,ffffffffc020022c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001c6:	60e2                	ld	ra,24(sp)
ffffffffc02001c8:	8522                	mv	a0,s0
ffffffffc02001ca:	6442                	ld	s0,16(sp)
ffffffffc02001cc:	64a2                	ld	s1,8(sp)
ffffffffc02001ce:	6105                	addi	sp,sp,32
ffffffffc02001d0:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001d2:	4405                	li	s0,1
ffffffffc02001d4:	b7f5                	j	ffffffffc02001c0 <cputs+0x2a>

ffffffffc02001d6 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001d6:	00007317          	auipc	t1,0x7
ffffffffc02001da:	fea30313          	addi	t1,t1,-22 # ffffffffc02071c0 <is_panic>
ffffffffc02001de:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001e2:	715d                	addi	sp,sp,-80
ffffffffc02001e4:	ec06                	sd	ra,24(sp)
ffffffffc02001e6:	e822                	sd	s0,16(sp)
ffffffffc02001e8:	f436                	sd	a3,40(sp)
ffffffffc02001ea:	f83a                	sd	a4,48(sp)
ffffffffc02001ec:	fc3e                	sd	a5,56(sp)
ffffffffc02001ee:	e0c2                	sd	a6,64(sp)
ffffffffc02001f0:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001f2:	000e0363          	beqz	t3,ffffffffc02001f8 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001f6:	a001                	j	ffffffffc02001f6 <__panic+0x20>
    is_panic = 1;
ffffffffc02001f8:	4785                	li	a5,1
ffffffffc02001fa:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001fe:	8432                	mv	s0,a2
ffffffffc0200200:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200202:	862e                	mv	a2,a1
ffffffffc0200204:	85aa                	mv	a1,a0
ffffffffc0200206:	00003517          	auipc	a0,0x3
ffffffffc020020a:	c2a50513          	addi	a0,a0,-982 # ffffffffc0202e30 <etext+0x114>
    va_start(ap, fmt);
ffffffffc020020e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200210:	f51ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200214:	65a2                	ld	a1,8(sp)
ffffffffc0200216:	8522                	mv	a0,s0
ffffffffc0200218:	f29ff0ef          	jal	ra,ffffffffc0200140 <vcprintf>
    cprintf("\n");
ffffffffc020021c:	00003517          	auipc	a0,0x3
ffffffffc0200220:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0202de8 <etext+0xcc>
ffffffffc0200224:	f3dff0ef          	jal	ra,ffffffffc0200160 <cprintf>
ffffffffc0200228:	b7f9                	j	ffffffffc02001f6 <__panic+0x20>

ffffffffc020022a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020022a:	8082                	ret

ffffffffc020022c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020022c:	0ff57513          	zext.b	a0,a0
ffffffffc0200230:	2470206f          	j	ffffffffc0202c76 <sbi_console_putchar>

ffffffffc0200234 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200234:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200236:	00003517          	auipc	a0,0x3
ffffffffc020023a:	c1a50513          	addi	a0,a0,-998 # ffffffffc0202e50 <etext+0x134>
void dtb_init(void) {
ffffffffc020023e:	fc86                	sd	ra,120(sp)
ffffffffc0200240:	f8a2                	sd	s0,112(sp)
ffffffffc0200242:	e8d2                	sd	s4,80(sp)
ffffffffc0200244:	f4a6                	sd	s1,104(sp)
ffffffffc0200246:	f0ca                	sd	s2,96(sp)
ffffffffc0200248:	ecce                	sd	s3,88(sp)
ffffffffc020024a:	e4d6                	sd	s5,72(sp)
ffffffffc020024c:	e0da                	sd	s6,64(sp)
ffffffffc020024e:	fc5e                	sd	s7,56(sp)
ffffffffc0200250:	f862                	sd	s8,48(sp)
ffffffffc0200252:	f466                	sd	s9,40(sp)
ffffffffc0200254:	f06a                	sd	s10,32(sp)
ffffffffc0200256:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200258:	f09ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020025c:	00007597          	auipc	a1,0x7
ffffffffc0200260:	da45b583          	ld	a1,-604(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200264:	00003517          	auipc	a0,0x3
ffffffffc0200268:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0202e60 <etext+0x144>
ffffffffc020026c:	ef5ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200270:	00007417          	auipc	s0,0x7
ffffffffc0200274:	d9840413          	addi	s0,s0,-616 # ffffffffc0207008 <boot_dtb>
ffffffffc0200278:	600c                	ld	a1,0(s0)
ffffffffc020027a:	00003517          	auipc	a0,0x3
ffffffffc020027e:	bf650513          	addi	a0,a0,-1034 # ffffffffc0202e70 <etext+0x154>
ffffffffc0200282:	edfff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200286:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020028a:	00003517          	auipc	a0,0x3
ffffffffc020028e:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0202e88 <etext+0x16c>
    if (boot_dtb == 0) {
ffffffffc0200292:	120a0463          	beqz	s4,ffffffffc02003ba <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200296:	57f5                	li	a5,-3
ffffffffc0200298:	07fa                	slli	a5,a5,0x1e
ffffffffc020029a:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020029e:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a0:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a4:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002aa:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ae:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002b2:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b6:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ba:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	8ec9                	or	a3,a3,a0
ffffffffc02002be:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002c2:	1b7d                	addi	s6,s6,-1
ffffffffc02002c4:	0167f7b3          	and	a5,a5,s6
ffffffffc02002c8:	8dd5                	or	a1,a1,a3
ffffffffc02002ca:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002cc:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d0:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002d2:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8ce1>
ffffffffc02002d6:	10f59163          	bne	a1,a5,ffffffffc02003d8 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002da:	471c                	lw	a5,8(a4)
ffffffffc02002dc:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002de:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002e4:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002e8:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ec:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f0:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f4:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f8:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fc:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200300:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200308:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020030a:	01146433          	or	s0,s0,a7
ffffffffc020030e:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200312:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200316:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200318:	0087979b          	slliw	a5,a5,0x8
ffffffffc020031c:	8c49                	or	s0,s0,a0
ffffffffc020031e:	0166f6b3          	and	a3,a3,s6
ffffffffc0200322:	00ca6a33          	or	s4,s4,a2
ffffffffc0200326:	0167f7b3          	and	a5,a5,s6
ffffffffc020032a:	8c55                	or	s0,s0,a3
ffffffffc020032c:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200330:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200332:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200334:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200336:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020033a:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020033c:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020033e:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200342:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200344:	00003917          	auipc	s2,0x3
ffffffffc0200348:	b9490913          	addi	s2,s2,-1132 # ffffffffc0202ed8 <etext+0x1bc>
ffffffffc020034c:	49bd                	li	s3,15
        switch (token) {
ffffffffc020034e:	4d91                	li	s11,4
ffffffffc0200350:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200352:	00003497          	auipc	s1,0x3
ffffffffc0200356:	b7e48493          	addi	s1,s1,-1154 # ffffffffc0202ed0 <etext+0x1b4>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020035a:	000a2703          	lw	a4,0(s4)
ffffffffc020035e:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200362:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200366:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020036a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020036e:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200372:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200376:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200378:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020037c:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200380:	8fd5                	or	a5,a5,a3
ffffffffc0200382:	00eb7733          	and	a4,s6,a4
ffffffffc0200386:	8fd9                	or	a5,a5,a4
ffffffffc0200388:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020038a:	09778c63          	beq	a5,s7,ffffffffc0200422 <dtb_init+0x1ee>
ffffffffc020038e:	00fbea63          	bltu	s7,a5,ffffffffc02003a2 <dtb_init+0x16e>
ffffffffc0200392:	07a78663          	beq	a5,s10,ffffffffc02003fe <dtb_init+0x1ca>
ffffffffc0200396:	4709                	li	a4,2
ffffffffc0200398:	00e79763          	bne	a5,a4,ffffffffc02003a6 <dtb_init+0x172>
ffffffffc020039c:	4c81                	li	s9,0
ffffffffc020039e:	8a56                	mv	s4,s5
ffffffffc02003a0:	bf6d                	j	ffffffffc020035a <dtb_init+0x126>
ffffffffc02003a2:	ffb78ee3          	beq	a5,s11,ffffffffc020039e <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02003a6:	00003517          	auipc	a0,0x3
ffffffffc02003aa:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202f50 <etext+0x234>
ffffffffc02003ae:	db3ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02003b2:	00003517          	auipc	a0,0x3
ffffffffc02003b6:	bd650513          	addi	a0,a0,-1066 # ffffffffc0202f88 <etext+0x26c>
}
ffffffffc02003ba:	7446                	ld	s0,112(sp)
ffffffffc02003bc:	70e6                	ld	ra,120(sp)
ffffffffc02003be:	74a6                	ld	s1,104(sp)
ffffffffc02003c0:	7906                	ld	s2,96(sp)
ffffffffc02003c2:	69e6                	ld	s3,88(sp)
ffffffffc02003c4:	6a46                	ld	s4,80(sp)
ffffffffc02003c6:	6aa6                	ld	s5,72(sp)
ffffffffc02003c8:	6b06                	ld	s6,64(sp)
ffffffffc02003ca:	7be2                	ld	s7,56(sp)
ffffffffc02003cc:	7c42                	ld	s8,48(sp)
ffffffffc02003ce:	7ca2                	ld	s9,40(sp)
ffffffffc02003d0:	7d02                	ld	s10,32(sp)
ffffffffc02003d2:	6de2                	ld	s11,24(sp)
ffffffffc02003d4:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003d6:	b369                	j	ffffffffc0200160 <cprintf>
}
ffffffffc02003d8:	7446                	ld	s0,112(sp)
ffffffffc02003da:	70e6                	ld	ra,120(sp)
ffffffffc02003dc:	74a6                	ld	s1,104(sp)
ffffffffc02003de:	7906                	ld	s2,96(sp)
ffffffffc02003e0:	69e6                	ld	s3,88(sp)
ffffffffc02003e2:	6a46                	ld	s4,80(sp)
ffffffffc02003e4:	6aa6                	ld	s5,72(sp)
ffffffffc02003e6:	6b06                	ld	s6,64(sp)
ffffffffc02003e8:	7be2                	ld	s7,56(sp)
ffffffffc02003ea:	7c42                	ld	s8,48(sp)
ffffffffc02003ec:	7ca2                	ld	s9,40(sp)
ffffffffc02003ee:	7d02                	ld	s10,32(sp)
ffffffffc02003f0:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003f2:	00003517          	auipc	a0,0x3
ffffffffc02003f6:	ab650513          	addi	a0,a0,-1354 # ffffffffc0202ea8 <etext+0x18c>
}
ffffffffc02003fa:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003fc:	b395                	j	ffffffffc0200160 <cprintf>
                int name_len = strlen(name);
ffffffffc02003fe:	8556                	mv	a0,s5
ffffffffc0200400:	091020ef          	jal	ra,ffffffffc0202c90 <strlen>
ffffffffc0200404:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200406:	4619                	li	a2,6
ffffffffc0200408:	85a6                	mv	a1,s1
ffffffffc020040a:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc020040c:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020040e:	0d7020ef          	jal	ra,ffffffffc0202ce4 <strncmp>
ffffffffc0200412:	e111                	bnez	a0,ffffffffc0200416 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200414:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200416:	0a91                	addi	s5,s5,4
ffffffffc0200418:	9ad2                	add	s5,s5,s4
ffffffffc020041a:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020041e:	8a56                	mv	s4,s5
ffffffffc0200420:	bf2d                	j	ffffffffc020035a <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200422:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200426:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042a:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020042e:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200436:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020043a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020043e:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200442:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200446:	0087979b          	slliw	a5,a5,0x8
ffffffffc020044a:	00eaeab3          	or	s5,s5,a4
ffffffffc020044e:	00fb77b3          	and	a5,s6,a5
ffffffffc0200452:	00faeab3          	or	s5,s5,a5
ffffffffc0200456:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200458:	000c9c63          	bnez	s9,ffffffffc0200470 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020045c:	1a82                	slli	s5,s5,0x20
ffffffffc020045e:	00368793          	addi	a5,a3,3
ffffffffc0200462:	020ada93          	srli	s5,s5,0x20
ffffffffc0200466:	9abe                	add	s5,s5,a5
ffffffffc0200468:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020046c:	8a56                	mv	s4,s5
ffffffffc020046e:	b5f5                	j	ffffffffc020035a <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200470:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200474:	85ca                	mv	a1,s2
ffffffffc0200476:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200478:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200480:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200484:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200488:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020048c:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020048e:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200492:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200496:	8d59                	or	a0,a0,a4
ffffffffc0200498:	00fb77b3          	and	a5,s6,a5
ffffffffc020049c:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020049e:	1502                	slli	a0,a0,0x20
ffffffffc02004a0:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02004a2:	9522                	add	a0,a0,s0
ffffffffc02004a4:	023020ef          	jal	ra,ffffffffc0202cc6 <strcmp>
ffffffffc02004a8:	66a2                	ld	a3,8(sp)
ffffffffc02004aa:	f94d                	bnez	a0,ffffffffc020045c <dtb_init+0x228>
ffffffffc02004ac:	fb59f8e3          	bgeu	s3,s5,ffffffffc020045c <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02004b0:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004b4:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004b8:	00003517          	auipc	a0,0x3
ffffffffc02004bc:	a2850513          	addi	a0,a0,-1496 # ffffffffc0202ee0 <etext+0x1c4>
           fdt32_to_cpu(x >> 32);
ffffffffc02004c0:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c4:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004c8:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004cc:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004d0:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d4:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004dc:	0187d693          	srli	a3,a5,0x18
ffffffffc02004e0:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004e4:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004e8:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004f0:	010f6f33          	or	t5,t5,a6
ffffffffc02004f4:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004f8:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fc:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	0186f6b3          	and	a3,a3,s8
ffffffffc0200508:	01859e1b          	slliw	t3,a1,0x18
ffffffffc020050c:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200510:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200514:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200518:	8361                	srli	a4,a4,0x18
ffffffffc020051a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051e:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200522:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200526:	00cb7633          	and	a2,s6,a2
ffffffffc020052a:	0088181b          	slliw	a6,a6,0x8
ffffffffc020052e:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200532:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200536:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053a:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053e:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200542:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200546:	011b78b3          	and	a7,s6,a7
ffffffffc020054a:	005eeeb3          	or	t4,t4,t0
ffffffffc020054e:	00c6e733          	or	a4,a3,a2
ffffffffc0200552:	006c6c33          	or	s8,s8,t1
ffffffffc0200556:	010b76b3          	and	a3,s6,a6
ffffffffc020055a:	00bb7b33          	and	s6,s6,a1
ffffffffc020055e:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200562:	016c6b33          	or	s6,s8,s6
ffffffffc0200566:	01146433          	or	s0,s0,a7
ffffffffc020056a:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc020056c:	1702                	slli	a4,a4,0x20
ffffffffc020056e:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200570:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200572:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200574:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200576:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020057a:	0167eb33          	or	s6,a5,s6
ffffffffc020057e:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200580:	be1ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200584:	85a2                	mv	a1,s0
ffffffffc0200586:	00003517          	auipc	a0,0x3
ffffffffc020058a:	97a50513          	addi	a0,a0,-1670 # ffffffffc0202f00 <etext+0x1e4>
ffffffffc020058e:	bd3ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200592:	014b5613          	srli	a2,s6,0x14
ffffffffc0200596:	85da                	mv	a1,s6
ffffffffc0200598:	00003517          	auipc	a0,0x3
ffffffffc020059c:	98050513          	addi	a0,a0,-1664 # ffffffffc0202f18 <etext+0x1fc>
ffffffffc02005a0:	bc1ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02005a4:	008b05b3          	add	a1,s6,s0
ffffffffc02005a8:	15fd                	addi	a1,a1,-1
ffffffffc02005aa:	00003517          	auipc	a0,0x3
ffffffffc02005ae:	98e50513          	addi	a0,a0,-1650 # ffffffffc0202f38 <etext+0x21c>
ffffffffc02005b2:	bafff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005b6:	00003517          	auipc	a0,0x3
ffffffffc02005ba:	9d250513          	addi	a0,a0,-1582 # ffffffffc0202f88 <etext+0x26c>
        memory_base = mem_base;
ffffffffc02005be:	00007797          	auipc	a5,0x7
ffffffffc02005c2:	c087b523          	sd	s0,-1014(a5) # ffffffffc02071c8 <memory_base>
        memory_size = mem_size;
ffffffffc02005c6:	00007797          	auipc	a5,0x7
ffffffffc02005ca:	c167b523          	sd	s6,-1014(a5) # ffffffffc02071d0 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ce:	b3f5                	j	ffffffffc02003ba <dtb_init+0x186>

ffffffffc02005d0 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005d0:	00007517          	auipc	a0,0x7
ffffffffc02005d4:	bf853503          	ld	a0,-1032(a0) # ffffffffc02071c8 <memory_base>
ffffffffc02005d8:	8082                	ret

ffffffffc02005da <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005da:	00007517          	auipc	a0,0x7
ffffffffc02005de:	bf653503          	ld	a0,-1034(a0) # ffffffffc02071d0 <memory_size>
ffffffffc02005e2:	8082                	ret

ffffffffc02005e4 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005e4:	00007797          	auipc	a5,0x7
ffffffffc02005e8:	a3478793          	addi	a5,a5,-1484 # ffffffffc0207018 <free_area>
ffffffffc02005ec:	e79c                	sd	a5,8(a5)
ffffffffc02005ee:	e39c                	sd	a5,0(a5)
}

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005f0:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005f4:	8082                	ret

ffffffffc02005f6 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005f6:	00007517          	auipc	a0,0x7
ffffffffc02005fa:	a3256503          	lwu	a0,-1486(a0) # ffffffffc0207028 <free_area+0x10>
ffffffffc02005fe:	8082                	ret

ffffffffc0200600 <best_fit_check_range>:
best_fit_check_range(struct Page *base, size_t n) {
ffffffffc0200600:	1141                	addi	sp,sp,-16
ffffffffc0200602:	e406                	sd	ra,8(sp)
    assert(n > 0 && pages != NULL && npage > nbase);
ffffffffc0200604:	c5b9                	beqz	a1,ffffffffc0200652 <best_fit_check_range+0x52>
ffffffffc0200606:	00007797          	auipc	a5,0x7
ffffffffc020060a:	bda7b783          	ld	a5,-1062(a5) # ffffffffc02071e0 <pages>
ffffffffc020060e:	c3b1                	beqz	a5,ffffffffc0200652 <best_fit_check_range+0x52>
ffffffffc0200610:	00007717          	auipc	a4,0x7
ffffffffc0200614:	bc873703          	ld	a4,-1080(a4) # ffffffffc02071d8 <npage>
ffffffffc0200618:	00004697          	auipc	a3,0x4
ffffffffc020061c:	8f06b683          	ld	a3,-1808(a3) # ffffffffc0203f08 <nbase>
ffffffffc0200620:	02e6f963          	bgeu	a3,a4,ffffffffc0200652 <best_fit_check_range+0x52>
    assert(base >= pages && base < pages + (npage - nbase));
ffffffffc0200624:	04f56663          	bltu	a0,a5,ffffffffc0200670 <best_fit_check_range+0x70>
ffffffffc0200628:	8f15                	sub	a4,a4,a3
ffffffffc020062a:	00271693          	slli	a3,a4,0x2
ffffffffc020062e:	9736                	add	a4,a4,a3
ffffffffc0200630:	070e                	slli	a4,a4,0x3
ffffffffc0200632:	97ba                	add	a5,a5,a4
ffffffffc0200634:	02f57e63          	bgeu	a0,a5,ffffffffc0200670 <best_fit_check_range+0x70>
    assert(n <= (size_t)(pages + (npage - nbase) - base));
ffffffffc0200638:	8f89                	sub	a5,a5,a0
ffffffffc020063a:	878d                	srai	a5,a5,0x3
ffffffffc020063c:	00004717          	auipc	a4,0x4
ffffffffc0200640:	8c473703          	ld	a4,-1852(a4) # ffffffffc0203f00 <error_string+0x38>
ffffffffc0200644:	02e787b3          	mul	a5,a5,a4
ffffffffc0200648:	04b7e363          	bltu	a5,a1,ffffffffc020068e <best_fit_check_range+0x8e>
}
ffffffffc020064c:	60a2                	ld	ra,8(sp)
ffffffffc020064e:	0141                	addi	sp,sp,16
ffffffffc0200650:	8082                	ret
    assert(n > 0 && pages != NULL && npage > nbase);
ffffffffc0200652:	00003697          	auipc	a3,0x3
ffffffffc0200656:	94e68693          	addi	a3,a3,-1714 # ffffffffc0202fa0 <etext+0x284>
ffffffffc020065a:	00003617          	auipc	a2,0x3
ffffffffc020065e:	96e60613          	addi	a2,a2,-1682 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200662:	45c1                	li	a1,16
ffffffffc0200664:	00003517          	auipc	a0,0x3
ffffffffc0200668:	97c50513          	addi	a0,a0,-1668 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc020066c:	b6bff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(base >= pages && base < pages + (npage - nbase));
ffffffffc0200670:	00003697          	auipc	a3,0x3
ffffffffc0200674:	98868693          	addi	a3,a3,-1656 # ffffffffc0202ff8 <etext+0x2dc>
ffffffffc0200678:	00003617          	auipc	a2,0x3
ffffffffc020067c:	95060613          	addi	a2,a2,-1712 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200680:	45c5                	li	a1,17
ffffffffc0200682:	00003517          	auipc	a0,0x3
ffffffffc0200686:	95e50513          	addi	a0,a0,-1698 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc020068a:	b4dff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(n <= (size_t)(pages + (npage - nbase) - base));
ffffffffc020068e:	00003697          	auipc	a3,0x3
ffffffffc0200692:	99a68693          	addi	a3,a3,-1638 # ffffffffc0203028 <etext+0x30c>
ffffffffc0200696:	00003617          	auipc	a2,0x3
ffffffffc020069a:	93260613          	addi	a2,a2,-1742 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc020069e:	45c9                	li	a1,18
ffffffffc02006a0:	00003517          	auipc	a0,0x3
ffffffffc02006a4:	94050513          	addi	a0,a0,-1728 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc02006a8:	b2fff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02006ac <best_fit_insert_and_merge>:
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02006ac:	00007697          	auipc	a3,0x7
ffffffffc02006b0:	96c68693          	addi	a3,a3,-1684 # ffffffffc0207018 <free_area>
ffffffffc02006b4:	669c                	ld	a5,8(a3)
best_fit_insert_and_merge(struct Page *base) {
ffffffffc02006b6:	1141                	addi	sp,sp,-16
ffffffffc02006b8:	e406                	sd	ra,8(sp)
    while (next != &free_list && le2page(next, page_link) < base) {
ffffffffc02006ba:	00d79663          	bne	a5,a3,ffffffffc02006c6 <best_fit_insert_and_merge+0x1a>
ffffffffc02006be:	a069                	j	ffffffffc0200748 <best_fit_insert_and_merge+0x9c>
ffffffffc02006c0:	679c                	ld	a5,8(a5)
ffffffffc02006c2:	08d78363          	beq	a5,a3,ffffffffc0200748 <best_fit_insert_and_merge+0x9c>
ffffffffc02006c6:	fe878713          	addi	a4,a5,-24
ffffffffc02006ca:	fea76be3          	bltu	a4,a0,ffffffffc02006c0 <best_fit_insert_and_merge+0x14>
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02006ce:	6390                	ld	a2,0(a5)
    if (prev != &free_list) {
ffffffffc02006d0:	10d60663          	beq	a2,a3,ffffffffc02007dc <best_fit_insert_and_merge+0x130>
        assert(p + p->property <= base);
ffffffffc02006d4:	ff866803          	lwu	a6,-8(a2)
ffffffffc02006d8:	00281593          	slli	a1,a6,0x2
ffffffffc02006dc:	95c2                	add	a1,a1,a6
ffffffffc02006de:	058e                	slli	a1,a1,0x3
ffffffffc02006e0:	15a1                	addi	a1,a1,-24
ffffffffc02006e2:	95b2                	add	a1,a1,a2
ffffffffc02006e4:	08b56363          	bltu	a0,a1,ffffffffc020076a <best_fit_insert_and_merge+0xbe>
        assert(base + base->property <= p);
ffffffffc02006e8:	01056803          	lwu	a6,16(a0)
ffffffffc02006ec:	00281593          	slli	a1,a6,0x2
ffffffffc02006f0:	95c2                	add	a1,a1,a6
ffffffffc02006f2:	058e                	slli	a1,a1,0x3
ffffffffc02006f4:	95aa                	add	a1,a1,a0
ffffffffc02006f6:	12b76563          	bltu	a4,a1,ffffffffc0200820 <best_fit_insert_and_merge+0x174>
        assert(p + p->property <= base);
ffffffffc02006fa:	ff862803          	lw	a6,-8(a2)
    list_add_before(next, &base->page_link);
ffffffffc02006fe:	01850593          	addi	a1,a0,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200702:	e38c                	sd	a1,0(a5)
        assert(p + p->property <= base);
ffffffffc0200704:	02081893          	slli	a7,a6,0x20
ffffffffc0200708:	0208d893          	srli	a7,a7,0x20
ffffffffc020070c:	00289713          	slli	a4,a7,0x2
ffffffffc0200710:	e60c                	sd	a1,8(a2)
ffffffffc0200712:	9746                	add	a4,a4,a7
    elm->next = next;
ffffffffc0200714:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200716:	ed10                	sd	a2,24(a0)
ffffffffc0200718:	070e                	slli	a4,a4,0x3
        struct Page *p = le2page(prev, page_link);
ffffffffc020071a:	fe860893          	addi	a7,a2,-24
        if (p + p->property == base) {
ffffffffc020071e:	9746                	add	a4,a4,a7
ffffffffc0200720:	06e50563          	beq	a0,a4,ffffffffc020078a <best_fit_insert_and_merge+0xde>
    if (next != &free_list) {
ffffffffc0200724:	00d78f63          	beq	a5,a3,ffffffffc0200742 <best_fit_insert_and_merge+0x96>
ffffffffc0200728:	fe878713          	addi	a4,a5,-24
        if (base + base->property == p) {
ffffffffc020072c:	490c                	lw	a1,16(a0)
ffffffffc020072e:	02059613          	slli	a2,a1,0x20
ffffffffc0200732:	9201                	srli	a2,a2,0x20
ffffffffc0200734:	00261693          	slli	a3,a2,0x2
ffffffffc0200738:	96b2                	add	a3,a3,a2
ffffffffc020073a:	068e                	slli	a3,a3,0x3
ffffffffc020073c:	96aa                	add	a3,a3,a0
ffffffffc020073e:	06d70863          	beq	a4,a3,ffffffffc02007ae <best_fit_insert_and_merge+0x102>
}
ffffffffc0200742:	60a2                	ld	ra,8(sp)
ffffffffc0200744:	0141                	addi	sp,sp,16
ffffffffc0200746:	8082                	ret
    return listelm->prev;
ffffffffc0200748:	6290                	ld	a2,0(a3)
    if (prev != &free_list) {
ffffffffc020074a:	0cd60463          	beq	a2,a3,ffffffffc0200812 <best_fit_insert_and_merge+0x166>
        assert(p + p->property <= base);
ffffffffc020074e:	ff862803          	lw	a6,-8(a2)
ffffffffc0200752:	02081793          	slli	a5,a6,0x20
ffffffffc0200756:	9381                	srli	a5,a5,0x20
ffffffffc0200758:	00279713          	slli	a4,a5,0x2
ffffffffc020075c:	973e                	add	a4,a4,a5
ffffffffc020075e:	070e                	slli	a4,a4,0x3
ffffffffc0200760:	fe870793          	addi	a5,a4,-24
ffffffffc0200764:	97b2                	add	a5,a5,a2
ffffffffc0200766:	08f57b63          	bgeu	a0,a5,ffffffffc02007fc <best_fit_insert_and_merge+0x150>
ffffffffc020076a:	00003697          	auipc	a3,0x3
ffffffffc020076e:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0203058 <etext+0x33c>
ffffffffc0200772:	00003617          	auipc	a2,0x3
ffffffffc0200776:	85660613          	addi	a2,a2,-1962 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc020077a:	02200593          	li	a1,34
ffffffffc020077e:	00003517          	auipc	a0,0x3
ffffffffc0200782:	86250513          	addi	a0,a0,-1950 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200786:	a51ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
            p->property += base->property;
ffffffffc020078a:	01052303          	lw	t1,16(a0)
            ClearPageProperty(base);
ffffffffc020078e:	6518                	ld	a4,8(a0)
            p->property += base->property;
ffffffffc0200790:	0103083b          	addw	a6,t1,a6
ffffffffc0200794:	ff062c23          	sw	a6,-8(a2)
            ClearPageProperty(base);
ffffffffc0200798:	9b75                	andi	a4,a4,-3
ffffffffc020079a:	e518                	sd	a4,8(a0)
            base->property = 0;
ffffffffc020079c:	00052823          	sw	zero,16(a0)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02007a0:	e61c                	sd	a5,8(a2)
    next->prev = prev;
ffffffffc02007a2:	e390                	sd	a2,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02007a4:	f10c                	sd	a1,32(a0)
    return listelm->next;
ffffffffc02007a6:	661c                	ld	a5,8(a2)
    elm->prev = elm->next = elm;
ffffffffc02007a8:	ed0c                	sd	a1,24(a0)
            base = p;
ffffffffc02007aa:	8546                	mv	a0,a7
ffffffffc02007ac:	bfa5                	j	ffffffffc0200724 <best_fit_insert_and_merge+0x78>
            base->property += p->property;
ffffffffc02007ae:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc02007b2:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02007b6:	0007b803          	ld	a6,0(a5)
ffffffffc02007ba:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc02007bc:	9db5                	addw	a1,a1,a3
ffffffffc02007be:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc02007c0:	9b75                	andi	a4,a4,-3
ffffffffc02007c2:	fee7b823          	sd	a4,-16(a5)
            p->property = 0;
ffffffffc02007c6:	fe07ac23          	sw	zero,-8(a5)
    prev->next = next;
ffffffffc02007ca:	00c83423          	sd	a2,8(a6)
}
ffffffffc02007ce:	60a2                	ld	ra,8(sp)
    next->prev = prev;
ffffffffc02007d0:	01063023          	sd	a6,0(a2)
    elm->prev = elm->next = elm;
ffffffffc02007d4:	e79c                	sd	a5,8(a5)
ffffffffc02007d6:	e39c                	sd	a5,0(a5)
ffffffffc02007d8:	0141                	addi	sp,sp,16
ffffffffc02007da:	8082                	ret
        assert(base + base->property <= p);
ffffffffc02007dc:	01056583          	lwu	a1,16(a0)
ffffffffc02007e0:	00259613          	slli	a2,a1,0x2
ffffffffc02007e4:	962e                	add	a2,a2,a1
ffffffffc02007e6:	060e                	slli	a2,a2,0x3
ffffffffc02007e8:	962a                	add	a2,a2,a0
ffffffffc02007ea:	02c76b63          	bltu	a4,a2,ffffffffc0200820 <best_fit_insert_and_merge+0x174>
    list_add_before(next, &base->page_link);
ffffffffc02007ee:	01850613          	addi	a2,a0,24
    prev->next = next->prev = elm;
ffffffffc02007f2:	e390                	sd	a2,0(a5)
ffffffffc02007f4:	e690                	sd	a2,8(a3)
    elm->next = next;
ffffffffc02007f6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02007f8:	ed14                	sd	a3,24(a0)
    if (next != &free_list) {
ffffffffc02007fa:	bf0d                	j	ffffffffc020072c <best_fit_insert_and_merge+0x80>
    list_add_before(next, &base->page_link);
ffffffffc02007fc:	01850593          	addi	a1,a0,24
    prev->next = next->prev = elm;
ffffffffc0200800:	e60c                	sd	a1,8(a2)
ffffffffc0200802:	e28c                	sd	a1,0(a3)
    elm->next = next;
ffffffffc0200804:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc0200806:	ed10                	sd	a2,24(a0)
ffffffffc0200808:	00007797          	auipc	a5,0x7
ffffffffc020080c:	81078793          	addi	a5,a5,-2032 # ffffffffc0207018 <free_area>
ffffffffc0200810:	b729                	j	ffffffffc020071a <best_fit_insert_and_merge+0x6e>
ffffffffc0200812:	01850793          	addi	a5,a0,24
    prev->next = next->prev = elm;
ffffffffc0200816:	e29c                	sd	a5,0(a3)
ffffffffc0200818:	e69c                	sd	a5,8(a3)
    elm->next = next;
ffffffffc020081a:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc020081c:	ed14                	sd	a3,24(a0)
    if (next != &free_list) {
ffffffffc020081e:	b715                	j	ffffffffc0200742 <best_fit_insert_and_merge+0x96>
        assert(base + base->property <= p);
ffffffffc0200820:	00003697          	auipc	a3,0x3
ffffffffc0200824:	85068693          	addi	a3,a3,-1968 # ffffffffc0203070 <etext+0x354>
ffffffffc0200828:	00002617          	auipc	a2,0x2
ffffffffc020082c:	7a060613          	addi	a2,a2,1952 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200830:	02600593          	li	a1,38
ffffffffc0200834:	00002517          	auipc	a0,0x2
ffffffffc0200838:	7ac50513          	addi	a0,a0,1964 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc020083c:	99bff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0200840 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200840:	1101                	addi	sp,sp,-32
ffffffffc0200842:	e822                	sd	s0,16(sp)
ffffffffc0200844:	e426                	sd	s1,8(sp)
ffffffffc0200846:	842a                	mv	s0,a0
ffffffffc0200848:	84ae                	mv	s1,a1
ffffffffc020084a:	ec06                	sd	ra,24(sp)
    best_fit_check_range(base, n);
ffffffffc020084c:	db5ff0ef          	jal	ra,ffffffffc0200600 <best_fit_check_range>
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200850:	00249693          	slli	a3,s1,0x2
ffffffffc0200854:	96a6                	add	a3,a3,s1
ffffffffc0200856:	068e                	slli	a3,a3,0x3
ffffffffc0200858:	96a2                	add	a3,a3,s0
ffffffffc020085a:	02d40463          	beq	s0,a3,ffffffffc0200882 <best_fit_free_pages+0x42>
ffffffffc020085e:	87a2                	mv	a5,s0
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200860:	6798                	ld	a4,8(a5)
ffffffffc0200862:	8b0d                	andi	a4,a4,3
ffffffffc0200864:	e331                	bnez	a4,ffffffffc02008a8 <best_fit_free_pages+0x68>
        p->flags = 0;
ffffffffc0200866:	01878713          	addi	a4,a5,24
ffffffffc020086a:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc020086e:	0007a823          	sw	zero,16(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200872:	0007a023          	sw	zero,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0200876:	f398                	sd	a4,32(a5)
ffffffffc0200878:	ef98                	sd	a4,24(a5)
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc020087a:	02878793          	addi	a5,a5,40
ffffffffc020087e:	fed791e3          	bne	a5,a3,ffffffffc0200860 <best_fit_free_pages+0x20>
    SetPageProperty(base);
ffffffffc0200882:	6418                	ld	a4,8(s0)
    nr_free += n;
ffffffffc0200884:	00006697          	auipc	a3,0x6
ffffffffc0200888:	79468693          	addi	a3,a3,1940 # ffffffffc0207018 <free_area>
ffffffffc020088c:	4a9c                	lw	a5,16(a3)
    base->property = n;
ffffffffc020088e:	2481                	sext.w	s1,s1
    SetPageProperty(base);
ffffffffc0200890:	00276713          	ori	a4,a4,2
    base->property = n;
ffffffffc0200894:	c804                	sw	s1,16(s0)
    SetPageProperty(base);
ffffffffc0200896:	e418                	sd	a4,8(s0)
    nr_free += n;
ffffffffc0200898:	9cbd                	addw	s1,s1,a5
    best_fit_insert_and_merge(base);
ffffffffc020089a:	8522                	mv	a0,s0
}
ffffffffc020089c:	6442                	ld	s0,16(sp)
ffffffffc020089e:	60e2                	ld	ra,24(sp)
    nr_free += n;
ffffffffc02008a0:	ca84                	sw	s1,16(a3)
}
ffffffffc02008a2:	64a2                	ld	s1,8(sp)
ffffffffc02008a4:	6105                	addi	sp,sp,32
    best_fit_insert_and_merge(base);
ffffffffc02008a6:	b519                	j	ffffffffc02006ac <best_fit_insert_and_merge>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02008a8:	00002697          	auipc	a3,0x2
ffffffffc02008ac:	7e868693          	addi	a3,a3,2024 # ffffffffc0203090 <etext+0x374>
ffffffffc02008b0:	00002617          	auipc	a2,0x2
ffffffffc02008b4:	71860613          	addi	a2,a2,1816 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02008b8:	08000593          	li	a1,128
ffffffffc02008bc:	00002517          	auipc	a0,0x2
ffffffffc02008c0:	72450513          	addi	a0,a0,1828 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc02008c4:	913ff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02008c8 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02008c8:	c95d                	beqz	a0,ffffffffc020097e <best_fit_alloc_pages+0xb6>
    if (n > nr_free) {
ffffffffc02008ca:	00006597          	auipc	a1,0x6
ffffffffc02008ce:	74e58593          	addi	a1,a1,1870 # ffffffffc0207018 <free_area>
ffffffffc02008d2:	0105a883          	lw	a7,16(a1)
ffffffffc02008d6:	862a                	mv	a2,a0
ffffffffc02008d8:	02089793          	slli	a5,a7,0x20
ffffffffc02008dc:	9381                	srli	a5,a5,0x20
ffffffffc02008de:	08a7ee63          	bltu	a5,a0,ffffffffc020097a <best_fit_alloc_pages+0xb2>
    return listelm->next;
ffffffffc02008e2:	659c                	ld	a5,8(a1)
    struct Page *best = NULL;
ffffffffc02008e4:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008e6:	08b78963          	beq	a5,a1,ffffffffc0200978 <best_fit_alloc_pages+0xb0>
        if (p->property >= n &&
ffffffffc02008ea:	ff87a703          	lw	a4,-8(a5)
ffffffffc02008ee:	02071693          	slli	a3,a4,0x20
ffffffffc02008f2:	9281                	srli	a3,a3,0x20
ffffffffc02008f4:	00c6eb63          	bltu	a3,a2,ffffffffc020090a <best_fit_alloc_pages+0x42>
ffffffffc02008f8:	c509                	beqz	a0,ffffffffc0200902 <best_fit_alloc_pages+0x3a>
            (best == NULL || p->property < best->property)) {
ffffffffc02008fa:	01052803          	lw	a6,16(a0)
ffffffffc02008fe:	01077663          	bgeu	a4,a6,ffffffffc020090a <best_fit_alloc_pages+0x42>
        struct Page *p = le2page(le, page_link);
ffffffffc0200902:	fe878513          	addi	a0,a5,-24
            if (p->property == n) {
ffffffffc0200906:	00c68663          	beq	a3,a2,ffffffffc0200912 <best_fit_alloc_pages+0x4a>
ffffffffc020090a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020090c:	fcb79fe3          	bne	a5,a1,ffffffffc02008ea <best_fit_alloc_pages+0x22>
    if (best == NULL) {
ffffffffc0200910:	c525                	beqz	a0,ffffffffc0200978 <best_fit_alloc_pages+0xb0>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200912:	02053803          	ld	a6,32(a0)
    return listelm->prev;
ffffffffc0200916:	6d18                	ld	a4,24(a0)
    size_t block_pages = best->property;
ffffffffc0200918:	4914                	lw	a3,16(a0)
    list_del_init(&best->page_link);
ffffffffc020091a:	01850793          	addi	a5,a0,24
    prev->next = next;
ffffffffc020091e:	01073423          	sd	a6,8(a4)
    next->prev = prev;
ffffffffc0200922:	00e83023          	sd	a4,0(a6)
    elm->prev = elm->next = elm;
ffffffffc0200926:	f11c                	sd	a5,32(a0)
ffffffffc0200928:	ed1c                	sd	a5,24(a0)
    size_t block_pages = best->property;
ffffffffc020092a:	02069793          	slli	a5,a3,0x20
ffffffffc020092e:	9381                	srli	a5,a5,0x20
        rest->property = block_pages - n;
ffffffffc0200930:	0006081b          	sext.w	a6,a2
    if (block_pages > n) {
ffffffffc0200934:	02f67863          	bgeu	a2,a5,ffffffffc0200964 <best_fit_alloc_pages+0x9c>
        struct Page *rest = best + n;
ffffffffc0200938:	00261793          	slli	a5,a2,0x2
ffffffffc020093c:	97b2                	add	a5,a5,a2
ffffffffc020093e:	078e                	slli	a5,a5,0x3
ffffffffc0200940:	97aa                	add	a5,a5,a0
        SetPageProperty(rest);
ffffffffc0200942:	6790                	ld	a2,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200944:	00873303          	ld	t1,8(a4)
        rest->property = block_pages - n;
ffffffffc0200948:	410686bb          	subw	a3,a3,a6
        SetPageProperty(rest);
ffffffffc020094c:	00266613          	ori	a2,a2,2
        rest->property = block_pages - n;
ffffffffc0200950:	cb94                	sw	a3,16(a5)
        SetPageProperty(rest);
ffffffffc0200952:	e790                	sd	a2,8(a5)
        list_add(prev, &rest->page_link);
ffffffffc0200954:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200958:	00d33023          	sd	a3,0(t1)
ffffffffc020095c:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc020095e:	0267b023          	sd	t1,32(a5)
    elm->prev = prev;
ffffffffc0200962:	ef98                	sd	a4,24(a5)
    ClearPageProperty(best);
ffffffffc0200964:	651c                	ld	a5,8(a0)
    best->property = 0;
ffffffffc0200966:	00052823          	sw	zero,16(a0)
    nr_free -= n;
ffffffffc020096a:	410888bb          	subw	a7,a7,a6
    ClearPageProperty(best);
ffffffffc020096e:	9bf5                	andi	a5,a5,-3
ffffffffc0200970:	e51c                	sd	a5,8(a0)
    nr_free -= n;
ffffffffc0200972:	0115a823          	sw	a7,16(a1)
    return best;
ffffffffc0200976:	8082                	ret
}
ffffffffc0200978:	8082                	ret
        return NULL;
ffffffffc020097a:	4501                	li	a0,0
ffffffffc020097c:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc020097e:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200980:	00002697          	auipc	a3,0x2
ffffffffc0200984:	73868693          	addi	a3,a3,1848 # ffffffffc02030b8 <etext+0x39c>
ffffffffc0200988:	00002617          	auipc	a2,0x2
ffffffffc020098c:	64060613          	addi	a2,a2,1600 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200990:	05800593          	li	a1,88
ffffffffc0200994:	00002517          	auipc	a0,0x2
ffffffffc0200998:	64c50513          	addi	a0,a0,1612 # ffffffffc0202fe0 <etext+0x2c4>
best_fit_alloc_pages(size_t n) {
ffffffffc020099c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020099e:	839ff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02009a2 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02009a2:	1101                	addi	sp,sp,-32
ffffffffc02009a4:	e822                	sd	s0,16(sp)
ffffffffc02009a6:	e426                	sd	s1,8(sp)
ffffffffc02009a8:	842a                	mv	s0,a0
ffffffffc02009aa:	84ae                	mv	s1,a1
ffffffffc02009ac:	ec06                	sd	ra,24(sp)
    best_fit_check_range(base, n);
ffffffffc02009ae:	c53ff0ef          	jal	ra,ffffffffc0200600 <best_fit_check_range>
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc02009b2:	00249693          	slli	a3,s1,0x2
ffffffffc02009b6:	96a6                	add	a3,a3,s1
ffffffffc02009b8:	068e                	slli	a3,a3,0x3
ffffffffc02009ba:	96a2                	add	a3,a3,s0
ffffffffc02009bc:	02d40463          	beq	s0,a3,ffffffffc02009e4 <best_fit_init_memmap+0x42>
ffffffffc02009c0:	87a2                	mv	a5,s0
        assert(PageReserved(p));
ffffffffc02009c2:	6798                	ld	a4,8(a5)
ffffffffc02009c4:	8b05                	andi	a4,a4,1
ffffffffc02009c6:	c331                	beqz	a4,ffffffffc0200a0a <best_fit_init_memmap+0x68>
        p->flags = p->property = 0;
ffffffffc02009c8:	01878713          	addi	a4,a5,24
ffffffffc02009cc:	0007a823          	sw	zero,16(a5)
ffffffffc02009d0:	0007b423          	sd	zero,8(a5)
ffffffffc02009d4:	0007a023          	sw	zero,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02009d8:	f398                	sd	a4,32(a5)
ffffffffc02009da:	ef98                	sd	a4,24(a5)
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc02009dc:	02878793          	addi	a5,a5,40
ffffffffc02009e0:	fed791e3          	bne	a5,a3,ffffffffc02009c2 <best_fit_init_memmap+0x20>
    SetPageProperty(base);
ffffffffc02009e4:	6418                	ld	a4,8(s0)
    nr_free += n;
ffffffffc02009e6:	00006697          	auipc	a3,0x6
ffffffffc02009ea:	63268693          	addi	a3,a3,1586 # ffffffffc0207018 <free_area>
ffffffffc02009ee:	4a9c                	lw	a5,16(a3)
    base->property = n;
ffffffffc02009f0:	2481                	sext.w	s1,s1
    SetPageProperty(base);
ffffffffc02009f2:	00276713          	ori	a4,a4,2
    base->property = n;
ffffffffc02009f6:	c804                	sw	s1,16(s0)
    SetPageProperty(base);
ffffffffc02009f8:	e418                	sd	a4,8(s0)
    nr_free += n;
ffffffffc02009fa:	9cbd                	addw	s1,s1,a5
    best_fit_insert_and_merge(base);
ffffffffc02009fc:	8522                	mv	a0,s0
}
ffffffffc02009fe:	6442                	ld	s0,16(sp)
ffffffffc0200a00:	60e2                	ld	ra,24(sp)
    nr_free += n;
ffffffffc0200a02:	ca84                	sw	s1,16(a3)
}
ffffffffc0200a04:	64a2                	ld	s1,8(sp)
ffffffffc0200a06:	6105                	addi	sp,sp,32
    best_fit_insert_and_merge(base);
ffffffffc0200a08:	b155                	j	ffffffffc02006ac <best_fit_insert_and_merge>
        assert(PageReserved(p));
ffffffffc0200a0a:	00002697          	auipc	a3,0x2
ffffffffc0200a0e:	6b668693          	addi	a3,a3,1718 # ffffffffc02030c0 <etext+0x3a4>
ffffffffc0200a12:	00002617          	auipc	a2,0x2
ffffffffc0200a16:	5b660613          	addi	a2,a2,1462 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200a1a:	04a00593          	li	a1,74
ffffffffc0200a1e:	00002517          	auipc	a0,0x2
ffffffffc0200a22:	5c250513          	addi	a0,a0,1474 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200a26:	fb0ff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0200a2a <best_fit_check>:
    free_page(p1);
    free_page(p2);
}

static void
best_fit_check(void) {
ffffffffc0200a2a:	715d                	addi	sp,sp,-80
ffffffffc0200a2c:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200a2e:	00006417          	auipc	s0,0x6
ffffffffc0200a32:	5ea40413          	addi	s0,s0,1514 # ffffffffc0207018 <free_area>
ffffffffc0200a36:	641c                	ld	a5,8(s0)
ffffffffc0200a38:	e486                	sd	ra,72(sp)
ffffffffc0200a3a:	fc26                	sd	s1,56(sp)
ffffffffc0200a3c:	f84a                	sd	s2,48(sp)
ffffffffc0200a3e:	f44e                	sd	s3,40(sp)
ffffffffc0200a40:	f052                	sd	s4,32(sp)
ffffffffc0200a42:	ec56                	sd	s5,24(sp)
ffffffffc0200a44:	e85a                	sd	s6,16(sp)
ffffffffc0200a46:	e45e                	sd	s7,8(sp)
ffffffffc0200a48:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200a4a:	26878963          	beq	a5,s0,ffffffffc0200cbc <best_fit_check+0x292>
    int count = 0, total = 0;
ffffffffc0200a4e:	4481                	li	s1,0
ffffffffc0200a50:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200a52:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200a56:	8b09                	andi	a4,a4,2
ffffffffc0200a58:	26070663          	beqz	a4,ffffffffc0200cc4 <best_fit_check+0x29a>
        count++, total += p->property;
ffffffffc0200a5c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200a60:	679c                	ld	a5,8(a5)
ffffffffc0200a62:	2905                	addiw	s2,s2,1
ffffffffc0200a64:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200a66:	fe8796e3          	bne	a5,s0,ffffffffc0200a52 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200a6a:	89a6                	mv	s3,s1
ffffffffc0200a6c:	690000ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0200a70:	33351a63          	bne	a0,s3,ffffffffc0200da4 <best_fit_check+0x37a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a74:	4505                	li	a0,1
ffffffffc0200a76:	66e000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200a7a:	8a2a                	mv	s4,a0
ffffffffc0200a7c:	36050463          	beqz	a0,ffffffffc0200de4 <best_fit_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a80:	4505                	li	a0,1
ffffffffc0200a82:	662000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200a86:	89aa                	mv	s3,a0
ffffffffc0200a88:	32050e63          	beqz	a0,ffffffffc0200dc4 <best_fit_check+0x39a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a8c:	4505                	li	a0,1
ffffffffc0200a8e:	656000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200a92:	8aaa                	mv	s5,a0
ffffffffc0200a94:	2c050863          	beqz	a0,ffffffffc0200d64 <best_fit_check+0x33a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200a98:	253a0663          	beq	s4,s3,ffffffffc0200ce4 <best_fit_check+0x2ba>
ffffffffc0200a9c:	24aa0463          	beq	s4,a0,ffffffffc0200ce4 <best_fit_check+0x2ba>
ffffffffc0200aa0:	24a98263          	beq	s3,a0,ffffffffc0200ce4 <best_fit_check+0x2ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200aa4:	000a2783          	lw	a5,0(s4)
ffffffffc0200aa8:	24079e63          	bnez	a5,ffffffffc0200d04 <best_fit_check+0x2da>
ffffffffc0200aac:	0009a783          	lw	a5,0(s3)
ffffffffc0200ab0:	24079a63          	bnez	a5,ffffffffc0200d04 <best_fit_check+0x2da>
ffffffffc0200ab4:	411c                	lw	a5,0(a0)
ffffffffc0200ab6:	24079763          	bnez	a5,ffffffffc0200d04 <best_fit_check+0x2da>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200aba:	00006797          	auipc	a5,0x6
ffffffffc0200abe:	7267b783          	ld	a5,1830(a5) # ffffffffc02071e0 <pages>
ffffffffc0200ac2:	40fa0733          	sub	a4,s4,a5
ffffffffc0200ac6:	870d                	srai	a4,a4,0x3
ffffffffc0200ac8:	00003597          	auipc	a1,0x3
ffffffffc0200acc:	4385b583          	ld	a1,1080(a1) # ffffffffc0203f00 <error_string+0x38>
ffffffffc0200ad0:	02b70733          	mul	a4,a4,a1
ffffffffc0200ad4:	00003617          	auipc	a2,0x3
ffffffffc0200ad8:	43463603          	ld	a2,1076(a2) # ffffffffc0203f08 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200adc:	00006697          	auipc	a3,0x6
ffffffffc0200ae0:	6fc6b683          	ld	a3,1788(a3) # ffffffffc02071d8 <npage>
ffffffffc0200ae4:	06b2                	slli	a3,a3,0xc
ffffffffc0200ae6:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ae8:	0732                	slli	a4,a4,0xc
ffffffffc0200aea:	22d77d63          	bgeu	a4,a3,ffffffffc0200d24 <best_fit_check+0x2fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200aee:	40f98733          	sub	a4,s3,a5
ffffffffc0200af2:	870d                	srai	a4,a4,0x3
ffffffffc0200af4:	02b70733          	mul	a4,a4,a1
ffffffffc0200af8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200afa:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200afc:	3ed77463          	bgeu	a4,a3,ffffffffc0200ee4 <best_fit_check+0x4ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b00:	40f507b3          	sub	a5,a0,a5
ffffffffc0200b04:	878d                	srai	a5,a5,0x3
ffffffffc0200b06:	02b787b3          	mul	a5,a5,a1
ffffffffc0200b0a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200b0c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b0e:	3ad7fb63          	bgeu	a5,a3,ffffffffc0200ec4 <best_fit_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200b12:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200b14:	00043c03          	ld	s8,0(s0)
ffffffffc0200b18:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200b1c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200b20:	e400                	sd	s0,8(s0)
ffffffffc0200b22:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200b24:	00006797          	auipc	a5,0x6
ffffffffc0200b28:	5007a223          	sw	zero,1284(a5) # ffffffffc0207028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200b2c:	5b8000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200b30:	36051a63          	bnez	a0,ffffffffc0200ea4 <best_fit_check+0x47a>
    free_page(p0);
ffffffffc0200b34:	4585                	li	a1,1
ffffffffc0200b36:	8552                	mv	a0,s4
ffffffffc0200b38:	5b8000ef          	jal	ra,ffffffffc02010f0 <free_pages>
    free_page(p1);
ffffffffc0200b3c:	4585                	li	a1,1
ffffffffc0200b3e:	854e                	mv	a0,s3
ffffffffc0200b40:	5b0000ef          	jal	ra,ffffffffc02010f0 <free_pages>
    free_page(p2);
ffffffffc0200b44:	4585                	li	a1,1
ffffffffc0200b46:	8556                	mv	a0,s5
ffffffffc0200b48:	5a8000ef          	jal	ra,ffffffffc02010f0 <free_pages>
    assert(nr_free == 3);
ffffffffc0200b4c:	4818                	lw	a4,16(s0)
ffffffffc0200b4e:	478d                	li	a5,3
ffffffffc0200b50:	32f71a63          	bne	a4,a5,ffffffffc0200e84 <best_fit_check+0x45a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200b54:	4505                	li	a0,1
ffffffffc0200b56:	58e000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200b5a:	89aa                	mv	s3,a0
ffffffffc0200b5c:	30050463          	beqz	a0,ffffffffc0200e64 <best_fit_check+0x43a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200b60:	4505                	li	a0,1
ffffffffc0200b62:	582000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200b66:	8aaa                	mv	s5,a0
ffffffffc0200b68:	2c050e63          	beqz	a0,ffffffffc0200e44 <best_fit_check+0x41a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b6c:	4505                	li	a0,1
ffffffffc0200b6e:	576000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200b72:	8a2a                	mv	s4,a0
ffffffffc0200b74:	2a050863          	beqz	a0,ffffffffc0200e24 <best_fit_check+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc0200b78:	4505                	li	a0,1
ffffffffc0200b7a:	56a000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200b7e:	28051363          	bnez	a0,ffffffffc0200e04 <best_fit_check+0x3da>
    free_page(p0);
ffffffffc0200b82:	4585                	li	a1,1
ffffffffc0200b84:	854e                	mv	a0,s3
ffffffffc0200b86:	56a000ef          	jal	ra,ffffffffc02010f0 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200b8a:	641c                	ld	a5,8(s0)
ffffffffc0200b8c:	1a878c63          	beq	a5,s0,ffffffffc0200d44 <best_fit_check+0x31a>
    assert((p = alloc_page()) == p0);
ffffffffc0200b90:	4505                	li	a0,1
ffffffffc0200b92:	552000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200b96:	52a99763          	bne	s3,a0,ffffffffc02010c4 <best_fit_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc0200b9a:	4505                	li	a0,1
ffffffffc0200b9c:	548000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200ba0:	50051263          	bnez	a0,ffffffffc02010a4 <best_fit_check+0x67a>
    assert(nr_free == 0);
ffffffffc0200ba4:	481c                	lw	a5,16(s0)
ffffffffc0200ba6:	4c079f63          	bnez	a5,ffffffffc0201084 <best_fit_check+0x65a>
    free_page(p);
ffffffffc0200baa:	854e                	mv	a0,s3
ffffffffc0200bac:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200bae:	01843023          	sd	s8,0(s0)
ffffffffc0200bb2:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200bb6:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200bba:	536000ef          	jal	ra,ffffffffc02010f0 <free_pages>
    free_page(p1);
ffffffffc0200bbe:	4585                	li	a1,1
ffffffffc0200bc0:	8556                	mv	a0,s5
ffffffffc0200bc2:	52e000ef          	jal	ra,ffffffffc02010f0 <free_pages>
    free_page(p2);
ffffffffc0200bc6:	4585                	li	a1,1
ffffffffc0200bc8:	8552                	mv	a0,s4
ffffffffc0200bca:	526000ef          	jal	ra,ffffffffc02010f0 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200bce:	4515                	li	a0,5
ffffffffc0200bd0:	514000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200bd4:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200bd6:	48050763          	beqz	a0,ffffffffc0201064 <best_fit_check+0x63a>
    assert(!PageProperty(p0));
ffffffffc0200bda:	651c                	ld	a5,8(a0)
ffffffffc0200bdc:	8b89                	andi	a5,a5,2
ffffffffc0200bde:	46079363          	bnez	a5,ffffffffc0201044 <best_fit_check+0x61a>
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200be2:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200be4:	00043b03          	ld	s6,0(s0)
ffffffffc0200be8:	00843a83          	ld	s5,8(s0)
ffffffffc0200bec:	e000                	sd	s0,0(s0)
ffffffffc0200bee:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200bf0:	4f4000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200bf4:	42051863          	bnez	a0,ffffffffc0201024 <best_fit_check+0x5fa>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200bf8:	4589                	li	a1,2
ffffffffc0200bfa:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200bfe:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200c02:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200c06:	00006797          	auipc	a5,0x6
ffffffffc0200c0a:	4207a123          	sw	zero,1058(a5) # ffffffffc0207028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200c0e:	4e2000ef          	jal	ra,ffffffffc02010f0 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200c12:	8562                	mv	a0,s8
ffffffffc0200c14:	4585                	li	a1,1
ffffffffc0200c16:	4da000ef          	jal	ra,ffffffffc02010f0 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c1a:	4511                	li	a0,4
ffffffffc0200c1c:	4c8000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200c20:	3e051263          	bnez	a0,ffffffffc0201004 <best_fit_check+0x5da>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c24:	0309b783          	ld	a5,48(s3)
ffffffffc0200c28:	8b89                	andi	a5,a5,2
ffffffffc0200c2a:	3a078d63          	beqz	a5,ffffffffc0200fe4 <best_fit_check+0x5ba>
ffffffffc0200c2e:	0389a703          	lw	a4,56(s3)
ffffffffc0200c32:	4789                	li	a5,2
ffffffffc0200c34:	3af71863          	bne	a4,a5,ffffffffc0200fe4 <best_fit_check+0x5ba>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c38:	4505                	li	a0,1
ffffffffc0200c3a:	4aa000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200c3e:	8a2a                	mv	s4,a0
ffffffffc0200c40:	38050263          	beqz	a0,ffffffffc0200fc4 <best_fit_check+0x59a>
    assert(alloc_pages(2) != NULL);
ffffffffc0200c44:	4509                	li	a0,2
ffffffffc0200c46:	49e000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200c4a:	34050d63          	beqz	a0,ffffffffc0200fa4 <best_fit_check+0x57a>
    assert(p0 + 4 == p1);
ffffffffc0200c4e:	334c1b63          	bne	s8,s4,ffffffffc0200f84 <best_fit_check+0x55a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200c52:	854e                	mv	a0,s3
ffffffffc0200c54:	4595                	li	a1,5
ffffffffc0200c56:	49a000ef          	jal	ra,ffffffffc02010f0 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200c5a:	4515                	li	a0,5
ffffffffc0200c5c:	488000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200c60:	89aa                	mv	s3,a0
ffffffffc0200c62:	30050163          	beqz	a0,ffffffffc0200f64 <best_fit_check+0x53a>
    assert(alloc_page() == NULL);
ffffffffc0200c66:	4505                	li	a0,1
ffffffffc0200c68:	47c000ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc0200c6c:	2c051c63          	bnez	a0,ffffffffc0200f44 <best_fit_check+0x51a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200c70:	481c                	lw	a5,16(s0)
ffffffffc0200c72:	2a079963          	bnez	a5,ffffffffc0200f24 <best_fit_check+0x4fa>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200c76:	4595                	li	a1,5
ffffffffc0200c78:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200c7a:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200c7e:	01643023          	sd	s6,0(s0)
ffffffffc0200c82:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200c86:	46a000ef          	jal	ra,ffffffffc02010f0 <free_pages>
    return listelm->next;
ffffffffc0200c8a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c8c:	00878963          	beq	a5,s0,ffffffffc0200c9e <best_fit_check+0x274>
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0200c90:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c94:	679c                	ld	a5,8(a5)
ffffffffc0200c96:	397d                	addiw	s2,s2,-1
ffffffffc0200c98:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c9a:	fe879be3          	bne	a5,s0,ffffffffc0200c90 <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc0200c9e:	26091363          	bnez	s2,ffffffffc0200f04 <best_fit_check+0x4da>
    assert(total == 0);
ffffffffc0200ca2:	e0ed                	bnez	s1,ffffffffc0200d84 <best_fit_check+0x35a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
}
ffffffffc0200ca4:	60a6                	ld	ra,72(sp)
ffffffffc0200ca6:	6406                	ld	s0,64(sp)
ffffffffc0200ca8:	74e2                	ld	s1,56(sp)
ffffffffc0200caa:	7942                	ld	s2,48(sp)
ffffffffc0200cac:	79a2                	ld	s3,40(sp)
ffffffffc0200cae:	7a02                	ld	s4,32(sp)
ffffffffc0200cb0:	6ae2                	ld	s5,24(sp)
ffffffffc0200cb2:	6b42                	ld	s6,16(sp)
ffffffffc0200cb4:	6ba2                	ld	s7,8(sp)
ffffffffc0200cb6:	6c02                	ld	s8,0(sp)
ffffffffc0200cb8:	6161                	addi	sp,sp,80
ffffffffc0200cba:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cbc:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200cbe:	4481                	li	s1,0
ffffffffc0200cc0:	4901                	li	s2,0
ffffffffc0200cc2:	b36d                	j	ffffffffc0200a6c <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200cc4:	00002697          	auipc	a3,0x2
ffffffffc0200cc8:	40c68693          	addi	a3,a3,1036 # ffffffffc02030d0 <etext+0x3b4>
ffffffffc0200ccc:	00002617          	auipc	a2,0x2
ffffffffc0200cd0:	2fc60613          	addi	a2,a2,764 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200cd4:	0cd00593          	li	a1,205
ffffffffc0200cd8:	00002517          	auipc	a0,0x2
ffffffffc0200cdc:	30850513          	addi	a0,a0,776 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200ce0:	cf6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ce4:	00002697          	auipc	a3,0x2
ffffffffc0200ce8:	47c68693          	addi	a3,a3,1148 # ffffffffc0203160 <etext+0x444>
ffffffffc0200cec:	00002617          	auipc	a2,0x2
ffffffffc0200cf0:	2dc60613          	addi	a2,a2,732 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200cf4:	09b00593          	li	a1,155
ffffffffc0200cf8:	00002517          	auipc	a0,0x2
ffffffffc0200cfc:	2e850513          	addi	a0,a0,744 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200d00:	cd6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d04:	00002697          	auipc	a3,0x2
ffffffffc0200d08:	48468693          	addi	a3,a3,1156 # ffffffffc0203188 <etext+0x46c>
ffffffffc0200d0c:	00002617          	auipc	a2,0x2
ffffffffc0200d10:	2bc60613          	addi	a2,a2,700 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200d14:	09c00593          	li	a1,156
ffffffffc0200d18:	00002517          	auipc	a0,0x2
ffffffffc0200d1c:	2c850513          	addi	a0,a0,712 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200d20:	cb6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d24:	00002697          	auipc	a3,0x2
ffffffffc0200d28:	4a468693          	addi	a3,a3,1188 # ffffffffc02031c8 <etext+0x4ac>
ffffffffc0200d2c:	00002617          	auipc	a2,0x2
ffffffffc0200d30:	29c60613          	addi	a2,a2,668 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200d34:	09e00593          	li	a1,158
ffffffffc0200d38:	00002517          	auipc	a0,0x2
ffffffffc0200d3c:	2a850513          	addi	a0,a0,680 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200d40:	c96ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200d44:	00002697          	auipc	a3,0x2
ffffffffc0200d48:	50c68693          	addi	a3,a3,1292 # ffffffffc0203250 <etext+0x534>
ffffffffc0200d4c:	00002617          	auipc	a2,0x2
ffffffffc0200d50:	27c60613          	addi	a2,a2,636 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200d54:	0b700593          	li	a1,183
ffffffffc0200d58:	00002517          	auipc	a0,0x2
ffffffffc0200d5c:	28850513          	addi	a0,a0,648 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200d60:	c76ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d64:	00002697          	auipc	a3,0x2
ffffffffc0200d68:	3dc68693          	addi	a3,a3,988 # ffffffffc0203140 <etext+0x424>
ffffffffc0200d6c:	00002617          	auipc	a2,0x2
ffffffffc0200d70:	25c60613          	addi	a2,a2,604 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200d74:	09900593          	li	a1,153
ffffffffc0200d78:	00002517          	auipc	a0,0x2
ffffffffc0200d7c:	26850513          	addi	a0,a0,616 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200d80:	c56ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(total == 0);
ffffffffc0200d84:	00002697          	auipc	a3,0x2
ffffffffc0200d88:	5fc68693          	addi	a3,a3,1532 # ffffffffc0203380 <etext+0x664>
ffffffffc0200d8c:	00002617          	auipc	a2,0x2
ffffffffc0200d90:	23c60613          	addi	a2,a2,572 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200d94:	10f00593          	li	a1,271
ffffffffc0200d98:	00002517          	auipc	a0,0x2
ffffffffc0200d9c:	24850513          	addi	a0,a0,584 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200da0:	c36ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200da4:	00002697          	auipc	a3,0x2
ffffffffc0200da8:	33c68693          	addi	a3,a3,828 # ffffffffc02030e0 <etext+0x3c4>
ffffffffc0200dac:	00002617          	auipc	a2,0x2
ffffffffc0200db0:	21c60613          	addi	a2,a2,540 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200db4:	0d000593          	li	a1,208
ffffffffc0200db8:	00002517          	auipc	a0,0x2
ffffffffc0200dbc:	22850513          	addi	a0,a0,552 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200dc0:	c16ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200dc4:	00002697          	auipc	a3,0x2
ffffffffc0200dc8:	35c68693          	addi	a3,a3,860 # ffffffffc0203120 <etext+0x404>
ffffffffc0200dcc:	00002617          	auipc	a2,0x2
ffffffffc0200dd0:	1fc60613          	addi	a2,a2,508 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200dd4:	09800593          	li	a1,152
ffffffffc0200dd8:	00002517          	auipc	a0,0x2
ffffffffc0200ddc:	20850513          	addi	a0,a0,520 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200de0:	bf6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200de4:	00002697          	auipc	a3,0x2
ffffffffc0200de8:	31c68693          	addi	a3,a3,796 # ffffffffc0203100 <etext+0x3e4>
ffffffffc0200dec:	00002617          	auipc	a2,0x2
ffffffffc0200df0:	1dc60613          	addi	a2,a2,476 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200df4:	09700593          	li	a1,151
ffffffffc0200df8:	00002517          	auipc	a0,0x2
ffffffffc0200dfc:	1e850513          	addi	a0,a0,488 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200e00:	bd6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e04:	00002697          	auipc	a3,0x2
ffffffffc0200e08:	42468693          	addi	a3,a3,1060 # ffffffffc0203228 <etext+0x50c>
ffffffffc0200e0c:	00002617          	auipc	a2,0x2
ffffffffc0200e10:	1bc60613          	addi	a2,a2,444 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200e14:	0b400593          	li	a1,180
ffffffffc0200e18:	00002517          	auipc	a0,0x2
ffffffffc0200e1c:	1c850513          	addi	a0,a0,456 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200e20:	bb6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e24:	00002697          	auipc	a3,0x2
ffffffffc0200e28:	31c68693          	addi	a3,a3,796 # ffffffffc0203140 <etext+0x424>
ffffffffc0200e2c:	00002617          	auipc	a2,0x2
ffffffffc0200e30:	19c60613          	addi	a2,a2,412 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200e34:	0b200593          	li	a1,178
ffffffffc0200e38:	00002517          	auipc	a0,0x2
ffffffffc0200e3c:	1a850513          	addi	a0,a0,424 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200e40:	b96ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e44:	00002697          	auipc	a3,0x2
ffffffffc0200e48:	2dc68693          	addi	a3,a3,732 # ffffffffc0203120 <etext+0x404>
ffffffffc0200e4c:	00002617          	auipc	a2,0x2
ffffffffc0200e50:	17c60613          	addi	a2,a2,380 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200e54:	0b100593          	li	a1,177
ffffffffc0200e58:	00002517          	auipc	a0,0x2
ffffffffc0200e5c:	18850513          	addi	a0,a0,392 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200e60:	b76ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e64:	00002697          	auipc	a3,0x2
ffffffffc0200e68:	29c68693          	addi	a3,a3,668 # ffffffffc0203100 <etext+0x3e4>
ffffffffc0200e6c:	00002617          	auipc	a2,0x2
ffffffffc0200e70:	15c60613          	addi	a2,a2,348 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200e74:	0b000593          	li	a1,176
ffffffffc0200e78:	00002517          	auipc	a0,0x2
ffffffffc0200e7c:	16850513          	addi	a0,a0,360 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200e80:	b56ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free == 3);
ffffffffc0200e84:	00002697          	auipc	a3,0x2
ffffffffc0200e88:	3bc68693          	addi	a3,a3,956 # ffffffffc0203240 <etext+0x524>
ffffffffc0200e8c:	00002617          	auipc	a2,0x2
ffffffffc0200e90:	13c60613          	addi	a2,a2,316 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200e94:	0ae00593          	li	a1,174
ffffffffc0200e98:	00002517          	auipc	a0,0x2
ffffffffc0200e9c:	14850513          	addi	a0,a0,328 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200ea0:	b36ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ea4:	00002697          	auipc	a3,0x2
ffffffffc0200ea8:	38468693          	addi	a3,a3,900 # ffffffffc0203228 <etext+0x50c>
ffffffffc0200eac:	00002617          	auipc	a2,0x2
ffffffffc0200eb0:	11c60613          	addi	a2,a2,284 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200eb4:	0a900593          	li	a1,169
ffffffffc0200eb8:	00002517          	auipc	a0,0x2
ffffffffc0200ebc:	12850513          	addi	a0,a0,296 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200ec0:	b16ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ec4:	00002697          	auipc	a3,0x2
ffffffffc0200ec8:	34468693          	addi	a3,a3,836 # ffffffffc0203208 <etext+0x4ec>
ffffffffc0200ecc:	00002617          	auipc	a2,0x2
ffffffffc0200ed0:	0fc60613          	addi	a2,a2,252 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200ed4:	0a000593          	li	a1,160
ffffffffc0200ed8:	00002517          	auipc	a0,0x2
ffffffffc0200edc:	10850513          	addi	a0,a0,264 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200ee0:	af6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200ee4:	00002697          	auipc	a3,0x2
ffffffffc0200ee8:	30468693          	addi	a3,a3,772 # ffffffffc02031e8 <etext+0x4cc>
ffffffffc0200eec:	00002617          	auipc	a2,0x2
ffffffffc0200ef0:	0dc60613          	addi	a2,a2,220 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200ef4:	09f00593          	li	a1,159
ffffffffc0200ef8:	00002517          	auipc	a0,0x2
ffffffffc0200efc:	0e850513          	addi	a0,a0,232 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200f00:	ad6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(count == 0);
ffffffffc0200f04:	00002697          	auipc	a3,0x2
ffffffffc0200f08:	46c68693          	addi	a3,a3,1132 # ffffffffc0203370 <etext+0x654>
ffffffffc0200f0c:	00002617          	auipc	a2,0x2
ffffffffc0200f10:	0bc60613          	addi	a2,a2,188 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200f14:	10e00593          	li	a1,270
ffffffffc0200f18:	00002517          	auipc	a0,0x2
ffffffffc0200f1c:	0c850513          	addi	a0,a0,200 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200f20:	ab6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free == 0);
ffffffffc0200f24:	00002697          	auipc	a3,0x2
ffffffffc0200f28:	36468693          	addi	a3,a3,868 # ffffffffc0203288 <etext+0x56c>
ffffffffc0200f2c:	00002617          	auipc	a2,0x2
ffffffffc0200f30:	09c60613          	addi	a2,a2,156 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200f34:	10300593          	li	a1,259
ffffffffc0200f38:	00002517          	auipc	a0,0x2
ffffffffc0200f3c:	0a850513          	addi	a0,a0,168 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200f40:	a96ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f44:	00002697          	auipc	a3,0x2
ffffffffc0200f48:	2e468693          	addi	a3,a3,740 # ffffffffc0203228 <etext+0x50c>
ffffffffc0200f4c:	00002617          	auipc	a2,0x2
ffffffffc0200f50:	07c60613          	addi	a2,a2,124 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200f54:	0fd00593          	li	a1,253
ffffffffc0200f58:	00002517          	auipc	a0,0x2
ffffffffc0200f5c:	08850513          	addi	a0,a0,136 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200f60:	a76ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f64:	00002697          	auipc	a3,0x2
ffffffffc0200f68:	3ec68693          	addi	a3,a3,1004 # ffffffffc0203350 <etext+0x634>
ffffffffc0200f6c:	00002617          	auipc	a2,0x2
ffffffffc0200f70:	05c60613          	addi	a2,a2,92 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200f74:	0fc00593          	li	a1,252
ffffffffc0200f78:	00002517          	auipc	a0,0x2
ffffffffc0200f7c:	06850513          	addi	a0,a0,104 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200f80:	a56ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200f84:	00002697          	auipc	a3,0x2
ffffffffc0200f88:	3bc68693          	addi	a3,a3,956 # ffffffffc0203340 <etext+0x624>
ffffffffc0200f8c:	00002617          	auipc	a2,0x2
ffffffffc0200f90:	03c60613          	addi	a2,a2,60 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200f94:	0f400593          	li	a1,244
ffffffffc0200f98:	00002517          	auipc	a0,0x2
ffffffffc0200f9c:	04850513          	addi	a0,a0,72 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200fa0:	a36ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(alloc_pages(2) != NULL);
ffffffffc0200fa4:	00002697          	auipc	a3,0x2
ffffffffc0200fa8:	38468693          	addi	a3,a3,900 # ffffffffc0203328 <etext+0x60c>
ffffffffc0200fac:	00002617          	auipc	a2,0x2
ffffffffc0200fb0:	01c60613          	addi	a2,a2,28 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200fb4:	0f300593          	li	a1,243
ffffffffc0200fb8:	00002517          	auipc	a0,0x2
ffffffffc0200fbc:	02850513          	addi	a0,a0,40 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200fc0:	a16ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200fc4:	00002697          	auipc	a3,0x2
ffffffffc0200fc8:	34468693          	addi	a3,a3,836 # ffffffffc0203308 <etext+0x5ec>
ffffffffc0200fcc:	00002617          	auipc	a2,0x2
ffffffffc0200fd0:	ffc60613          	addi	a2,a2,-4 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200fd4:	0f200593          	li	a1,242
ffffffffc0200fd8:	00002517          	auipc	a0,0x2
ffffffffc0200fdc:	00850513          	addi	a0,a0,8 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0200fe0:	9f6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200fe4:	00002697          	auipc	a3,0x2
ffffffffc0200fe8:	2f468693          	addi	a3,a3,756 # ffffffffc02032d8 <etext+0x5bc>
ffffffffc0200fec:	00002617          	auipc	a2,0x2
ffffffffc0200ff0:	fdc60613          	addi	a2,a2,-36 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0200ff4:	0f000593          	li	a1,240
ffffffffc0200ff8:	00002517          	auipc	a0,0x2
ffffffffc0200ffc:	fe850513          	addi	a0,a0,-24 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0201000:	9d6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201004:	00002697          	auipc	a3,0x2
ffffffffc0201008:	2bc68693          	addi	a3,a3,700 # ffffffffc02032c0 <etext+0x5a4>
ffffffffc020100c:	00002617          	auipc	a2,0x2
ffffffffc0201010:	fbc60613          	addi	a2,a2,-68 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201014:	0ef00593          	li	a1,239
ffffffffc0201018:	00002517          	auipc	a0,0x2
ffffffffc020101c:	fc850513          	addi	a0,a0,-56 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0201020:	9b6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201024:	00002697          	auipc	a3,0x2
ffffffffc0201028:	20468693          	addi	a3,a3,516 # ffffffffc0203228 <etext+0x50c>
ffffffffc020102c:	00002617          	auipc	a2,0x2
ffffffffc0201030:	f9c60613          	addi	a2,a2,-100 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201034:	0e300593          	li	a1,227
ffffffffc0201038:	00002517          	auipc	a0,0x2
ffffffffc020103c:	fa850513          	addi	a0,a0,-88 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0201040:	996ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201044:	00002697          	auipc	a3,0x2
ffffffffc0201048:	26468693          	addi	a3,a3,612 # ffffffffc02032a8 <etext+0x58c>
ffffffffc020104c:	00002617          	auipc	a2,0x2
ffffffffc0201050:	f7c60613          	addi	a2,a2,-132 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201054:	0da00593          	li	a1,218
ffffffffc0201058:	00002517          	auipc	a0,0x2
ffffffffc020105c:	f8850513          	addi	a0,a0,-120 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0201060:	976ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(p0 != NULL);
ffffffffc0201064:	00002697          	auipc	a3,0x2
ffffffffc0201068:	23468693          	addi	a3,a3,564 # ffffffffc0203298 <etext+0x57c>
ffffffffc020106c:	00002617          	auipc	a2,0x2
ffffffffc0201070:	f5c60613          	addi	a2,a2,-164 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201074:	0d900593          	li	a1,217
ffffffffc0201078:	00002517          	auipc	a0,0x2
ffffffffc020107c:	f6850513          	addi	a0,a0,-152 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc0201080:	956ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free == 0);
ffffffffc0201084:	00002697          	auipc	a3,0x2
ffffffffc0201088:	20468693          	addi	a3,a3,516 # ffffffffc0203288 <etext+0x56c>
ffffffffc020108c:	00002617          	auipc	a2,0x2
ffffffffc0201090:	f3c60613          	addi	a2,a2,-196 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201094:	0bd00593          	li	a1,189
ffffffffc0201098:	00002517          	auipc	a0,0x2
ffffffffc020109c:	f4850513          	addi	a0,a0,-184 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc02010a0:	936ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010a4:	00002697          	auipc	a3,0x2
ffffffffc02010a8:	18468693          	addi	a3,a3,388 # ffffffffc0203228 <etext+0x50c>
ffffffffc02010ac:	00002617          	auipc	a2,0x2
ffffffffc02010b0:	f1c60613          	addi	a2,a2,-228 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02010b4:	0bb00593          	li	a1,187
ffffffffc02010b8:	00002517          	auipc	a0,0x2
ffffffffc02010bc:	f2850513          	addi	a0,a0,-216 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc02010c0:	916ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02010c4:	00002697          	auipc	a3,0x2
ffffffffc02010c8:	1a468693          	addi	a3,a3,420 # ffffffffc0203268 <etext+0x54c>
ffffffffc02010cc:	00002617          	auipc	a2,0x2
ffffffffc02010d0:	efc60613          	addi	a2,a2,-260 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02010d4:	0ba00593          	li	a1,186
ffffffffc02010d8:	00002517          	auipc	a0,0x2
ffffffffc02010dc:	f0850513          	addi	a0,a0,-248 # ffffffffc0202fe0 <etext+0x2c4>
ffffffffc02010e0:	8f6ff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02010e4 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc02010e4:	00006797          	auipc	a5,0x6
ffffffffc02010e8:	1047b783          	ld	a5,260(a5) # ffffffffc02071e8 <pmm_manager>
ffffffffc02010ec:	6f9c                	ld	a5,24(a5)
ffffffffc02010ee:	8782                	jr	a5

ffffffffc02010f0 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02010f0:	00006797          	auipc	a5,0x6
ffffffffc02010f4:	0f87b783          	ld	a5,248(a5) # ffffffffc02071e8 <pmm_manager>
ffffffffc02010f8:	739c                	ld	a5,32(a5)
ffffffffc02010fa:	8782                	jr	a5

ffffffffc02010fc <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02010fc:	00006797          	auipc	a5,0x6
ffffffffc0201100:	0ec7b783          	ld	a5,236(a5) # ffffffffc02071e8 <pmm_manager>
ffffffffc0201104:	779c                	ld	a5,40(a5)
ffffffffc0201106:	8782                	jr	a5

ffffffffc0201108 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201108:	00002797          	auipc	a5,0x2
ffffffffc020110c:	2a078793          	addi	a5,a5,672 # ffffffffc02033a8 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201110:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(free_start), (free_end - free_start) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201112:	7179                	addi	sp,sp,-48
ffffffffc0201114:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201116:	00002517          	auipc	a0,0x2
ffffffffc020111a:	2ca50513          	addi	a0,a0,714 # ffffffffc02033e0 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020111e:	00006417          	auipc	s0,0x6
ffffffffc0201122:	0ca40413          	addi	s0,s0,202 # ffffffffc02071e8 <pmm_manager>
void pmm_init(void) {
ffffffffc0201126:	f406                	sd	ra,40(sp)
ffffffffc0201128:	ec26                	sd	s1,24(sp)
ffffffffc020112a:	e84a                	sd	s2,16(sp)
ffffffffc020112c:	e44e                	sd	s3,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020112e:	e01c                	sd	a5,0(s0)
void pmm_init(void) {
ffffffffc0201130:	e052                	sd	s4,0(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201132:	82eff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    pmm_manager->init();
ffffffffc0201136:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201138:	00006497          	auipc	s1,0x6
ffffffffc020113c:	0c848493          	addi	s1,s1,200 # ffffffffc0207200 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201140:	679c                	ld	a5,8(a5)
ffffffffc0201142:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201144:	57f5                	li	a5,-3
ffffffffc0201146:	07fa                	slli	a5,a5,0x1e
ffffffffc0201148:	e09c                	sd	a5,0(s1)
    uint64_t mem_base = get_memory_base();
ffffffffc020114a:	c86ff0ef          	jal	ra,ffffffffc02005d0 <get_memory_base>
ffffffffc020114e:	89aa                	mv	s3,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0201150:	c8aff0ef          	jal	ra,ffffffffc02005da <get_memory_size>
    if (mem_base == 0 || mem_size == 0 || mem_base < DRAM_BASE) {
ffffffffc0201154:	800007b7          	lui	a5,0x80000
ffffffffc0201158:	fff7c793          	not	a5,a5
    uint64_t mem_size = get_memory_size();
ffffffffc020115c:	892a                	mv	s2,a0
    if (mem_base == 0 || mem_size == 0 || mem_base < DRAM_BASE) {
ffffffffc020115e:	1337f663          	bgeu	a5,s3,ffffffffc020128a <pmm_init+0x182>
ffffffffc0201162:	12050463          	beqz	a0,ffffffffc020128a <pmm_init+0x182>
    uint64_t mem_end = mem_base + mem_size;
ffffffffc0201166:	47c5                	li	a5,17
ffffffffc0201168:	00a98a33          	add	s4,s3,a0
    if (mem_end > PHYSICAL_MEMORY_END) {
ffffffffc020116c:	07ee                	slli	a5,a5,0x1b
ffffffffc020116e:	0f47e963          	bltu	a5,s4,ffffffffc0201260 <pmm_init+0x158>
    cprintf("physical memory map:\n");
ffffffffc0201172:	00002517          	auipc	a0,0x2
ffffffffc0201176:	2de50513          	addi	a0,a0,734 # ffffffffc0203450 <best_fit_pmm_manager+0xa8>
ffffffffc020117a:	fe7fe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_base,
ffffffffc020117e:	fffa0693          	addi	a3,s4,-1
ffffffffc0201182:	864e                	mv	a2,s3
ffffffffc0201184:	85ca                	mv	a1,s2
ffffffffc0201186:	00002517          	auipc	a0,0x2
ffffffffc020118a:	2e250513          	addi	a0,a0,738 # ffffffffc0203468 <best_fit_pmm_manager+0xc0>
ffffffffc020118e:	fd3fe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    npage = ROUNDDOWN(mem_end, PGSIZE) / PGSIZE;
ffffffffc0201192:	777d                	lui	a4,0xfffff
ffffffffc0201194:	00007797          	auipc	a5,0x7
ffffffffc0201198:	07778793          	addi	a5,a5,119 # ffffffffc020820b <end+0xfff>
ffffffffc020119c:	8ff9                	and	a5,a5,a4
ffffffffc020119e:	00ca5613          	srli	a2,s4,0xc
    size_t nr_desc = npage - nbase;
ffffffffc02011a2:	fff805b7          	lui	a1,0xfff80
    npage = ROUNDDOWN(mem_end, PGSIZE) / PGSIZE;
ffffffffc02011a6:	00006717          	auipc	a4,0x6
ffffffffc02011aa:	02c73923          	sd	a2,50(a4) # ffffffffc02071d8 <npage>
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02011ae:	00006717          	auipc	a4,0x6
ffffffffc02011b2:	02f73923          	sd	a5,50(a4) # ffffffffc02071e0 <pages>
    size_t nr_desc = npage - nbase;
ffffffffc02011b6:	00b606b3          	add	a3,a2,a1
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02011ba:	853e                	mv	a0,a5
    for (i = 0; i < nr_desc; i++) {
ffffffffc02011bc:	c685                	beqz	a3,ffffffffc02011e4 <pmm_init+0xdc>
ffffffffc02011be:	00261593          	slli	a1,a2,0x2
ffffffffc02011c2:	95b2                	add	a1,a1,a2
ffffffffc02011c4:	fec00737          	lui	a4,0xfec00
ffffffffc02011c8:	973e                	add	a4,a4,a5
ffffffffc02011ca:	058e                	slli	a1,a1,0x3
ffffffffc02011cc:	972e                	add	a4,a4,a1
        SetPageReserved(p);
ffffffffc02011ce:	4805                	li	a6,1
        p->property = 0;
ffffffffc02011d0:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02011d4:	0007a023          	sw	zero,0(a5)
        SetPageReserved(p);
ffffffffc02011d8:	0107b423          	sd	a6,8(a5)
    for (i = 0; i < nr_desc; i++) {
ffffffffc02011dc:	02878793          	addi	a5,a5,40
ffffffffc02011e0:	fef718e3          	bne	a4,a5,ffffffffc02011d0 <pmm_init+0xc8>
    uintptr_t free_start = ROUNDUP(PADDR(pages + nr_desc), PGSIZE);
ffffffffc02011e4:	00269593          	slli	a1,a3,0x2
ffffffffc02011e8:	95b6                	add	a1,a1,a3
ffffffffc02011ea:	058e                	slli	a1,a1,0x3
ffffffffc02011ec:	00b506b3          	add	a3,a0,a1
ffffffffc02011f0:	c02007b7          	lui	a5,0xc0200
ffffffffc02011f4:	0af6e963          	bltu	a3,a5,ffffffffc02012a6 <pmm_init+0x19e>
ffffffffc02011f8:	609c                	ld	a5,0(s1)
ffffffffc02011fa:	6585                	lui	a1,0x1
ffffffffc02011fc:	15fd                	addi	a1,a1,-1
ffffffffc02011fe:	8d9d                	sub	a1,a1,a5
ffffffffc0201200:	95b6                	add	a1,a1,a3
ffffffffc0201202:	76fd                	lui	a3,0xfffff
ffffffffc0201204:	8df5                	and	a1,a1,a3
    uintptr_t free_end = npage * PGSIZE;
ffffffffc0201206:	00c61793          	slli	a5,a2,0xc
    if (free_start < free_end) {
ffffffffc020120a:	04f5ed63          	bltu	a1,a5,ffffffffc0201264 <pmm_init+0x15c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020120e:	601c                	ld	a5,0(s0)
ffffffffc0201210:	7b9c                	ld	a5,48(a5)
ffffffffc0201212:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201214:	00002517          	auipc	a0,0x2
ffffffffc0201218:	2dc50513          	addi	a0,a0,732 # ffffffffc02034f0 <best_fit_pmm_manager+0x148>
ffffffffc020121c:	f45fe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201220:	00005597          	auipc	a1,0x5
ffffffffc0201224:	de058593          	addi	a1,a1,-544 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201228:	00006797          	auipc	a5,0x6
ffffffffc020122c:	fcb7b823          	sd	a1,-48(a5) # ffffffffc02071f8 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201230:	c02007b7          	lui	a5,0xc0200
ffffffffc0201234:	08f5e563          	bltu	a1,a5,ffffffffc02012be <pmm_init+0x1b6>
ffffffffc0201238:	6090                	ld	a2,0(s1)
}
ffffffffc020123a:	7402                	ld	s0,32(sp)
ffffffffc020123c:	70a2                	ld	ra,40(sp)
ffffffffc020123e:	64e2                	ld	s1,24(sp)
ffffffffc0201240:	6942                	ld	s2,16(sp)
ffffffffc0201242:	69a2                	ld	s3,8(sp)
ffffffffc0201244:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201246:	40c58633          	sub	a2,a1,a2
ffffffffc020124a:	00006797          	auipc	a5,0x6
ffffffffc020124e:	fac7b323          	sd	a2,-90(a5) # ffffffffc02071f0 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201252:	00002517          	auipc	a0,0x2
ffffffffc0201256:	2be50513          	addi	a0,a0,702 # ffffffffc0203510 <best_fit_pmm_manager+0x168>
}
ffffffffc020125a:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020125c:	f05fe06f          	j	ffffffffc0200160 <cprintf>
ffffffffc0201260:	8a3e                	mv	s4,a5
ffffffffc0201262:	bf01                	j	ffffffffc0201172 <pmm_init+0x6a>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201264:	00c5d713          	srli	a4,a1,0xc
ffffffffc0201268:	06c77863          	bgeu	a4,a2,ffffffffc02012d8 <pmm_init+0x1d0>
    pmm_manager->init_memmap(base, n);
ffffffffc020126c:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020126e:	fff806b7          	lui	a3,0xfff80
ffffffffc0201272:	96ba                	add	a3,a3,a4
ffffffffc0201274:	00269713          	slli	a4,a3,0x2
ffffffffc0201278:	9736                	add	a4,a4,a3
ffffffffc020127a:	6a14                	ld	a3,16(a2)
        init_memmap(pa2page(free_start), (free_end - free_start) / PGSIZE);
ffffffffc020127c:	40b785b3          	sub	a1,a5,a1
ffffffffc0201280:	070e                	slli	a4,a4,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201282:	81b1                	srli	a1,a1,0xc
ffffffffc0201284:	953a                	add	a0,a0,a4
ffffffffc0201286:	9682                	jalr	a3
}
ffffffffc0201288:	b759                	j	ffffffffc020120e <pmm_init+0x106>
        panic("page_init: invalid physical memory info (base=0x%lx, size=0x%lx)",
ffffffffc020128a:	874a                	mv	a4,s2
ffffffffc020128c:	86ce                	mv	a3,s3
ffffffffc020128e:	00002617          	auipc	a2,0x2
ffffffffc0201292:	16a60613          	addi	a2,a2,362 # ffffffffc02033f8 <best_fit_pmm_manager+0x50>
ffffffffc0201296:	05f00593          	li	a1,95
ffffffffc020129a:	00002517          	auipc	a0,0x2
ffffffffc020129e:	1a650513          	addi	a0,a0,422 # ffffffffc0203440 <best_fit_pmm_manager+0x98>
ffffffffc02012a2:	f35fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    uintptr_t free_start = ROUNDUP(PADDR(pages + nr_desc), PGSIZE);
ffffffffc02012a6:	00002617          	auipc	a2,0x2
ffffffffc02012aa:	1f260613          	addi	a2,a2,498 # ffffffffc0203498 <best_fit_pmm_manager+0xf0>
ffffffffc02012ae:	08300593          	li	a1,131
ffffffffc02012b2:	00002517          	auipc	a0,0x2
ffffffffc02012b6:	18e50513          	addi	a0,a0,398 # ffffffffc0203440 <best_fit_pmm_manager+0x98>
ffffffffc02012ba:	f1dfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02012be:	86ae                	mv	a3,a1
ffffffffc02012c0:	00002617          	auipc	a2,0x2
ffffffffc02012c4:	1d860613          	addi	a2,a2,472 # ffffffffc0203498 <best_fit_pmm_manager+0xf0>
ffffffffc02012c8:	09e00593          	li	a1,158
ffffffffc02012cc:	00002517          	auipc	a0,0x2
ffffffffc02012d0:	17450513          	addi	a0,a0,372 # ffffffffc0203440 <best_fit_pmm_manager+0x98>
ffffffffc02012d4:	f03fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02012d8:	00002617          	auipc	a2,0x2
ffffffffc02012dc:	1e860613          	addi	a2,a2,488 # ffffffffc02034c0 <best_fit_pmm_manager+0x118>
ffffffffc02012e0:	06a00593          	li	a1,106
ffffffffc02012e4:	00002517          	auipc	a0,0x2
ffffffffc02012e8:	1fc50513          	addi	a0,a0,508 # ffffffffc02034e0 <best_fit_pmm_manager+0x138>
ffffffffc02012ec:	eebfe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02012f0 <slub_test_disjoint.part.0>:
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
    }
}

static void
slub_test_disjoint(void *a, size_t a_size, void *b, size_t b_size) {
ffffffffc02012f0:	1141                	addi	sp,sp,-16
    uintptr_t a_start = (uintptr_t)a, b_start = (uintptr_t)b;
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc02012f2:	00002697          	auipc	a3,0x2
ffffffffc02012f6:	25e68693          	addi	a3,a3,606 # ffffffffc0203550 <best_fit_pmm_manager+0x1a8>
ffffffffc02012fa:	00002617          	auipc	a2,0x2
ffffffffc02012fe:	cce60613          	addi	a2,a2,-818 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201302:	0ce00593          	li	a1,206
ffffffffc0201306:	00002517          	auipc	a0,0x2
ffffffffc020130a:	28a50513          	addi	a0,a0,650 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
slub_test_disjoint(void *a, size_t a_size, void *b, size_t b_size) {
ffffffffc020130e:	e406                	sd	ra,8(sp)
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0201310:	ec7fe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0201314 <slub_alloc.part.0>:
slub_alloc(size_t size) {
ffffffffc0201314:	7139                	addi	sp,sp,-64
ffffffffc0201316:	f04a                	sd	s2,32(sp)
ffffffffc0201318:	00006917          	auipc	s2,0x6
ffffffffc020131c:	d1890913          	addi	s2,s2,-744 # ffffffffc0207030 <slub_caches>
ffffffffc0201320:	ec4e                	sd	s3,24(sp)
ffffffffc0201322:	fc06                	sd	ra,56(sp)
ffffffffc0201324:	f822                	sd	s0,48(sp)
ffffffffc0201326:	f426                	sd	s1,40(sp)
ffffffffc0201328:	e852                	sd	s4,16(sp)
ffffffffc020132a:	e456                	sd	s5,8(sp)
ffffffffc020132c:	87ca                	mv	a5,s2
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc020132e:	4981                	li	s3,0
ffffffffc0201330:	46a9                	li	a3,10
        if (size > cache->object_size) {
ffffffffc0201332:	6398                	ld	a4,0(a5)
ffffffffc0201334:	06a76963          	bltu	a4,a0,ffffffffc02013a6 <slub_alloc.part.0+0x92>
ffffffffc0201338:	00299a13          	slli	s4,s3,0x2
ffffffffc020133c:	013a04b3          	add	s1,s4,s3
ffffffffc0201340:	048e                	slli	s1,s1,0x3
    return list->next == list;
ffffffffc0201342:	00990ab3          	add	s5,s2,s1
ffffffffc0201346:	010ab403          	ld	s0,16(s5)
        if (list_empty(&cache->partial)) {
ffffffffc020134a:	00848793          	addi	a5,s1,8
ffffffffc020134e:	97ca                	add	a5,a5,s2
ffffffffc0201350:	0cf40563          	beq	s0,a5,ffffffffc020141a <slub_alloc.part.0+0x106>
        void *object = slab->freelist;
ffffffffc0201354:	7008                	ld	a0,32(s0)
        assert(object != NULL && slab->inuse < slab->capacity);
ffffffffc0201356:	14050d63          	beqz	a0,ffffffffc02014b0 <slub_alloc.part.0+0x19c>
ffffffffc020135a:	741c                	ld	a5,40(s0)
ffffffffc020135c:	7818                	ld	a4,48(s0)
ffffffffc020135e:	14e7f963          	bgeu	a5,a4,ffffffffc02014b0 <slub_alloc.part.0+0x19c>
        slab->freelist = *(void **)object;
ffffffffc0201362:	6114                	ld	a3,0(a0)
        slab->inuse++;
ffffffffc0201364:	0785                	addi	a5,a5,1
ffffffffc0201366:	f41c                	sd	a5,40(s0)
        slab->freelist = *(void **)object;
ffffffffc0201368:	f014                	sd	a3,32(s0)
        if (slab->inuse == slab->capacity) {
ffffffffc020136a:	02f71563          	bne	a4,a5,ffffffffc0201394 <slub_alloc.part.0+0x80>
    __list_del(listelm->prev, listelm->next);
ffffffffc020136e:	641c                	ld	a5,8(s0)
ffffffffc0201370:	6018                	ld	a4,0(s0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201372:	99d2                	add	s3,s3,s4
ffffffffc0201374:	098e                	slli	s3,s3,0x3
    prev->next = next;
ffffffffc0201376:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201378:	e398                	sd	a4,0(a5)
    elm->prev = elm->next = elm;
ffffffffc020137a:	e400                	sd	s0,8(s0)
ffffffffc020137c:	e000                	sd	s0,0(s0)
    __list_add(elm, listelm, listelm->next);
ffffffffc020137e:	99ca                	add	s3,s3,s2
ffffffffc0201380:	0209b783          	ld	a5,32(s3)
            list_add(&cache->full, &slab->link);
ffffffffc0201384:	04e1                	addi	s1,s1,24
ffffffffc0201386:	9926                	add	s2,s2,s1
    prev->next = next->prev = elm;
ffffffffc0201388:	e380                	sd	s0,0(a5)
ffffffffc020138a:	0289b023          	sd	s0,32(s3)
    elm->next = next;
ffffffffc020138e:	e41c                	sd	a5,8(s0)
    elm->prev = prev;
ffffffffc0201390:	01243023          	sd	s2,0(s0)
}
ffffffffc0201394:	70e2                	ld	ra,56(sp)
ffffffffc0201396:	7442                	ld	s0,48(sp)
ffffffffc0201398:	74a2                	ld	s1,40(sp)
ffffffffc020139a:	7902                	ld	s2,32(sp)
ffffffffc020139c:	69e2                	ld	s3,24(sp)
ffffffffc020139e:	6a42                	ld	s4,16(sp)
ffffffffc02013a0:	6aa2                	ld	s5,8(sp)
ffffffffc02013a2:	6121                	addi	sp,sp,64
ffffffffc02013a4:	8082                	ret
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc02013a6:	0985                	addi	s3,s3,1
ffffffffc02013a8:	02878793          	addi	a5,a5,40
ffffffffc02013ac:	f8d993e3          	bne	s3,a3,ffffffffc0201332 <slub_alloc.part.0+0x1e>
    if (size > (size_t)-1 - SLUB_HEADER_SIZE - (PGSIZE - 1)) {
ffffffffc02013b0:	77fd                	lui	a5,0xfffff
ffffffffc02013b2:	fc078793          	addi	a5,a5,-64 # ffffffffffffefc0 <end+0x3fdf7db4>
ffffffffc02013b6:	0ea7eb63          	bltu	a5,a0,ffffffffc02014ac <slub_alloc.part.0+0x198>
    size_t nr_pages = (size + SLUB_HEADER_SIZE + PGSIZE - 1) / PGSIZE;
ffffffffc02013ba:	6405                	lui	s0,0x1
ffffffffc02013bc:	03f40413          	addi	s0,s0,63 # 103f <kern_entry-0xffffffffc01fefc1>
ffffffffc02013c0:	9522                	add	a0,a0,s0
ffffffffc02013c2:	00c55413          	srli	s0,a0,0xc
    struct Page *page = alloc_pages(nr_pages);
ffffffffc02013c6:	8522                	mv	a0,s0
ffffffffc02013c8:	d1dff0ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
    if (page == NULL) {
ffffffffc02013cc:	c165                	beqz	a0,ffffffffc02014ac <slub_alloc.part.0+0x198>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02013ce:	00006797          	auipc	a5,0x6
ffffffffc02013d2:	e127b783          	ld	a5,-494(a5) # ffffffffc02071e0 <pages>
ffffffffc02013d6:	40f507b3          	sub	a5,a0,a5
ffffffffc02013da:	00003717          	auipc	a4,0x3
ffffffffc02013de:	b2673703          	ld	a4,-1242(a4) # ffffffffc0203f00 <error_string+0x38>
ffffffffc02013e2:	878d                	srai	a5,a5,0x3
ffffffffc02013e4:	02e787b3          	mul	a5,a5,a4
ffffffffc02013e8:	00003697          	auipc	a3,0x3
ffffffffc02013ec:	b206b683          	ld	a3,-1248(a3) # ffffffffc0203f08 <nbase>
    slab->inuse = 1;
ffffffffc02013f0:	4705                	li	a4,1
ffffffffc02013f2:	97b6                	add	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02013f4:	07b2                	slli	a5,a5,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc02013f6:	00006697          	auipc	a3,0x6
ffffffffc02013fa:	e0a6b683          	ld	a3,-502(a3) # ffffffffc0207200 <va_pa_offset>
ffffffffc02013fe:	97b6                	add	a5,a5,a3
    slab->page = page;
ffffffffc0201400:	ef88                	sd	a0,24(a5)
    elm->prev = elm->next = elm;
ffffffffc0201402:	e79c                	sd	a5,8(a5)
ffffffffc0201404:	e39c                	sd	a5,0(a5)
    slab->cache = NULL;
ffffffffc0201406:	0007b823          	sd	zero,16(a5)
    slab->freelist = NULL;
ffffffffc020140a:	0207b023          	sd	zero,32(a5)
    slab->inuse = 1;
ffffffffc020140e:	f798                	sd	a4,40(a5)
    slab->capacity = 1;
ffffffffc0201410:	fb98                	sd	a4,48(a5)
    slab->nr_pages = nr_pages;
ffffffffc0201412:	ff80                	sd	s0,56(a5)
    return (char *)slab + SLUB_HEADER_SIZE;
ffffffffc0201414:	04078513          	addi	a0,a5,64
ffffffffc0201418:	bfb5                	j	ffffffffc0201394 <slub_alloc.part.0+0x80>
    struct Page *page = alloc_pages(1);
ffffffffc020141a:	4505                	li	a0,1
ffffffffc020141c:	cc9ff0ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
    if (page == NULL) {
ffffffffc0201420:	c551                	beqz	a0,ffffffffc02014ac <slub_alloc.part.0+0x198>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201422:	00006717          	auipc	a4,0x6
ffffffffc0201426:	dbe73703          	ld	a4,-578(a4) # ffffffffc02071e0 <pages>
ffffffffc020142a:	40e50733          	sub	a4,a0,a4
ffffffffc020142e:	00003797          	auipc	a5,0x3
ffffffffc0201432:	ad27b783          	ld	a5,-1326(a5) # ffffffffc0203f00 <error_string+0x38>
ffffffffc0201436:	870d                	srai	a4,a4,0x3
ffffffffc0201438:	02f70733          	mul	a4,a4,a5
ffffffffc020143c:	00003697          	auipc	a3,0x3
ffffffffc0201440:	acc6b683          	ld	a3,-1332(a3) # ffffffffc0203f08 <nbase>
    slab->capacity = (PGSIZE - SLUB_HEADER_SIZE) / cache->object_size;
ffffffffc0201444:	6785                	lui	a5,0x1
ffffffffc0201446:	fc078793          	addi	a5,a5,-64 # fc0 <kern_entry-0xffffffffc01ff040>
ffffffffc020144a:	9736                	add	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020144c:	0732                	slli	a4,a4,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc020144e:	00006697          	auipc	a3,0x6
ffffffffc0201452:	db26b683          	ld	a3,-590(a3) # ffffffffc0207200 <va_pa_offset>
ffffffffc0201456:	9736                	add	a4,a4,a3
ffffffffc0201458:	e718                	sd	a4,8(a4)
ffffffffc020145a:	e318                	sd	a4,0(a4)
    slab->capacity = (PGSIZE - SLUB_HEADER_SIZE) / cache->object_size;
ffffffffc020145c:	000ab583          	ld	a1,0(s5)
    slab->nr_pages = 1;
ffffffffc0201460:	4685                	li	a3,1
    slab->cache = cache;
ffffffffc0201462:	01573823          	sd	s5,16(a4)
    slab->capacity = (PGSIZE - SLUB_HEADER_SIZE) / cache->object_size;
ffffffffc0201466:	02b7d633          	divu	a2,a5,a1
    slab->page = page;
ffffffffc020146a:	ef08                	sd	a0,24(a4)
    slab->freelist = NULL;
ffffffffc020146c:	02073023          	sd	zero,32(a4)
    slab->inuse = 0;
ffffffffc0201470:	02073423          	sd	zero,40(a4)
    slab->nr_pages = 1;
ffffffffc0201474:	ff14                	sd	a3,56(a4)
    slab->capacity = (PGSIZE - SLUB_HEADER_SIZE) / cache->object_size;
ffffffffc0201476:	fb10                	sd	a2,48(a4)
    assert(slab->capacity > 0);
ffffffffc0201478:	04b7ec63          	bltu	a5,a1,ffffffffc02014d0 <slub_alloc.part.0+0x1bc>
ffffffffc020147c:	167d                	addi	a2,a2,-1
ffffffffc020147e:	02b607b3          	mul	a5,a2,a1
ffffffffc0201482:	4681                	li	a3,0
ffffffffc0201484:	04078793          	addi	a5,a5,64
ffffffffc0201488:	97ba                	add	a5,a5,a4
ffffffffc020148a:	a011                	j	ffffffffc020148e <slub_alloc.part.0+0x17a>
ffffffffc020148c:	167d                	addi	a2,a2,-1
        *(void **)object = slab->freelist;
ffffffffc020148e:	e394                	sd	a3,0(a5)
        slab->freelist = object;
ffffffffc0201490:	f31c                	sd	a5,32(a4)
        void *object = objects + (i - 1) * cache->object_size;
ffffffffc0201492:	86be                	mv	a3,a5
    for (size_t i = slab->capacity; i > 0; i--) {
ffffffffc0201494:	8f8d                	sub	a5,a5,a1
ffffffffc0201496:	fa7d                	bnez	a2,ffffffffc020148c <slub_alloc.part.0+0x178>
    __list_add(elm, listelm, listelm->next);
ffffffffc0201498:	010ab783          	ld	a5,16(s5)
        void *object = slab->freelist;
ffffffffc020149c:	7308                	ld	a0,32(a4)
    prev->next = next->prev = elm;
ffffffffc020149e:	e398                	sd	a4,0(a5)
ffffffffc02014a0:	00eab823          	sd	a4,16(s5)
    elm->prev = prev;
ffffffffc02014a4:	e300                	sd	s0,0(a4)
    elm->next = next;
ffffffffc02014a6:	e71c                	sd	a5,8(a4)
ffffffffc02014a8:	843a                	mv	s0,a4
ffffffffc02014aa:	bd45                	j	ffffffffc020135a <slub_alloc.part.0+0x46>
                return NULL;
ffffffffc02014ac:	4501                	li	a0,0
ffffffffc02014ae:	b5dd                	j	ffffffffc0201394 <slub_alloc.part.0+0x80>
        assert(object != NULL && slab->inuse < slab->capacity);
ffffffffc02014b0:	00002697          	auipc	a3,0x2
ffffffffc02014b4:	10868693          	addi	a3,a3,264 # ffffffffc02035b8 <best_fit_pmm_manager+0x210>
ffffffffc02014b8:	00002617          	auipc	a2,0x2
ffffffffc02014bc:	b1060613          	addi	a2,a2,-1264 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02014c0:	08400593          	li	a1,132
ffffffffc02014c4:	00002517          	auipc	a0,0x2
ffffffffc02014c8:	0cc50513          	addi	a0,a0,204 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02014cc:	d0bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slab->capacity > 0);
ffffffffc02014d0:	00002697          	auipc	a3,0x2
ffffffffc02014d4:	0d068693          	addi	a3,a3,208 # ffffffffc02035a0 <best_fit_pmm_manager+0x1f8>
ffffffffc02014d8:	00002617          	auipc	a2,0x2
ffffffffc02014dc:	af060613          	addi	a2,a2,-1296 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02014e0:	04a00593          	li	a1,74
ffffffffc02014e4:	00002517          	auipc	a0,0x2
ffffffffc02014e8:	0ac50513          	addi	a0,a0,172 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02014ec:	cebfe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02014f0 <slub_init>:
    if (slub_ready) {
ffffffffc02014f0:	00006817          	auipc	a6,0x6
ffffffffc02014f4:	d1880813          	addi	a6,a6,-744 # ffffffffc0207208 <slub_ready>
ffffffffc02014f8:	00082783          	lw	a5,0(a6)
ffffffffc02014fc:	e7b9                	bnez	a5,ffffffffc020154a <slub_init+0x5a>
ffffffffc02014fe:	00002617          	auipc	a2,0x2
ffffffffc0201502:	77260613          	addi	a2,a2,1906 # ffffffffc0203c70 <slub_sizes+0x8>
ffffffffc0201506:	00006797          	auipc	a5,0x6
ffffffffc020150a:	b3278793          	addi	a5,a5,-1230 # ffffffffc0207038 <slub_caches+0x8>
ffffffffc020150e:	00006597          	auipc	a1,0x6
ffffffffc0201512:	c9258593          	addi	a1,a1,-878 # ffffffffc02071a0 <slub_caches+0x170>
        assert(slub_sizes[i] >= sizeof(void *) &&
ffffffffc0201516:	4741                	li	a4,16
ffffffffc0201518:	451d                	li	a0,7
ffffffffc020151a:	a039                	j	ffffffffc0201528 <slub_init+0x38>
ffffffffc020151c:	6218                	ld	a4,0(a2)
ffffffffc020151e:	02878793          	addi	a5,a5,40
ffffffffc0201522:	0621                	addi	a2,a2,8
ffffffffc0201524:	02e57463          	bgeu	a0,a4,ffffffffc020154c <slub_init+0x5c>
ffffffffc0201528:	00f77693          	andi	a3,a4,15
ffffffffc020152c:	e285                	bnez	a3,ffffffffc020154c <slub_init+0x5c>
        slub_caches[i].object_size = slub_sizes[i];
ffffffffc020152e:	01078693          	addi	a3,a5,16
ffffffffc0201532:	fee7bc23          	sd	a4,-8(a5)
    elm->prev = elm->next = elm;
ffffffffc0201536:	e79c                	sd	a5,8(a5)
ffffffffc0201538:	e39c                	sd	a5,0(a5)
ffffffffc020153a:	ef94                	sd	a3,24(a5)
ffffffffc020153c:	eb94                	sd	a3,16(a5)
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc020153e:	fcb79fe3          	bne	a5,a1,ffffffffc020151c <slub_init+0x2c>
    slub_ready = 1;
ffffffffc0201542:	4785                	li	a5,1
ffffffffc0201544:	00f82023          	sw	a5,0(a6)
ffffffffc0201548:	8082                	ret
ffffffffc020154a:	8082                	ret
slub_init(void) {
ffffffffc020154c:	1141                	addi	sp,sp,-16
        assert(slub_sizes[i] >= sizeof(void *) &&
ffffffffc020154e:	00002697          	auipc	a3,0x2
ffffffffc0201552:	09a68693          	addi	a3,a3,154 # ffffffffc02035e8 <best_fit_pmm_manager+0x240>
ffffffffc0201556:	00002617          	auipc	a2,0x2
ffffffffc020155a:	a7260613          	addi	a2,a2,-1422 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc020155e:	03200593          	li	a1,50
ffffffffc0201562:	00002517          	auipc	a0,0x2
ffffffffc0201566:	02e50513          	addi	a0,a0,46 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
slub_init(void) {
ffffffffc020156a:	e406                	sd	ra,8(sp)
        assert(slub_sizes[i] >= sizeof(void *) &&
ffffffffc020156c:	c6bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0201570 <slub_free>:
    if (ptr == NULL) {
ffffffffc0201570:	c15d                	beqz	a0,ffffffffc0201616 <slub_free+0xa6>
slub_free(void *ptr) {
ffffffffc0201572:	1141                	addi	sp,sp,-16
ffffffffc0201574:	e406                	sd	ra,8(sp)
    assert(slub_ready);
ffffffffc0201576:	00006797          	auipc	a5,0x6
ffffffffc020157a:	c927a783          	lw	a5,-878(a5) # ffffffffc0207208 <slub_ready>
ffffffffc020157e:	cfe9                	beqz	a5,ffffffffc0201658 <slub_free+0xe8>
    struct slub_slab *slab = (struct slub_slab *)ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0201580:	77fd                	lui	a5,0xfffff
ffffffffc0201582:	8fe9                	and	a5,a5,a0
    assert(slab->page != NULL && slab->inuse > 0);
ffffffffc0201584:	6f98                	ld	a4,24(a5)
ffffffffc0201586:	cb4d                	beqz	a4,ffffffffc0201638 <slub_free+0xc8>
ffffffffc0201588:	7794                	ld	a3,40(a5)
ffffffffc020158a:	c6dd                	beqz	a3,ffffffffc0201638 <slub_free+0xc8>
    if (slab->cache == NULL) {
ffffffffc020158c:	6b90                	ld	a2,16(a5)
ffffffffc020158e:	ce0d                	beqz	a2,ffffffffc02015c8 <slub_free+0x58>
    uintptr_t offset = (uintptr_t)ptr - ((uintptr_t)slab + SLUB_HEADER_SIZE);
ffffffffc0201590:	fc050713          	addi	a4,a0,-64
    assert((uintptr_t)ptr >= (uintptr_t)slab + SLUB_HEADER_SIZE &&
ffffffffc0201594:	04078593          	addi	a1,a5,64 # fffffffffffff040 <end+0x3fdf7e34>
    uintptr_t offset = (uintptr_t)ptr - ((uintptr_t)slab + SLUB_HEADER_SIZE);
ffffffffc0201598:	8f1d                	sub	a4,a4,a5
    assert((uintptr_t)ptr >= (uintptr_t)slab + SLUB_HEADER_SIZE &&
ffffffffc020159a:	06b56f63          	bltu	a0,a1,ffffffffc0201618 <slub_free+0xa8>
ffffffffc020159e:	7b8c                	ld	a1,48(a5)
ffffffffc02015a0:	00063803          	ld	a6,0(a2)
ffffffffc02015a4:	030588b3          	mul	a7,a1,a6
ffffffffc02015a8:	07177863          	bgeu	a4,a7,ffffffffc0201618 <slub_free+0xa8>
ffffffffc02015ac:	03077733          	remu	a4,a4,a6
ffffffffc02015b0:	e725                	bnez	a4,ffffffffc0201618 <slub_free+0xa8>
    if (slab->inuse == slab->capacity) {
ffffffffc02015b2:	02b68463          	beq	a3,a1,ffffffffc02015da <slub_free+0x6a>
    *(void **)ptr = slab->freelist;
ffffffffc02015b6:	7398                	ld	a4,32(a5)
    slab->inuse--;
ffffffffc02015b8:	16fd                	addi	a3,a3,-1
    *(void **)ptr = slab->freelist;
ffffffffc02015ba:	e118                	sd	a4,0(a0)
    slab->freelist = ptr;
ffffffffc02015bc:	f388                	sd	a0,32(a5)
    slab->inuse--;
ffffffffc02015be:	f794                	sd	a3,40(a5)
    if (slab->inuse == 0) {
ffffffffc02015c0:	c2a1                	beqz	a3,ffffffffc0201600 <slub_free+0x90>
}
ffffffffc02015c2:	60a2                	ld	ra,8(sp)
ffffffffc02015c4:	0141                	addi	sp,sp,16
ffffffffc02015c6:	8082                	ret
        assert(ptr == (char *)slab + SLUB_HEADER_SIZE);
ffffffffc02015c8:	04078693          	addi	a3,a5,64
ffffffffc02015cc:	0ad51663          	bne	a0,a3,ffffffffc0201678 <slub_free+0x108>
}
ffffffffc02015d0:	60a2                	ld	ra,8(sp)
        free_pages(slab->page, slab->nr_pages);
ffffffffc02015d2:	7f8c                	ld	a1,56(a5)
ffffffffc02015d4:	853a                	mv	a0,a4
}
ffffffffc02015d6:	0141                	addi	sp,sp,16
        free_pages(slab->page, slab->nr_pages);
ffffffffc02015d8:	be21                	j	ffffffffc02010f0 <free_pages>
    __list_del(listelm->prev, listelm->next);
ffffffffc02015da:	6798                	ld	a4,8(a5)
ffffffffc02015dc:	638c                	ld	a1,0(a5)
        list_add(&cache->partial, &slab->link);
ffffffffc02015de:	00860813          	addi	a6,a2,8
    slab->inuse--;
ffffffffc02015e2:	16fd                	addi	a3,a3,-1
    prev->next = next;
ffffffffc02015e4:	e598                	sd	a4,8(a1)
    next->prev = prev;
ffffffffc02015e6:	e30c                	sd	a1,0(a4)
    elm->prev = elm->next = elm;
ffffffffc02015e8:	e79c                	sd	a5,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc02015ea:	6a18                	ld	a4,16(a2)
    prev->next = next->prev = elm;
ffffffffc02015ec:	e31c                	sd	a5,0(a4)
ffffffffc02015ee:	ea1c                	sd	a5,16(a2)
    elm->next = next;
ffffffffc02015f0:	e798                	sd	a4,8(a5)
    *(void **)ptr = slab->freelist;
ffffffffc02015f2:	7398                	ld	a4,32(a5)
    elm->prev = prev;
ffffffffc02015f4:	0107b023          	sd	a6,0(a5)
ffffffffc02015f8:	e118                	sd	a4,0(a0)
    slab->freelist = ptr;
ffffffffc02015fa:	f388                	sd	a0,32(a5)
    slab->inuse--;
ffffffffc02015fc:	f794                	sd	a3,40(a5)
    if (slab->inuse == 0) {
ffffffffc02015fe:	f2f1                	bnez	a3,ffffffffc02015c2 <slub_free+0x52>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201600:	6394                	ld	a3,0(a5)
ffffffffc0201602:	6798                	ld	a4,8(a5)
        free_pages(slab->page, 1);
ffffffffc0201604:	6f88                	ld	a0,24(a5)
}
ffffffffc0201606:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201608:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020160a:	e314                	sd	a3,0(a4)
    elm->prev = elm->next = elm;
ffffffffc020160c:	e79c                	sd	a5,8(a5)
ffffffffc020160e:	e39c                	sd	a5,0(a5)
        free_pages(slab->page, 1);
ffffffffc0201610:	4585                	li	a1,1
}
ffffffffc0201612:	0141                	addi	sp,sp,16
        free_pages(slab->page, 1);
ffffffffc0201614:	bcf1                	j	ffffffffc02010f0 <free_pages>
ffffffffc0201616:	8082                	ret
    assert((uintptr_t)ptr >= (uintptr_t)slab + SLUB_HEADER_SIZE &&
ffffffffc0201618:	00002697          	auipc	a3,0x2
ffffffffc020161c:	07868693          	addi	a3,a3,120 # ffffffffc0203690 <best_fit_pmm_manager+0x2e8>
ffffffffc0201620:	00002617          	auipc	a2,0x2
ffffffffc0201624:	9a860613          	addi	a2,a2,-1624 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201628:	0a100593          	li	a1,161
ffffffffc020162c:	00002517          	auipc	a0,0x2
ffffffffc0201630:	f6450513          	addi	a0,a0,-156 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201634:	ba3fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slab->page != NULL && slab->inuse > 0);
ffffffffc0201638:	00002697          	auipc	a3,0x2
ffffffffc020163c:	00868693          	addi	a3,a3,8 # ffffffffc0203640 <best_fit_pmm_manager+0x298>
ffffffffc0201640:	00002617          	auipc	a2,0x2
ffffffffc0201644:	98860613          	addi	a2,a2,-1656 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201648:	09800593          	li	a1,152
ffffffffc020164c:	00002517          	auipc	a0,0x2
ffffffffc0201650:	f4450513          	addi	a0,a0,-188 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201654:	b83fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0201658:	00002697          	auipc	a3,0x2
ffffffffc020165c:	fd868693          	addi	a3,a3,-40 # ffffffffc0203630 <best_fit_pmm_manager+0x288>
ffffffffc0201660:	00002617          	auipc	a2,0x2
ffffffffc0201664:	96860613          	addi	a2,a2,-1688 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201668:	09500593          	li	a1,149
ffffffffc020166c:	00002517          	auipc	a0,0x2
ffffffffc0201670:	f2450513          	addi	a0,a0,-220 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201674:	b63fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(ptr == (char *)slab + SLUB_HEADER_SIZE);
ffffffffc0201678:	00002697          	auipc	a3,0x2
ffffffffc020167c:	ff068693          	addi	a3,a3,-16 # ffffffffc0203668 <best_fit_pmm_manager+0x2c0>
ffffffffc0201680:	00002617          	auipc	a2,0x2
ffffffffc0201684:	94860613          	addi	a2,a2,-1720 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201688:	09a00593          	li	a1,154
ffffffffc020168c:	00002517          	auipc	a0,0x2
ffffffffc0201690:	f0450513          	addi	a0,a0,-252 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201694:	b43fe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0201698 <slub_test_sizes>:
}

static void
slub_test_sizes(void) {
ffffffffc0201698:	de010113          	addi	sp,sp,-544
ffffffffc020169c:	20913423          	sd	s1,520(sp)
ffffffffc02016a0:	20113c23          	sd	ra,536(sp)
ffffffffc02016a4:	20813823          	sd	s0,528(sp)
ffffffffc02016a8:	21213023          	sd	s2,512(sp)
ffffffffc02016ac:	ffce                	sd	s3,504(sp)
ffffffffc02016ae:	fbd2                	sd	s4,496(sp)
ffffffffc02016b0:	f7d6                	sd	s5,488(sp)
ffffffffc02016b2:	f3da                	sd	s6,480(sp)
ffffffffc02016b4:	efde                	sd	s7,472(sp)
    size_t before = nr_free_pages();
ffffffffc02016b6:	a47ff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc02016ba:	84aa                	mv	s1,a0
    const size_t sizes[] = {
ffffffffc02016bc:	00002797          	auipc	a5,0x2
ffffffffc02016c0:	4c478793          	addi	a5,a5,1220 # ffffffffc0203b80 <best_fit_pmm_manager+0x7d8>
ffffffffc02016c4:	870a                	mv	a4,sp
ffffffffc02016c6:	00002817          	auipc	a6,0x2
ffffffffc02016ca:	59a80813          	addi	a6,a6,1434 # ffffffffc0203c60 <best_fit_pmm_manager+0x8b8>
ffffffffc02016ce:	6388                	ld	a0,0(a5)
ffffffffc02016d0:	678c                	ld	a1,8(a5)
ffffffffc02016d2:	6b90                	ld	a2,16(a5)
ffffffffc02016d4:	6f94                	ld	a3,24(a5)
ffffffffc02016d6:	e308                	sd	a0,0(a4)
ffffffffc02016d8:	e70c                	sd	a1,8(a4)
ffffffffc02016da:	eb10                	sd	a2,16(a4)
ffffffffc02016dc:	ef14                	sd	a3,24(a4)
ffffffffc02016de:	02078793          	addi	a5,a5,32
ffffffffc02016e2:	02070713          	addi	a4,a4,32
ffffffffc02016e6:	ff0794e3          	bne	a5,a6,ffffffffc02016ce <slub_test_sizes+0x36>
ffffffffc02016ea:	6394                	ld	a3,0(a5)
    assert(slub_ready);
ffffffffc02016ec:	00006917          	auipc	s2,0x6
ffffffffc02016f0:	b1c90913          	addi	s2,s2,-1252 # ffffffffc0207208 <slub_ready>
ffffffffc02016f4:	00092783          	lw	a5,0(s2)
    const size_t sizes[] = {
ffffffffc02016f8:	e314                	sd	a3,0(a4)
    assert(slub_ready);
ffffffffc02016fa:	16078b63          	beqz	a5,ffffffffc0201870 <slub_test_sizes+0x1d8>
ffffffffc02016fe:	11a0                	addi	s0,sp,232
ffffffffc0201700:	8aa2                	mv	s5,s0
ffffffffc0201702:	4b85                	li	s7,1
ffffffffc0201704:	4b01                	li	s6,0
    enum { count = sizeof(sizes) / sizeof(sizes[0]) };
    void *objects[count];

    assert(slub_alloc(0) == NULL);
    for (size_t i = 0; i < count; i++) {
        objects[i] = slub_alloc(sizes[i]);
ffffffffc0201706:	4a05                	li	s4,1
    for (size_t i = 0; i < count; i++) {
ffffffffc0201708:	49f5                	li	s3,29
ffffffffc020170a:	8552                	mv	a0,s4
ffffffffc020170c:	c09ff0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
        objects[i] = slub_alloc(sizes[i]);
ffffffffc0201710:	00aab023          	sd	a0,0(s5)
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201714:	c535                	beqz	a0,ffffffffc0201780 <slub_test_sizes+0xe8>
ffffffffc0201716:	00f57813          	andi	a6,a0,15
ffffffffc020171a:	06081363          	bnez	a6,ffffffffc0201780 <slub_test_sizes+0xe8>
ffffffffc020171e:	0ffb7793          	zext.b	a5,s6
ffffffffc0201722:	014505b3          	add	a1,a0,s4
ffffffffc0201726:	872a                	mv	a4,a0
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0201728:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc020172c:	27c5                	addiw	a5,a5,17
ffffffffc020172e:	0705                	addi	a4,a4,1
ffffffffc0201730:	0ff7f793          	zext.b	a5,a5
ffffffffc0201734:	feb71ae3          	bne	a4,a1,ffffffffc0201728 <slub_test_sizes+0x90>
        slub_test_write(objects[i], sizes[i], (unsigned char)i);
        for (size_t j = 0; j < i; j++) {
ffffffffc0201738:	020b0563          	beqz	s6,ffffffffc0201762 <slub_test_sizes+0xca>
ffffffffc020173c:	00810893          	addi	a7,sp,8
ffffffffc0201740:	8746                	mv	a4,a7
ffffffffc0201742:	87a2                	mv	a5,s0
ffffffffc0201744:	4605                	li	a2,1
ffffffffc0201746:	a019                	j	ffffffffc020174c <slub_test_sizes+0xb4>
            slub_test_disjoint(objects[i], sizes[i], objects[j], sizes[j]);
ffffffffc0201748:	6310                	ld	a2,0(a4)
ffffffffc020174a:	0721                	addi	a4,a4,8
    uintptr_t a_start = (uintptr_t)a, b_start = (uintptr_t)b;
ffffffffc020174c:	6394                	ld	a3,0(a5)
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc020174e:	00b6f563          	bgeu	a3,a1,ffffffffc0201758 <slub_test_sizes+0xc0>
ffffffffc0201752:	96b2                	add	a3,a3,a2
ffffffffc0201754:	0cd56e63          	bltu	a0,a3,ffffffffc0201830 <slub_test_sizes+0x198>
        for (size_t j = 0; j < i; j++) {
ffffffffc0201758:	07a1                	addi	a5,a5,8
ffffffffc020175a:	ff5797e3          	bne	a5,s5,ffffffffc0201748 <slub_test_sizes+0xb0>
    for (size_t i = 0; i < count; i++) {
ffffffffc020175e:	053b8163          	beq	s7,s3,ffffffffc02017a0 <slub_test_sizes+0x108>
    assert(slub_ready);
ffffffffc0201762:	00092703          	lw	a4,0(s2)
        objects[i] = slub_alloc(sizes[i]);
ffffffffc0201766:	003b9793          	slli	a5,s7,0x3
ffffffffc020176a:	0b94                	addi	a3,sp,464
ffffffffc020176c:	97b6                	add	a5,a5,a3
ffffffffc020176e:	e307ba03          	ld	s4,-464(a5)
    assert(slub_ready);
ffffffffc0201772:	0b05                	addi	s6,s6,1
ffffffffc0201774:	0b85                	addi	s7,s7,1
ffffffffc0201776:	0aa1                	addi	s5,s5,8
ffffffffc0201778:	0e070c63          	beqz	a4,ffffffffc0201870 <slub_test_sizes+0x1d8>
    if (size == 0) {
ffffffffc020177c:	f80a17e3          	bnez	s4,ffffffffc020170a <slub_test_sizes+0x72>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201780:	00002697          	auipc	a3,0x2
ffffffffc0201784:	fa068693          	addi	a3,a3,-96 # ffffffffc0203720 <best_fit_pmm_manager+0x378>
ffffffffc0201788:	00002617          	auipc	a2,0x2
ffffffffc020178c:	84060613          	addi	a2,a2,-1984 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201790:	0be00593          	li	a1,190
ffffffffc0201794:	00002517          	auipc	a0,0x2
ffffffffc0201798:	dfc50513          	addi	a0,a0,-516 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc020179c:	a3bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
ffffffffc02017a0:	85a2                	mv	a1,s0
ffffffffc02017a2:	4605                	li	a2,1
        }
    }
    for (size_t i = 0; i < count; i++) {
ffffffffc02017a4:	4575                	li	a0,29
        slub_test_read(objects[i], sizes[i], (unsigned char)i);
ffffffffc02017a6:	6198                	ld	a4,0(a1)
ffffffffc02017a8:	0ff87793          	zext.b	a5,a6
    for (size_t i = 0; i < size; i++) {
ffffffffc02017ac:	ce01                	beqz	a2,ffffffffc02017c4 <slub_test_sizes+0x12c>
ffffffffc02017ae:	963a                	add	a2,a2,a4
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02017b0:	00074683          	lbu	a3,0(a4)
ffffffffc02017b4:	04f69e63          	bne	a3,a5,ffffffffc0201810 <slub_test_sizes+0x178>
    for (size_t i = 0; i < size; i++) {
ffffffffc02017b8:	27c5                	addiw	a5,a5,17
ffffffffc02017ba:	0705                	addi	a4,a4,1
ffffffffc02017bc:	0ff7f793          	zext.b	a5,a5
ffffffffc02017c0:	fee618e3          	bne	a2,a4,ffffffffc02017b0 <slub_test_sizes+0x118>
    for (size_t i = 0; i < count; i++) {
ffffffffc02017c4:	0805                	addi	a6,a6,1
ffffffffc02017c6:	05a1                	addi	a1,a1,8
ffffffffc02017c8:	00a80663          	beq	a6,a0,ffffffffc02017d4 <slub_test_sizes+0x13c>
        slub_test_read(objects[i], sizes[i], (unsigned char)i);
ffffffffc02017cc:	0008b603          	ld	a2,0(a7)
ffffffffc02017d0:	08a1                	addi	a7,a7,8
ffffffffc02017d2:	bfd1                	j	ffffffffc02017a6 <slub_test_sizes+0x10e>
ffffffffc02017d4:	1c810913          	addi	s2,sp,456
    }
    for (size_t i = count; i > 0; i--) {
        slub_free(objects[i - 1]);
ffffffffc02017d8:	00093503          	ld	a0,0(s2)
ffffffffc02017dc:	d95ff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    for (size_t i = count; i > 0; i--) {
ffffffffc02017e0:	87ca                	mv	a5,s2
ffffffffc02017e2:	1961                	addi	s2,s2,-8
ffffffffc02017e4:	fe879ae3          	bne	a5,s0,ffffffffc02017d8 <slub_test_sizes+0x140>
    }
    assert(nr_free_pages() == before);
ffffffffc02017e8:	915ff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc02017ec:	06951263          	bne	a0,s1,ffffffffc0201850 <slub_test_sizes+0x1b8>
}
ffffffffc02017f0:	21813083          	ld	ra,536(sp)
ffffffffc02017f4:	21013403          	ld	s0,528(sp)
ffffffffc02017f8:	20813483          	ld	s1,520(sp)
ffffffffc02017fc:	20013903          	ld	s2,512(sp)
ffffffffc0201800:	79fe                	ld	s3,504(sp)
ffffffffc0201802:	7a5e                	ld	s4,496(sp)
ffffffffc0201804:	7abe                	ld	s5,488(sp)
ffffffffc0201806:	7b1e                	ld	s6,480(sp)
ffffffffc0201808:	6bfe                	ld	s7,472(sp)
ffffffffc020180a:	22010113          	addi	sp,sp,544
ffffffffc020180e:	8082                	ret
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201810:	00002697          	auipc	a3,0x2
ffffffffc0201814:	f4068693          	addi	a3,a3,-192 # ffffffffc0203750 <best_fit_pmm_manager+0x3a8>
ffffffffc0201818:	00001617          	auipc	a2,0x1
ffffffffc020181c:	7b060613          	addi	a2,a2,1968 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201820:	0c700593          	li	a1,199
ffffffffc0201824:	00002517          	auipc	a0,0x2
ffffffffc0201828:	d6c50513          	addi	a0,a0,-660 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc020182c:	9abfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0201830:	00002697          	auipc	a3,0x2
ffffffffc0201834:	d2068693          	addi	a3,a3,-736 # ffffffffc0203550 <best_fit_pmm_manager+0x1a8>
ffffffffc0201838:	00001617          	auipc	a2,0x1
ffffffffc020183c:	79060613          	addi	a2,a2,1936 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201840:	0ce00593          	li	a1,206
ffffffffc0201844:	00002517          	auipc	a0,0x2
ffffffffc0201848:	d4c50513          	addi	a0,a0,-692 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc020184c:	98bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0201850:	00002697          	auipc	a3,0x2
ffffffffc0201854:	f4068693          	addi	a3,a3,-192 # ffffffffc0203790 <best_fit_pmm_manager+0x3e8>
ffffffffc0201858:	00001617          	auipc	a2,0x1
ffffffffc020185c:	77060613          	addi	a2,a2,1904 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201860:	0eb00593          	li	a1,235
ffffffffc0201864:	00002517          	auipc	a0,0x2
ffffffffc0201868:	d2c50513          	addi	a0,a0,-724 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc020186c:	96bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0201870:	00002697          	auipc	a3,0x2
ffffffffc0201874:	dc068693          	addi	a3,a3,-576 # ffffffffc0203630 <best_fit_pmm_manager+0x288>
ffffffffc0201878:	00001617          	auipc	a2,0x1
ffffffffc020187c:	75060613          	addi	a2,a2,1872 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201880:	06e00593          	li	a1,110
ffffffffc0201884:	00002517          	auipc	a0,0x2
ffffffffc0201888:	d0c50513          	addi	a0,a0,-756 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc020188c:	94bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0201890 <slub_test_same_cache>:

static void
slub_test_same_cache(void) {
ffffffffc0201890:	99010113          	addi	sp,sp,-1648
ffffffffc0201894:	65213823          	sd	s2,1616(sp)
ffffffffc0201898:	63513c23          	sd	s5,1592(sp)
ffffffffc020189c:	63613823          	sd	s6,1584(sp)
ffffffffc02018a0:	63713423          	sd	s7,1576(sp)
ffffffffc02018a4:	61913c23          	sd	s9,1560(sp)
ffffffffc02018a8:	61a13823          	sd	s10,1552(sp)
ffffffffc02018ac:	61b13423          	sd	s11,1544(sp)
ffffffffc02018b0:	66113423          	sd	ra,1640(sp)
ffffffffc02018b4:	66813023          	sd	s0,1632(sp)
ffffffffc02018b8:	64913c23          	sd	s1,1624(sp)
ffffffffc02018bc:	65313423          	sd	s3,1608(sp)
ffffffffc02018c0:	65413023          	sd	s4,1600(sp)
ffffffffc02018c4:	63813023          	sd	s8,1568(sp)
    size_t before = nr_free_pages();
ffffffffc02018c8:	835ff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc02018cc:	e42a                	sd	a0,8(sp)
ffffffffc02018ce:	01810b93          	addi	s7,sp,24
ffffffffc02018d2:	04000c93          	li	s9,64
ffffffffc02018d6:	4d85                	li	s11,1
ffffffffc02018d8:	4d01                	li	s10,0
ffffffffc02018da:	00006917          	auipc	s2,0x6
ffffffffc02018de:	92e90913          	addi	s2,s2,-1746 # ffffffffc0207208 <slub_ready>
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc02018e2:	7afd                	lui	s5,0xfffff
    void *reused[SLUB_TEST_CAPACITY];
    void *second[SLUB_TEST_CAPACITY];
    size_t reused_count = 0;

    /* Fill one page. Every returned object must be distinct and writable. */
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
ffffffffc02018e4:	03f00b13          	li	s6,63
    assert(slub_ready);
ffffffffc02018e8:	00092783          	lw	a5,0(s2)
ffffffffc02018ec:	3c078b63          	beqz	a5,ffffffffc0201cc2 <slub_test_same_cache+0x432>
    if (size == 0) {
ffffffffc02018f0:	04000513          	li	a0,64
ffffffffc02018f4:	a21ff0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
        first[i] = slub_alloc(SLUB_TEST_OBJECT_SIZE);
ffffffffc02018f8:	00abb023          	sd	a0,0(s7)
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02018fc:	36050363          	beqz	a0,ffffffffc0201c62 <slub_test_same_cache+0x3d2>
ffffffffc0201900:	00f57413          	andi	s0,a0,15
ffffffffc0201904:	34041f63          	bnez	s0,ffffffffc0201c62 <slub_test_same_cache+0x3d2>
ffffffffc0201908:	0ffd7793          	zext.b	a5,s10
ffffffffc020190c:	872a                	mv	a4,a0
    for (size_t i = 0; i < size; i++) {
ffffffffc020190e:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0201912:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201916:	0ff6f793          	zext.b	a5,a3
ffffffffc020191a:	0705                	addi	a4,a4,1
ffffffffc020191c:	ff9799e3          	bne	a5,s9,ffffffffc020190e <slub_test_same_cache+0x7e>
        slub_test_write(first[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)i);
        if (i != 0) {
ffffffffc0201920:	020d0b63          	beqz	s10,ffffffffc0201956 <slub_test_same_cache+0xc6>
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc0201924:	6c62                	ld	s8,24(sp)
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0201926:	015577b3          	and	a5,a0,s5
ffffffffc020192a:	015c79b3          	and	s3,s8,s5
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc020192e:	41379a63          	bne	a5,s3,ffffffffc0201d42 <slub_test_same_cache+0x4b2>
ffffffffc0201932:	1004                	addi	s1,sp,32
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0201934:	04050693          	addi	a3,a0,64
ffffffffc0201938:	87a6                	mv	a5,s1
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc020193a:	8762                	mv	a4,s8
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc020193c:	00d77663          	bgeu	a4,a3,ffffffffc0201948 <slub_test_same_cache+0xb8>
ffffffffc0201940:	04070713          	addi	a4,a4,64
ffffffffc0201944:	2ee56f63          	bltu	a0,a4,ffffffffc0201c42 <slub_test_same_cache+0x3b2>
        }
        for (size_t j = 0; j < i; j++) {
ffffffffc0201948:	01778563          	beq	a5,s7,ffffffffc0201952 <slub_test_same_cache+0xc2>
            slub_test_disjoint(first[i], SLUB_TEST_OBJECT_SIZE,
ffffffffc020194c:	6398                	ld	a4,0(a5)
ffffffffc020194e:	07a1                	addi	a5,a5,8
ffffffffc0201950:	b7f5                	j	ffffffffc020193c <slub_test_same_cache+0xac>
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
ffffffffc0201952:	016d8963          	beq	s11,s6,ffffffffc0201964 <slub_test_same_cache+0xd4>
ffffffffc0201956:	2c85                	addiw	s9,s9,1
ffffffffc0201958:	0d05                	addi	s10,s10,1
ffffffffc020195a:	0d85                	addi	s11,s11,1
ffffffffc020195c:	0ba1                	addi	s7,s7,8
ffffffffc020195e:	0ffcfc93          	zext.b	s9,s9
ffffffffc0201962:	b759                	j	ffffffffc02018e8 <slub_test_same_cache+0x58>
                               first[j], SLUB_TEST_OBJECT_SIZE);
        }
    }
    assert(nr_free_pages() == before - 1);
ffffffffc0201964:	f98ff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0201968:	67a2                	ld	a5,8(sp)
ffffffffc020196a:	fff78a93          	addi	s5,a5,-1
ffffffffc020196e:	39551a63          	bne	a0,s5,ffffffffc0201d02 <slub_test_same_cache+0x472>
ffffffffc0201972:	21810d13          	addi	s10,sp,536
ffffffffc0201976:	02810b13          	addi	s6,sp,40
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc020197a:	8562                	mv	a0,s8
ffffffffc020197c:	a021                	j	ffffffffc0201984 <slub_test_same_cache+0xf4>

    /* Free alternate slots. Replacements must come from those slots only. */
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i += 2) {
        slub_free(first[i]);
ffffffffc020197e:	000b3503          	ld	a0,0(s6) # 10000 <kern_entry-0xffffffffc01f0000>
ffffffffc0201982:	0b41                	addi	s6,s6,16
ffffffffc0201984:	bedff0ef          	jal	ra,ffffffffc0201570 <slub_free>
        assert(nr_free_pages() == before - 1);
ffffffffc0201988:	f74ff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc020198c:	34aa9b63          	bne	s5,a0,ffffffffc0201ce2 <slub_test_same_cache+0x452>
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0201990:	ffab17e3          	bne	s6,s10,ffffffffc020197e <slub_test_same_cache+0xee>
ffffffffc0201994:	8526                	mv	a0,s1
ffffffffc0201996:	04100613          	li	a2,65
    }
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc020199a:	4585                	li	a1,1
ffffffffc020199c:	03f00813          	li	a6,63
        slub_test_read(first[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)i);
ffffffffc02019a0:	6118                	ld	a4,0(a0)
ffffffffc02019a2:	0ff5f793          	zext.b	a5,a1
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02019a6:	00074683          	lbu	a3,0(a4)
ffffffffc02019aa:	1cf69063          	bne	a3,a5,ffffffffc0201b6a <slub_test_same_cache+0x2da>
    for (size_t i = 0; i < size; i++) {
ffffffffc02019ae:	27c5                	addiw	a5,a5,17
ffffffffc02019b0:	0ff7f793          	zext.b	a5,a5
ffffffffc02019b4:	0705                	addi	a4,a4,1
ffffffffc02019b6:	fec798e3          	bne	a5,a2,ffffffffc02019a6 <slub_test_same_cache+0x116>
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc02019ba:	2789                	addiw	a5,a5,2
ffffffffc02019bc:	0589                	addi	a1,a1,2
ffffffffc02019be:	0541                	addi	a0,a0,16
ffffffffc02019c0:	0ff7f613          	zext.b	a2,a5
ffffffffc02019c4:	fd059ee3          	bne	a1,a6,ffffffffc02019a0 <slub_test_same_cache+0x110>
ffffffffc02019c8:	21010b13          	addi	s6,sp,528
ffffffffc02019cc:	8dda                	mv	s11,s6
ffffffffc02019ce:	09b00a13          	li	s4,155
    }
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc02019d2:	0db00b93          	li	s7,219
    assert(slub_ready);
ffffffffc02019d6:	00092783          	lw	a5,0(s2)
ffffffffc02019da:	2e078463          	beqz	a5,ffffffffc0201cc2 <slub_test_same_cache+0x432>
    if (size == 0) {
ffffffffc02019de:	04000513          	li	a0,64
ffffffffc02019e2:	933ff0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
ffffffffc02019e6:	8caa                	mv	s9,a0
        void *ptr = slub_alloc(SLUB_TEST_OBJECT_SIZE);
        bool was_freed = 0;
        for (size_t j = 0; j < SLUB_TEST_CAPACITY; j += 2) {
ffffffffc02019e8:	1034                	addi	a3,sp,40
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc02019ea:	87e2                	mv	a5,s8
        bool was_freed = 0;
ffffffffc02019ec:	4701                	li	a4,0
ffffffffc02019ee:	a019                	j	ffffffffc02019f4 <slub_test_same_cache+0x164>
            was_freed |= ptr == first[j];
ffffffffc02019f0:	629c                	ld	a5,0(a3)
ffffffffc02019f2:	06c1                	addi	a3,a3,16
ffffffffc02019f4:	419787b3          	sub	a5,a5,s9
ffffffffc02019f8:	0017b793          	seqz	a5,a5
ffffffffc02019fc:	8f5d                	or	a4,a4,a5
ffffffffc02019fe:	2701                	sext.w	a4,a4
        for (size_t j = 0; j < SLUB_TEST_CAPACITY; j += 2) {
ffffffffc0201a00:	ffa698e3          	bne	a3,s10,ffffffffc02019f0 <slub_test_same_cache+0x160>
        }
        assert(was_freed);
ffffffffc0201a04:	30070f63          	beqz	a4,ffffffffc0201d22 <slub_test_same_cache+0x492>
        for (size_t j = 0; j < reused_count; j++) {
ffffffffc0201a08:	87da                	mv	a5,s6
ffffffffc0201a0a:	c419                	beqz	s0,ffffffffc0201a18 <slub_test_same_cache+0x188>
            assert(ptr != reused[j]);
ffffffffc0201a0c:	6398                	ld	a4,0(a5)
ffffffffc0201a0e:	27970a63          	beq	a4,s9,ffffffffc0201c82 <slub_test_same_cache+0x3f2>
        for (size_t j = 0; j < reused_count; j++) {
ffffffffc0201a12:	07a1                	addi	a5,a5,8
ffffffffc0201a14:	ffb79ce3          	bne	a5,s11,ffffffffc0201a0c <slub_test_same_cache+0x17c>
        }
        reused[reused_count++] = ptr;
ffffffffc0201a18:	019db023          	sd	s9,0(s11)
ffffffffc0201a1c:	0405                	addi	s0,s0,1
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201a1e:	240c8263          	beqz	s9,ffffffffc0201c62 <slub_test_same_cache+0x3d2>
ffffffffc0201a22:	00fcf793          	andi	a5,s9,15
ffffffffc0201a26:	8766                	mv	a4,s9
ffffffffc0201a28:	22079d63          	bnez	a5,ffffffffc0201c62 <slub_test_same_cache+0x3d2>
ffffffffc0201a2c:	fc0a079b          	addiw	a5,s4,-64
ffffffffc0201a30:	0ff7f793          	zext.b	a5,a5
    for (size_t i = 0; i < size; i++) {
ffffffffc0201a34:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0201a38:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201a3c:	0ff6f793          	zext.b	a5,a3
ffffffffc0201a40:	0705                	addi	a4,a4,1
ffffffffc0201a42:	ff4799e3          	bne	a5,s4,ffffffffc0201a34 <slub_test_same_cache+0x1a4>
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0201a46:	2789                	addiw	a5,a5,2
ffffffffc0201a48:	0ff7fa13          	zext.b	s4,a5
ffffffffc0201a4c:	0da1                	addi	s11,s11,8
ffffffffc0201a4e:	f97a14e3          	bne	s4,s7,ffffffffc02019d6 <slub_test_same_cache+0x146>
        slub_test_write(ptr, SLUB_TEST_OBJECT_SIZE, (unsigned char)(i + 91));
    }
    assert(nr_free_pages() == before - 1);
ffffffffc0201a52:	eaaff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0201a56:	30aa9663          	bne	s5,a0,ffffffffc0201d62 <slub_test_same_cache+0x4d2>
ffffffffc0201a5a:	8526                	mv	a0,s1
ffffffffc0201a5c:	04100613          	li	a2,65
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0201a60:	4585                	li	a1,1
ffffffffc0201a62:	03f00813          	li	a6,63
        slub_test_read(first[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)i);
ffffffffc0201a66:	6118                	ld	a4,0(a0)
ffffffffc0201a68:	0ff5f793          	zext.b	a5,a1
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201a6c:	00074683          	lbu	a3,0(a4)
ffffffffc0201a70:	0ef69d63          	bne	a3,a5,ffffffffc0201b6a <slub_test_same_cache+0x2da>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201a74:	27c5                	addiw	a5,a5,17
ffffffffc0201a76:	0ff7f793          	zext.b	a5,a5
ffffffffc0201a7a:	0705                	addi	a4,a4,1
ffffffffc0201a7c:	fec798e3          	bne	a5,a2,ffffffffc0201a6c <slub_test_same_cache+0x1dc>
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0201a80:	2789                	addiw	a5,a5,2
ffffffffc0201a82:	0589                	addi	a1,a1,2
ffffffffc0201a84:	0541                	addi	a0,a0,16
ffffffffc0201a86:	0ff7f613          	zext.b	a2,a5
ffffffffc0201a8a:	fd059ee3          	bne	a1,a6,ffffffffc0201a66 <slub_test_same_cache+0x1d6>
ffffffffc0201a8e:	40810c13          	addi	s8,sp,1032
ffffffffc0201a92:	0c900d93          	li	s11,201
ffffffffc0201a96:	4d05                	li	s10,1
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0201a98:	7bfd                	lui	s7,0xfffff
    assert(slub_ready);
ffffffffc0201a9a:	00092783          	lw	a5,0(s2)
ffffffffc0201a9e:	22078263          	beqz	a5,ffffffffc0201cc2 <slub_test_same_cache+0x432>
    if (size == 0) {
ffffffffc0201aa2:	04000513          	li	a0,64
ffffffffc0201aa6:	86fff0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
    }

    /* A full slab forces a second page. Emptying one must spare the other. */
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
        second[i] = slub_alloc(SLUB_TEST_OBJECT_SIZE);
ffffffffc0201aaa:	00ac3023          	sd	a0,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201aae:	1a050a63          	beqz	a0,ffffffffc0201c62 <slub_test_same_cache+0x3d2>
ffffffffc0201ab2:	00f57793          	andi	a5,a0,15
ffffffffc0201ab6:	1a079663          	bnez	a5,ffffffffc0201c62 <slub_test_same_cache+0x3d2>
ffffffffc0201aba:	f88d079b          	addiw	a5,s10,-120
ffffffffc0201abe:	0ff7f793          	zext.b	a5,a5
ffffffffc0201ac2:	872a                	mv	a4,a0
    for (size_t i = 0; i < size; i++) {
ffffffffc0201ac4:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0201ac8:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201acc:	0ff6f793          	zext.b	a5,a3
ffffffffc0201ad0:	0705                	addi	a4,a4,1
ffffffffc0201ad2:	fefd99e3          	bne	s11,a5,ffffffffc0201ac4 <slub_test_same_cache+0x234>
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0201ad6:	01757533          	and	a0,a0,s7
        slub_test_write(second[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)(i + 137));
        assert(slub_test_page(second[i]) != slub_test_page(first[0]));
ffffffffc0201ada:	2aa98463          	beq	s3,a0,ffffffffc0201d82 <slub_test_same_cache+0x4f2>
        if (i != 0) {
ffffffffc0201ade:	4785                	li	a5,1
ffffffffc0201ae0:	00fd0c63          	beq	s10,a5,ffffffffc0201af8 <slub_test_same_cache+0x268>
            assert(slub_test_page(second[i]) == slub_test_page(second[0]));
ffffffffc0201ae4:	40813a03          	ld	s4,1032(sp)
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0201ae8:	017a77b3          	and	a5,s4,s7
            assert(slub_test_page(second[i]) == slub_test_page(second[0]));
ffffffffc0201aec:	2af51b63          	bne	a0,a5,ffffffffc0201da2 <slub_test_same_cache+0x512>
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
ffffffffc0201af0:	03f00793          	li	a5,63
ffffffffc0201af4:	00fd0863          	beq	s10,a5,ffffffffc0201b04 <slub_test_same_cache+0x274>
ffffffffc0201af8:	2d85                	addiw	s11,s11,1
ffffffffc0201afa:	0d05                	addi	s10,s10,1
ffffffffc0201afc:	0ffdfd93          	zext.b	s11,s11
ffffffffc0201b00:	0c21                	addi	s8,s8,8
ffffffffc0201b02:	bf61                	j	ffffffffc0201a9a <slub_test_same_cache+0x20a>
        }
    }
    assert(nr_free_pages() == before - 2);
ffffffffc0201b04:	df8ff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0201b08:	67a2                	ld	a5,8(sp)
ffffffffc0201b0a:	ffe78913          	addi	s2,a5,-2
ffffffffc0201b0e:	083c                	addi	a5,sp,24
ffffffffc0201b10:	1f878993          	addi	s3,a5,504
ffffffffc0201b14:	2b251763          	bne	a0,s2,ffffffffc0201dc2 <slub_test_same_cache+0x532>
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
        slub_free(first[i]);
ffffffffc0201b18:	6088                	ld	a0,0(s1)
ffffffffc0201b1a:	a57ff0ef          	jal	ra,ffffffffc0201570 <slub_free>
        assert(nr_free_pages() == before - 2);
ffffffffc0201b1e:	ddeff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0201b22:	2ca91063          	bne	s2,a0,ffffffffc0201de2 <slub_test_same_cache+0x552>
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0201b26:	04c1                	addi	s1,s1,16
ffffffffc0201b28:	ff3498e3          	bne	s1,s3,ffffffffc0201b18 <slub_test_same_cache+0x288>
ffffffffc0201b2c:	040e                	slli	s0,s0,0x3
ffffffffc0201b2e:	ff8b0793          	addi	a5,s6,-8
ffffffffc0201b32:	943e                	add	s0,s0,a5
    }
    for (size_t i = 0; i + 1 < reused_count; i++) {
ffffffffc0201b34:	048b0b63          	beq	s6,s0,ffffffffc0201b8a <slub_test_same_cache+0x2fa>
        slub_free(reused[i]);
ffffffffc0201b38:	000b3503          	ld	a0,0(s6)
        assert(nr_free_pages() == before - 2);
ffffffffc0201b3c:	0b21                	addi	s6,s6,8
        slub_free(reused[i]);
ffffffffc0201b3e:	a33ff0ef          	jal	ra,ffffffffc0201570 <slub_free>
        assert(nr_free_pages() == before - 2);
ffffffffc0201b42:	dbaff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0201b46:	fea907e3          	beq	s2,a0,ffffffffc0201b34 <slub_test_same_cache+0x2a4>
ffffffffc0201b4a:	00002697          	auipc	a3,0x2
ffffffffc0201b4e:	d5668693          	addi	a3,a3,-682 # ffffffffc02038a0 <best_fit_pmm_manager+0x4f8>
ffffffffc0201b52:	00001617          	auipc	a2,0x1
ffffffffc0201b56:	47660613          	addi	a2,a2,1142 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201b5a:	12e00593          	li	a1,302
ffffffffc0201b5e:	00002517          	auipc	a0,0x2
ffffffffc0201b62:	a3250513          	addi	a0,a0,-1486 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201b66:	e70fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201b6a:	00002697          	auipc	a3,0x2
ffffffffc0201b6e:	be668693          	addi	a3,a3,-1050 # ffffffffc0203750 <best_fit_pmm_manager+0x3a8>
ffffffffc0201b72:	00001617          	auipc	a2,0x1
ffffffffc0201b76:	45660613          	addi	a2,a2,1110 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201b7a:	0c700593          	li	a1,199
ffffffffc0201b7e:	00002517          	auipc	a0,0x2
ffffffffc0201b82:	a1250513          	addi	a0,a0,-1518 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201b86:	e50fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    }
    slub_free(reused[reused_count - 1]);
ffffffffc0201b8a:	8566                	mv	a0,s9
ffffffffc0201b8c:	9e5ff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    assert(nr_free_pages() == before - 1);
ffffffffc0201b90:	d6cff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0201b94:	26aa9763          	bne	s5,a0,ffffffffc0201e02 <slub_test_same_cache+0x572>
ffffffffc0201b98:	41010413          	addi	s0,sp,1040
ffffffffc0201b9c:	60010893          	addi	a7,sp,1536
ffffffffc0201ba0:	8522                	mv	a0,s0
            assert(slub_test_page(second[i]) == slub_test_page(second[0]));
ffffffffc0201ba2:	8752                	mv	a4,s4
    assert(nr_free_pages() == before - 1);
ffffffffc0201ba4:	08900593          	li	a1,137
ffffffffc0201ba8:	0c900613          	li	a2,201
ffffffffc0201bac:	87ae                	mv	a5,a1
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201bae:	00074683          	lbu	a3,0(a4)
ffffffffc0201bb2:	faf69ce3          	bne	a3,a5,ffffffffc0201b6a <slub_test_same_cache+0x2da>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201bb6:	27c5                	addiw	a5,a5,17
ffffffffc0201bb8:	0ff7f793          	zext.b	a5,a5
ffffffffc0201bbc:	0705                	addi	a4,a4,1
ffffffffc0201bbe:	fef618e3          	bne	a2,a5,ffffffffc0201bae <slub_test_same_cache+0x31e>
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
ffffffffc0201bc2:	2605                	addiw	a2,a2,1
ffffffffc0201bc4:	2585                	addiw	a1,a1,1
ffffffffc0201bc6:	0ff67613          	zext.b	a2,a2
ffffffffc0201bca:	0ff5f593          	zext.b	a1,a1
ffffffffc0201bce:	00a88563          	beq	a7,a0,ffffffffc0201bd8 <slub_test_same_cache+0x348>
        slub_test_read(second[i], SLUB_TEST_OBJECT_SIZE,
ffffffffc0201bd2:	6118                	ld	a4,0(a0)
ffffffffc0201bd4:	0521                	addi	a0,a0,8
ffffffffc0201bd6:	bfd9                	j	ffffffffc0201bac <slub_test_same_cache+0x31c>
ffffffffc0201bd8:	5f810493          	addi	s1,sp,1528
ffffffffc0201bdc:	a021                	j	ffffffffc0201be4 <slub_test_same_cache+0x354>
                       (unsigned char)(i + 137));
    }
    for (size_t i = 0; i + 1 < SLUB_TEST_CAPACITY; i++) {
        slub_free(second[i]);
ffffffffc0201bde:	00043a03          	ld	s4,0(s0)
ffffffffc0201be2:	0421                	addi	s0,s0,8
ffffffffc0201be4:	8552                	mv	a0,s4
ffffffffc0201be6:	98bff0ef          	jal	ra,ffffffffc0201570 <slub_free>
        assert(nr_free_pages() == before - 1);
ffffffffc0201bea:	d12ff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0201bee:	22aa9a63          	bne	s5,a0,ffffffffc0201e22 <slub_test_same_cache+0x592>
    for (size_t i = 0; i + 1 < SLUB_TEST_CAPACITY; i++) {
ffffffffc0201bf2:	fe9416e3          	bne	s0,s1,ffffffffc0201bde <slub_test_same_cache+0x34e>
    }
    slub_free(second[SLUB_TEST_CAPACITY - 1]);
ffffffffc0201bf6:	5f813503          	ld	a0,1528(sp)
ffffffffc0201bfa:	977ff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    assert(nr_free_pages() == before);
ffffffffc0201bfe:	cfeff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0201c02:	67a2                	ld	a5,8(sp)
ffffffffc0201c04:	08f51f63          	bne	a0,a5,ffffffffc0201ca2 <slub_test_same_cache+0x412>
}
ffffffffc0201c08:	66813083          	ld	ra,1640(sp)
ffffffffc0201c0c:	66013403          	ld	s0,1632(sp)
ffffffffc0201c10:	65813483          	ld	s1,1624(sp)
ffffffffc0201c14:	65013903          	ld	s2,1616(sp)
ffffffffc0201c18:	64813983          	ld	s3,1608(sp)
ffffffffc0201c1c:	64013a03          	ld	s4,1600(sp)
ffffffffc0201c20:	63813a83          	ld	s5,1592(sp)
ffffffffc0201c24:	63013b03          	ld	s6,1584(sp)
ffffffffc0201c28:	62813b83          	ld	s7,1576(sp)
ffffffffc0201c2c:	62013c03          	ld	s8,1568(sp)
ffffffffc0201c30:	61813c83          	ld	s9,1560(sp)
ffffffffc0201c34:	61013d03          	ld	s10,1552(sp)
ffffffffc0201c38:	60813d83          	ld	s11,1544(sp)
ffffffffc0201c3c:	67010113          	addi	sp,sp,1648
ffffffffc0201c40:	8082                	ret
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0201c42:	00002697          	auipc	a3,0x2
ffffffffc0201c46:	90e68693          	addi	a3,a3,-1778 # ffffffffc0203550 <best_fit_pmm_manager+0x1a8>
ffffffffc0201c4a:	00001617          	auipc	a2,0x1
ffffffffc0201c4e:	37e60613          	addi	a2,a2,894 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201c52:	0ce00593          	li	a1,206
ffffffffc0201c56:	00002517          	auipc	a0,0x2
ffffffffc0201c5a:	93a50513          	addi	a0,a0,-1734 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201c5e:	d78fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201c62:	00002697          	auipc	a3,0x2
ffffffffc0201c66:	abe68693          	addi	a3,a3,-1346 # ffffffffc0203720 <best_fit_pmm_manager+0x378>
ffffffffc0201c6a:	00001617          	auipc	a2,0x1
ffffffffc0201c6e:	35e60613          	addi	a2,a2,862 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201c72:	0be00593          	li	a1,190
ffffffffc0201c76:	00002517          	auipc	a0,0x2
ffffffffc0201c7a:	91a50513          	addi	a0,a0,-1766 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201c7e:	d58fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
            assert(ptr != reused[j]);
ffffffffc0201c82:	00002697          	auipc	a3,0x2
ffffffffc0201c86:	b9668693          	addi	a3,a3,-1130 # ffffffffc0203818 <best_fit_pmm_manager+0x470>
ffffffffc0201c8a:	00001617          	auipc	a2,0x1
ffffffffc0201c8e:	33e60613          	addi	a2,a2,830 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201c92:	11400593          	li	a1,276
ffffffffc0201c96:	00002517          	auipc	a0,0x2
ffffffffc0201c9a:	8fa50513          	addi	a0,a0,-1798 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201c9e:	d38fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0201ca2:	00002697          	auipc	a3,0x2
ffffffffc0201ca6:	aee68693          	addi	a3,a3,-1298 # ffffffffc0203790 <best_fit_pmm_manager+0x3e8>
ffffffffc0201caa:	00001617          	auipc	a2,0x1
ffffffffc0201cae:	31e60613          	addi	a2,a2,798 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201cb2:	13b00593          	li	a1,315
ffffffffc0201cb6:	00002517          	auipc	a0,0x2
ffffffffc0201cba:	8da50513          	addi	a0,a0,-1830 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201cbe:	d18fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0201cc2:	00002697          	auipc	a3,0x2
ffffffffc0201cc6:	96e68693          	addi	a3,a3,-1682 # ffffffffc0203630 <best_fit_pmm_manager+0x288>
ffffffffc0201cca:	00001617          	auipc	a2,0x1
ffffffffc0201cce:	2fe60613          	addi	a2,a2,766 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201cd2:	06e00593          	li	a1,110
ffffffffc0201cd6:	00002517          	auipc	a0,0x2
ffffffffc0201cda:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201cde:	cf8fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nr_free_pages() == before - 1);
ffffffffc0201ce2:	00002697          	auipc	a3,0x2
ffffffffc0201ce6:	b0668693          	addi	a3,a3,-1274 # ffffffffc02037e8 <best_fit_pmm_manager+0x440>
ffffffffc0201cea:	00001617          	auipc	a2,0x1
ffffffffc0201cee:	2de60613          	addi	a2,a2,734 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201cf2:	10700593          	li	a1,263
ffffffffc0201cf6:	00002517          	auipc	a0,0x2
ffffffffc0201cfa:	89a50513          	addi	a0,a0,-1894 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201cfe:	cd8fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0201d02:	00002697          	auipc	a3,0x2
ffffffffc0201d06:	ae668693          	addi	a3,a3,-1306 # ffffffffc02037e8 <best_fit_pmm_manager+0x440>
ffffffffc0201d0a:	00001617          	auipc	a2,0x1
ffffffffc0201d0e:	2be60613          	addi	a2,a2,702 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201d12:	10200593          	li	a1,258
ffffffffc0201d16:	00002517          	auipc	a0,0x2
ffffffffc0201d1a:	87a50513          	addi	a0,a0,-1926 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201d1e:	cb8fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(was_freed);
ffffffffc0201d22:	00002697          	auipc	a3,0x2
ffffffffc0201d26:	ae668693          	addi	a3,a3,-1306 # ffffffffc0203808 <best_fit_pmm_manager+0x460>
ffffffffc0201d2a:	00001617          	auipc	a2,0x1
ffffffffc0201d2e:	29e60613          	addi	a2,a2,670 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201d32:	11200593          	li	a1,274
ffffffffc0201d36:	00002517          	auipc	a0,0x2
ffffffffc0201d3a:	85a50513          	addi	a0,a0,-1958 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201d3e:	c98fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc0201d42:	00002697          	auipc	a3,0x2
ffffffffc0201d46:	a6e68693          	addi	a3,a3,-1426 # ffffffffc02037b0 <best_fit_pmm_manager+0x408>
ffffffffc0201d4a:	00001617          	auipc	a2,0x1
ffffffffc0201d4e:	27e60613          	addi	a2,a2,638 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201d52:	0fb00593          	li	a1,251
ffffffffc0201d56:	00002517          	auipc	a0,0x2
ffffffffc0201d5a:	83a50513          	addi	a0,a0,-1990 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201d5e:	c78fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0201d62:	00002697          	auipc	a3,0x2
ffffffffc0201d66:	a8668693          	addi	a3,a3,-1402 # ffffffffc02037e8 <best_fit_pmm_manager+0x440>
ffffffffc0201d6a:	00001617          	auipc	a2,0x1
ffffffffc0201d6e:	25e60613          	addi	a2,a2,606 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201d72:	11900593          	li	a1,281
ffffffffc0201d76:	00002517          	auipc	a0,0x2
ffffffffc0201d7a:	81a50513          	addi	a0,a0,-2022 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201d7e:	c58fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(slub_test_page(second[i]) != slub_test_page(first[0]));
ffffffffc0201d82:	00002697          	auipc	a3,0x2
ffffffffc0201d86:	aae68693          	addi	a3,a3,-1362 # ffffffffc0203830 <best_fit_pmm_manager+0x488>
ffffffffc0201d8a:	00001617          	auipc	a2,0x1
ffffffffc0201d8e:	23e60613          	addi	a2,a2,574 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201d92:	12200593          	li	a1,290
ffffffffc0201d96:	00001517          	auipc	a0,0x1
ffffffffc0201d9a:	7fa50513          	addi	a0,a0,2042 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201d9e:	c38fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
            assert(slub_test_page(second[i]) == slub_test_page(second[0]));
ffffffffc0201da2:	00002697          	auipc	a3,0x2
ffffffffc0201da6:	ac668693          	addi	a3,a3,-1338 # ffffffffc0203868 <best_fit_pmm_manager+0x4c0>
ffffffffc0201daa:	00001617          	auipc	a2,0x1
ffffffffc0201dae:	21e60613          	addi	a2,a2,542 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201db2:	12400593          	li	a1,292
ffffffffc0201db6:	00001517          	auipc	a0,0x1
ffffffffc0201dba:	7da50513          	addi	a0,a0,2010 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201dbe:	c18fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc0201dc2:	00002697          	auipc	a3,0x2
ffffffffc0201dc6:	ade68693          	addi	a3,a3,-1314 # ffffffffc02038a0 <best_fit_pmm_manager+0x4f8>
ffffffffc0201dca:	00001617          	auipc	a2,0x1
ffffffffc0201dce:	1fe60613          	addi	a2,a2,510 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201dd2:	12700593          	li	a1,295
ffffffffc0201dd6:	00001517          	auipc	a0,0x1
ffffffffc0201dda:	7ba50513          	addi	a0,a0,1978 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201dde:	bf8fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nr_free_pages() == before - 2);
ffffffffc0201de2:	00002697          	auipc	a3,0x2
ffffffffc0201de6:	abe68693          	addi	a3,a3,-1346 # ffffffffc02038a0 <best_fit_pmm_manager+0x4f8>
ffffffffc0201dea:	00001617          	auipc	a2,0x1
ffffffffc0201dee:	1de60613          	addi	a2,a2,478 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201df2:	12a00593          	li	a1,298
ffffffffc0201df6:	00001517          	auipc	a0,0x1
ffffffffc0201dfa:	79a50513          	addi	a0,a0,1946 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201dfe:	bd8fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0201e02:	00002697          	auipc	a3,0x2
ffffffffc0201e06:	9e668693          	addi	a3,a3,-1562 # ffffffffc02037e8 <best_fit_pmm_manager+0x440>
ffffffffc0201e0a:	00001617          	auipc	a2,0x1
ffffffffc0201e0e:	1be60613          	addi	a2,a2,446 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201e12:	13100593          	li	a1,305
ffffffffc0201e16:	00001517          	auipc	a0,0x1
ffffffffc0201e1a:	77a50513          	addi	a0,a0,1914 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201e1e:	bb8fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nr_free_pages() == before - 1);
ffffffffc0201e22:	00002697          	auipc	a3,0x2
ffffffffc0201e26:	9c668693          	addi	a3,a3,-1594 # ffffffffc02037e8 <best_fit_pmm_manager+0x440>
ffffffffc0201e2a:	00001617          	auipc	a2,0x1
ffffffffc0201e2e:	19e60613          	addi	a2,a2,414 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0201e32:	13800593          	li	a1,312
ffffffffc0201e36:	00001517          	auipc	a0,0x1
ffffffffc0201e3a:	75a50513          	addi	a0,a0,1882 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0201e3e:	b98fe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0201e42 <slub_test_mixed>:
    free_pages(page, 1);
    assert(nr_free_pages() == before);
}

static void
slub_test_mixed(void) {
ffffffffc0201e42:	b4010113          	addi	sp,sp,-1216
ffffffffc0201e46:	4a813823          	sd	s0,1200(sp)
ffffffffc0201e4a:	4a913423          	sd	s1,1192(sp)
ffffffffc0201e4e:	4b213023          	sd	s2,1184(sp)
ffffffffc0201e52:	49313c23          	sd	s3,1176(sp)
ffffffffc0201e56:	49413823          	sd	s4,1168(sp)
ffffffffc0201e5a:	49513423          	sd	s5,1160(sp)
ffffffffc0201e5e:	49613023          	sd	s6,1152(sp)
ffffffffc0201e62:	47713c23          	sd	s7,1144(sp)
ffffffffc0201e66:	47813823          	sd	s8,1136(sp)
ffffffffc0201e6a:	47913423          	sd	s9,1128(sp)
ffffffffc0201e6e:	47a13023          	sd	s10,1120(sp)
ffffffffc0201e72:	45b13c23          	sd	s11,1112(sp)
ffffffffc0201e76:	4a113c23          	sd	ra,1208(sp)

    for (size_t i = 0; i < count; i++) {
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
                   i == SLUB_TEST_CAPACITY + 1 ? 1 :
                   i == SLUB_TEST_CAPACITY + 2 ? 255 :
                   i == SLUB_TEST_CAPACITY + 3 ? slub_sizes[SLUB_CACHE_COUNT - 1] :
ffffffffc0201e7a:	6a85                	lui	s5,0x1
    size_t before = nr_free_pages();
ffffffffc0201e7c:	a80ff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0201e80:	1c00                	addi	s0,sp,560
ffffffffc0201e82:	e42a                	sd	a0,8(sp)
ffffffffc0201e84:	01010d93          	addi	s11,sp,16
ffffffffc0201e88:	8ca2                	mv	s9,s0
ffffffffc0201e8a:	4b85                	li	s7,1
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
ffffffffc0201e8c:	04000d13          	li	s10,64
ffffffffc0201e90:	00005917          	auipc	s2,0x5
ffffffffc0201e94:	37890913          	addi	s2,s2,888 # ffffffffc0207208 <slub_ready>
                   slub_sizes[SLUB_CACHE_COUNT - 1] + 1;
        objects[i] = slub_alloc(sizes[i]);
        slub_test_write(objects[i], sizes[i], (unsigned char)(i + 51));
        for (size_t j = 0; j < i; j++) {
ffffffffc0201e98:	4485                	li	s1,1
    for (size_t i = 0; i < count; i++) {
ffffffffc0201e9a:	04400993          	li	s3,68
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
ffffffffc0201e9e:	03f00a13          	li	s4,63
ffffffffc0201ea2:	04000b13          	li	s6,64
                   i == SLUB_TEST_CAPACITY + 2 ? 255 :
ffffffffc0201ea6:	04100c13          	li	s8,65
                   i == SLUB_TEST_CAPACITY + 3 ? slub_sizes[SLUB_CACHE_COUNT - 1] :
ffffffffc0201eaa:	fc1a8a93          	addi	s5,s5,-63 # fc1 <kern_entry-0xffffffffc01ff03f>
    assert(slub_ready);
ffffffffc0201eae:	00092783          	lw	a5,0(s2)
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
ffffffffc0201eb2:	01acb023          	sd	s10,0(s9)
    assert(slub_ready);
ffffffffc0201eb6:	1c078963          	beqz	a5,ffffffffc0202088 <slub_test_mixed+0x246>
    if (size == 0) {
ffffffffc0201eba:	856a                	mv	a0,s10
ffffffffc0201ebc:	c58ff0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
        objects[i] = slub_alloc(sizes[i]);
ffffffffc0201ec0:	00adb023          	sd	a0,0(s11)
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201ec4:	1e050263          	beqz	a0,ffffffffc02020a8 <slub_test_mixed+0x266>
ffffffffc0201ec8:	00f57793          	andi	a5,a0,15
ffffffffc0201ecc:	1c079e63          	bnez	a5,ffffffffc02020a8 <slub_test_mixed+0x266>
ffffffffc0201ed0:	032b879b          	addiw	a5,s7,50
ffffffffc0201ed4:	0ff7f793          	zext.b	a5,a5
ffffffffc0201ed8:	01a50633          	add	a2,a0,s10
ffffffffc0201edc:	872a                	mv	a4,a0
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0201ede:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201ee2:	27c5                	addiw	a5,a5,17
ffffffffc0201ee4:	0705                	addi	a4,a4,1
ffffffffc0201ee6:	0ff7f793          	zext.b	a5,a5
ffffffffc0201eea:	fec71ae3          	bne	a4,a2,ffffffffc0201ede <slub_test_mixed+0x9c>
        for (size_t j = 0; j < i; j++) {
ffffffffc0201eee:	029b8363          	beq	s7,s1,ffffffffc0201f14 <slub_test_mixed+0xd2>
ffffffffc0201ef2:	86a2                	mv	a3,s0
ffffffffc0201ef4:	081c                	addi	a5,sp,16
    uintptr_t a_start = (uintptr_t)a, b_start = (uintptr_t)b;
ffffffffc0201ef6:	6398                	ld	a4,0(a5)
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0201ef8:	00c77663          	bgeu	a4,a2,ffffffffc0201f04 <slub_test_mixed+0xc2>
ffffffffc0201efc:	628c                	ld	a1,0(a3)
ffffffffc0201efe:	972e                	add	a4,a4,a1
ffffffffc0201f00:	10e56463          	bltu	a0,a4,ffffffffc0202008 <slub_test_mixed+0x1c6>
        for (size_t j = 0; j < i; j++) {
ffffffffc0201f04:	07a1                	addi	a5,a5,8
ffffffffc0201f06:	06a1                	addi	a3,a3,8
ffffffffc0201f08:	ffb797e3          	bne	a5,s11,ffffffffc0201ef6 <slub_test_mixed+0xb4>
    for (size_t i = 0; i < count; i++) {
ffffffffc0201f0c:	033b8a63          	beq	s7,s3,ffffffffc0201f40 <slub_test_mixed+0xfe>
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
ffffffffc0201f10:	017a6863          	bltu	s4,s7,ffffffffc0201f20 <slub_test_mixed+0xde>
ffffffffc0201f14:	04000d13          	li	s10,64
ffffffffc0201f18:	0ca1                	addi	s9,s9,8
ffffffffc0201f1a:	0b85                	addi	s7,s7,1
ffffffffc0201f1c:	0da1                	addi	s11,s11,8
ffffffffc0201f1e:	bf41                	j	ffffffffc0201eae <slub_test_mixed+0x6c>
                   i == SLUB_TEST_CAPACITY + 1 ? 1 :
ffffffffc0201f20:	4d05                	li	s10,1
ffffffffc0201f22:	ff6b8be3          	beq	s7,s6,ffffffffc0201f18 <slub_test_mixed+0xd6>
                   i == SLUB_TEST_CAPACITY + 2 ? 255 :
ffffffffc0201f26:	0ff00d13          	li	s10,255
ffffffffc0201f2a:	ff8b87e3          	beq	s7,s8,ffffffffc0201f18 <slub_test_mixed+0xd6>
                   i == SLUB_TEST_CAPACITY + 3 ? slub_sizes[SLUB_CACHE_COUNT - 1] :
ffffffffc0201f2e:	6705                	lui	a4,0x1
ffffffffc0201f30:	04200793          	li	a5,66
ffffffffc0201f34:	fc070d13          	addi	s10,a4,-64 # fc0 <kern_entry-0xffffffffc01ff040>
ffffffffc0201f38:	fefb80e3          	beq	s7,a5,ffffffffc0201f18 <slub_test_mixed+0xd6>
ffffffffc0201f3c:	8d56                	mv	s10,s5
ffffffffc0201f3e:	bfe9                	j	ffffffffc0201f18 <slub_test_mixed+0xd6>
            slub_test_disjoint(objects[i], sizes[i], objects[j], sizes[j]);
        }
    }
    assert(slub_test_page(objects[0]) !=
ffffffffc0201f40:	64c2                	ld	s1,16(sp)
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0201f42:	20813783          	ld	a5,520(sp)
ffffffffc0201f46:	777d                	lui	a4,0xfffff
ffffffffc0201f48:	00e4f6b3          	and	a3,s1,a4
ffffffffc0201f4c:	8ff9                	and	a5,a5,a4
ffffffffc0201f4e:	01810913          	addi	s2,sp,24
ffffffffc0201f52:	23810993          	addi	s3,sp,568
    assert(slub_test_page(objects[0]) !=
ffffffffc0201f56:	10d78963          	beq	a5,a3,ffffffffc0202068 <slub_test_mixed+0x226>
           slub_test_page(objects[SLUB_TEST_CAPACITY]));
    for (size_t i = 1; i < count; i += 2) {
        slub_free(objects[i]);
ffffffffc0201f5a:	00093503          	ld	a0,0(s2)
    for (size_t i = 1; i < count; i += 2) {
ffffffffc0201f5e:	0941                	addi	s2,s2,16
        slub_free(objects[i]);
ffffffffc0201f60:	e10ff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    for (size_t i = 1; i < count; i += 2) {
ffffffffc0201f64:	ff391be3          	bne	s2,s3,ffffffffc0201f5a <slub_test_mixed+0x118>
ffffffffc0201f68:	1008                	addi	a0,sp,32
ffffffffc0201f6a:	22040813          	addi	a6,s0,544
ffffffffc0201f6e:	03300593          	li	a1,51
    }
    for (size_t i = 0; i < count; i += 2) {
        slub_test_read(objects[i], sizes[i], (unsigned char)(i + 51));
ffffffffc0201f72:	6010                	ld	a2,0(s0)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201f74:	ce11                	beqz	a2,ffffffffc0201f90 <slub_test_mixed+0x14e>
ffffffffc0201f76:	8726                	mv	a4,s1
ffffffffc0201f78:	9626                	add	a2,a2,s1
ffffffffc0201f7a:	87ae                	mv	a5,a1
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201f7c:	00074683          	lbu	a3,0(a4) # fffffffffffff000 <end+0x3fdf7df4>
ffffffffc0201f80:	0af69463          	bne	a3,a5,ffffffffc0202028 <slub_test_mixed+0x1e6>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201f84:	27c5                	addiw	a5,a5,17
ffffffffc0201f86:	0705                	addi	a4,a4,1
ffffffffc0201f88:	0ff7f793          	zext.b	a5,a5
ffffffffc0201f8c:	fec718e3          	bne	a4,a2,ffffffffc0201f7c <slub_test_mixed+0x13a>
    for (size_t i = 0; i < count; i += 2) {
ffffffffc0201f90:	2589                	addiw	a1,a1,2
ffffffffc0201f92:	0441                	addi	s0,s0,16
ffffffffc0201f94:	0ff5f593          	zext.b	a1,a1
ffffffffc0201f98:	00880563          	beq	a6,s0,ffffffffc0201fa2 <slub_test_mixed+0x160>
        slub_test_read(objects[i], sizes[i], (unsigned char)(i + 51));
ffffffffc0201f9c:	6104                	ld	s1,0(a0)
ffffffffc0201f9e:	0541                	addi	a0,a0,16
ffffffffc0201fa0:	bfc9                	j	ffffffffc0201f72 <slub_test_mixed+0x130>
ffffffffc0201fa2:	1400                	addi	s0,sp,544
ffffffffc0201fa4:	00810913          	addi	s2,sp,8
    for (size_t i = 0; i < count; i += 2) {
ffffffffc0201fa8:	04200493          	li	s1,66
    }
    for (size_t i = count; i > 0; i--) {
ffffffffc0201fac:	00890c63          	beq	s2,s0,ffffffffc0201fc4 <slub_test_mixed+0x182>
        if ((i - 1) % 2 == 0) {
ffffffffc0201fb0:	0014f793          	andi	a5,s1,1
ffffffffc0201fb4:	e781                	bnez	a5,ffffffffc0201fbc <slub_test_mixed+0x17a>
            slub_free(objects[i - 1]);
ffffffffc0201fb6:	6008                	ld	a0,0(s0)
ffffffffc0201fb8:	db8ff0ef          	jal	ra,ffffffffc0201570 <slub_free>
ffffffffc0201fbc:	1461                	addi	s0,s0,-8
ffffffffc0201fbe:	14fd                	addi	s1,s1,-1
    for (size_t i = count; i > 0; i--) {
ffffffffc0201fc0:	fe8918e3          	bne	s2,s0,ffffffffc0201fb0 <slub_test_mixed+0x16e>
        }
    }
    assert(nr_free_pages() == before);
ffffffffc0201fc4:	938ff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0201fc8:	67a2                	ld	a5,8(sp)
ffffffffc0201fca:	06f51f63          	bne	a0,a5,ffffffffc0202048 <slub_test_mixed+0x206>
}
ffffffffc0201fce:	4b813083          	ld	ra,1208(sp)
ffffffffc0201fd2:	4b013403          	ld	s0,1200(sp)
ffffffffc0201fd6:	4a813483          	ld	s1,1192(sp)
ffffffffc0201fda:	4a013903          	ld	s2,1184(sp)
ffffffffc0201fde:	49813983          	ld	s3,1176(sp)
ffffffffc0201fe2:	49013a03          	ld	s4,1168(sp)
ffffffffc0201fe6:	48813a83          	ld	s5,1160(sp)
ffffffffc0201fea:	48013b03          	ld	s6,1152(sp)
ffffffffc0201fee:	47813b83          	ld	s7,1144(sp)
ffffffffc0201ff2:	47013c03          	ld	s8,1136(sp)
ffffffffc0201ff6:	46813c83          	ld	s9,1128(sp)
ffffffffc0201ffa:	46013d03          	ld	s10,1120(sp)
ffffffffc0201ffe:	45813d83          	ld	s11,1112(sp)
ffffffffc0202002:	4c010113          	addi	sp,sp,1216
ffffffffc0202006:	8082                	ret
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0202008:	00001697          	auipc	a3,0x1
ffffffffc020200c:	54868693          	addi	a3,a3,1352 # ffffffffc0203550 <best_fit_pmm_manager+0x1a8>
ffffffffc0202010:	00001617          	auipc	a2,0x1
ffffffffc0202014:	fb860613          	addi	a2,a2,-72 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202018:	0ce00593          	li	a1,206
ffffffffc020201c:	00001517          	auipc	a0,0x1
ffffffffc0202020:	57450513          	addi	a0,a0,1396 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202024:	9b2fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0202028:	00001697          	auipc	a3,0x1
ffffffffc020202c:	72868693          	addi	a3,a3,1832 # ffffffffc0203750 <best_fit_pmm_manager+0x3a8>
ffffffffc0202030:	00001617          	auipc	a2,0x1
ffffffffc0202034:	f9860613          	addi	a2,a2,-104 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202038:	0c700593          	li	a1,199
ffffffffc020203c:	00001517          	auipc	a0,0x1
ffffffffc0202040:	55450513          	addi	a0,a0,1364 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202044:	992fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0202048:	00001697          	auipc	a3,0x1
ffffffffc020204c:	74868693          	addi	a3,a3,1864 # ffffffffc0203790 <best_fit_pmm_manager+0x3e8>
ffffffffc0202050:	00001617          	auipc	a2,0x1
ffffffffc0202054:	f7860613          	addi	a2,a2,-136 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202058:	1b000593          	li	a1,432
ffffffffc020205c:	00001517          	auipc	a0,0x1
ffffffffc0202060:	53450513          	addi	a0,a0,1332 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202064:	972fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_test_page(objects[0]) !=
ffffffffc0202068:	00002697          	auipc	a3,0x2
ffffffffc020206c:	85868693          	addi	a3,a3,-1960 # ffffffffc02038c0 <best_fit_pmm_manager+0x518>
ffffffffc0202070:	00001617          	auipc	a2,0x1
ffffffffc0202074:	f5860613          	addi	a2,a2,-168 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202078:	1a300593          	li	a1,419
ffffffffc020207c:	00001517          	auipc	a0,0x1
ffffffffc0202080:	51450513          	addi	a0,a0,1300 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202084:	952fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0202088:	00001697          	auipc	a3,0x1
ffffffffc020208c:	5a868693          	addi	a3,a3,1448 # ffffffffc0203630 <best_fit_pmm_manager+0x288>
ffffffffc0202090:	00001617          	auipc	a2,0x1
ffffffffc0202094:	f3860613          	addi	a2,a2,-200 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202098:	06e00593          	li	a1,110
ffffffffc020209c:	00001517          	auipc	a0,0x1
ffffffffc02020a0:	4f450513          	addi	a0,a0,1268 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02020a4:	932fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02020a8:	00001697          	auipc	a3,0x1
ffffffffc02020ac:	67868693          	addi	a3,a3,1656 # ffffffffc0203720 <best_fit_pmm_manager+0x378>
ffffffffc02020b0:	00001617          	auipc	a2,0x1
ffffffffc02020b4:	f1860613          	addi	a2,a2,-232 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02020b8:	0be00593          	li	a1,190
ffffffffc02020bc:	00001517          	auipc	a0,0x1
ffffffffc02020c0:	4d450513          	addi	a0,a0,1236 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02020c4:	912fe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02020c8 <slub_check>:

void
slub_check(void) {
ffffffffc02020c8:	7175                	addi	sp,sp,-144
ffffffffc02020ca:	fca6                	sd	s1,120(sp)
    assert(slub_ready);
ffffffffc02020cc:	00005497          	auipc	s1,0x5
ffffffffc02020d0:	13c48493          	addi	s1,s1,316 # ffffffffc0207208 <slub_ready>
ffffffffc02020d4:	409c                	lw	a5,0(s1)
slub_check(void) {
ffffffffc02020d6:	e506                	sd	ra,136(sp)
ffffffffc02020d8:	e122                	sd	s0,128(sp)
ffffffffc02020da:	f8ca                	sd	s2,112(sp)
ffffffffc02020dc:	f4ce                	sd	s3,104(sp)
ffffffffc02020de:	f0d2                	sd	s4,96(sp)
ffffffffc02020e0:	ecd6                	sd	s5,88(sp)
ffffffffc02020e2:	e8da                	sd	s6,80(sp)
ffffffffc02020e4:	e4de                	sd	s7,72(sp)
ffffffffc02020e6:	e0e2                	sd	s8,64(sp)
ffffffffc02020e8:	fc66                	sd	s9,56(sp)
ffffffffc02020ea:	f86a                	sd	s10,48(sp)
ffffffffc02020ec:	f46e                	sd	s11,40(sp)
    assert(slub_ready);
ffffffffc02020ee:	76078d63          	beqz	a5,ffffffffc0202868 <slub_check+0x7a0>
    size_t free_before = nr_free_pages();
ffffffffc02020f2:	80aff0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc02020f6:	8aaa                	mv	s5,a0
    cprintf("slub test: size classes, alignment and object isolation\n");
ffffffffc02020f8:	00002517          	auipc	a0,0x2
ffffffffc02020fc:	81850513          	addi	a0,a0,-2024 # ffffffffc0203910 <best_fit_pmm_manager+0x568>
    size_t free_before = nr_free_pages();
ffffffffc0202100:	e456                	sd	s5,8(sp)
    cprintf("slub test: size classes, alignment and object isolation\n");
ffffffffc0202102:	85efe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    slub_test_sizes();
ffffffffc0202106:	d92ff0ef          	jal	ra,ffffffffc0201698 <slub_test_sizes>
    cprintf("slub test: freelist, slab extension and independent page reclaim\n");
ffffffffc020210a:	00002517          	auipc	a0,0x2
ffffffffc020210e:	84650513          	addi	a0,a0,-1978 # ffffffffc0203950 <best_fit_pmm_manager+0x5a8>
ffffffffc0202112:	84efe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    slub_test_same_cache();
ffffffffc0202116:	f7aff0ef          	jal	ra,ffffffffc0201890 <slub_test_same_cache>
    cprintf("slub test: cache isolation and pointer-based release\n");
ffffffffc020211a:	00002517          	auipc	a0,0x2
ffffffffc020211e:	87e50513          	addi	a0,a0,-1922 # ffffffffc0203998 <best_fit_pmm_manager+0x5f0>
ffffffffc0202122:	83efe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0202126:	fd7fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
    assert(slub_ready);
ffffffffc020212a:	409c                	lw	a5,0(s1)
    size_t before = nr_free_pages();
ffffffffc020212c:	8a2a                	mv	s4,a0
    assert(slub_ready);
ffffffffc020212e:	4c078d63          	beqz	a5,ffffffffc0202608 <slub_check+0x540>
    if (size == 0) {
ffffffffc0202132:	02000513          	li	a0,32
ffffffffc0202136:	9deff0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
    assert(slub_ready);
ffffffffc020213a:	409c                	lw	a5,0(s1)
ffffffffc020213c:	89aa                	mv	s3,a0
ffffffffc020213e:	4c078563          	beqz	a5,ffffffffc0202608 <slub_check+0x540>
    if (size == 0) {
ffffffffc0202142:	02000513          	li	a0,32
ffffffffc0202146:	9ceff0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
    assert(slub_ready);
ffffffffc020214a:	409c                	lw	a5,0(s1)
ffffffffc020214c:	8daa                	mv	s11,a0
ffffffffc020214e:	4a078d63          	beqz	a5,ffffffffc0202608 <slub_check+0x540>
    if (size == 0) {
ffffffffc0202152:	10000513          	li	a0,256
ffffffffc0202156:	9beff0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
    assert(slub_ready);
ffffffffc020215a:	409c                	lw	a5,0(s1)
ffffffffc020215c:	842a                	mv	s0,a0
ffffffffc020215e:	4a078563          	beqz	a5,ffffffffc0202608 <slub_check+0x540>
    if (size == 0) {
ffffffffc0202162:	10000513          	li	a0,256
ffffffffc0202166:	9aeff0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
ffffffffc020216a:	892a                	mv	s2,a0
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc020216c:	46098e63          	beqz	s3,ffffffffc02025e8 <slub_check+0x520>
ffffffffc0202170:	00f9f793          	andi	a5,s3,15
ffffffffc0202174:	8cce                	mv	s9,s3
ffffffffc0202176:	46079963          	bnez	a5,ffffffffc02025e8 <slub_check+0x520>
ffffffffc020217a:	874e                	mv	a4,s3
ffffffffc020217c:	47ad                	li	a5,11
    for (size_t i = 0; i < size; i++) {
ffffffffc020217e:	02b00613          	li	a2,43
ffffffffc0202182:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0202186:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc020218a:	0ff6f793          	zext.b	a5,a3
ffffffffc020218e:	0705                	addi	a4,a4,1
ffffffffc0202190:	fec799e3          	bne	a5,a2,ffffffffc0202182 <slub_check+0xba>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0202194:	440d8a63          	beqz	s11,ffffffffc02025e8 <slub_check+0x520>
ffffffffc0202198:	00fdf793          	andi	a5,s11,15
ffffffffc020219c:	44079663          	bnez	a5,ffffffffc02025e8 <slub_check+0x520>
ffffffffc02021a0:	876e                	mv	a4,s11
ffffffffc02021a2:	47b1                	li	a5,12
    for (size_t i = 0; i < size; i++) {
ffffffffc02021a4:	02c00613          	li	a2,44
ffffffffc02021a8:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc02021ac:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02021b0:	0ff6f793          	zext.b	a5,a3
ffffffffc02021b4:	0705                	addi	a4,a4,1
ffffffffc02021b6:	fec799e3          	bne	a5,a2,ffffffffc02021a8 <slub_check+0xe0>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02021ba:	42040763          	beqz	s0,ffffffffc02025e8 <slub_check+0x520>
ffffffffc02021be:	00f47793          	andi	a5,s0,15
ffffffffc02021c2:	8ba2                	mv	s7,s0
ffffffffc02021c4:	42079263          	bnez	a5,ffffffffc02025e8 <slub_check+0x520>
ffffffffc02021c8:	10040d13          	addi	s10,s0,256
ffffffffc02021cc:	8722                	mv	a4,s0
ffffffffc02021ce:	47b5                	li	a5,13
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc02021d0:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02021d4:	27c5                	addiw	a5,a5,17
ffffffffc02021d6:	0705                	addi	a4,a4,1
ffffffffc02021d8:	0ff7f793          	zext.b	a5,a5
ffffffffc02021dc:	ffa71ae3          	bne	a4,s10,ffffffffc02021d0 <slub_check+0x108>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02021e0:	40090463          	beqz	s2,ffffffffc02025e8 <slub_check+0x520>
ffffffffc02021e4:	00f97793          	andi	a5,s2,15
ffffffffc02021e8:	8c4a                	mv	s8,s2
ffffffffc02021ea:	3e079f63          	bnez	a5,ffffffffc02025e8 <slub_check+0x520>
ffffffffc02021ee:	10090a93          	addi	s5,s2,256
ffffffffc02021f2:	874a                	mv	a4,s2
ffffffffc02021f4:	47b9                	li	a5,14
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc02021f6:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02021fa:	27c5                	addiw	a5,a5,17
ffffffffc02021fc:	0705                	addi	a4,a4,1
ffffffffc02021fe:	0ff7f793          	zext.b	a5,a5
ffffffffc0202202:	feea9ae3          	bne	s5,a4,ffffffffc02021f6 <slub_check+0x12e>
    assert(nr_free_pages() == before - 2);
ffffffffc0202206:	ef7fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc020220a:	ffea0b13          	addi	s6,s4,-2
ffffffffc020220e:	61651d63          	bne	a0,s6,ffffffffc0202828 <slub_check+0x760>
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0202212:	02098793          	addi	a5,s3,32
ffffffffc0202216:	00fdf663          	bgeu	s11,a5,ffffffffc0202222 <slub_check+0x15a>
ffffffffc020221a:	020d8793          	addi	a5,s11,32
ffffffffc020221e:	3af9e363          	bltu	s3,a5,ffffffffc02025c4 <slub_check+0x4fc>
ffffffffc0202222:	01a97463          	bgeu	s2,s10,ffffffffc020222a <slub_check+0x162>
ffffffffc0202226:	39546f63          	bltu	s0,s5,ffffffffc02025c4 <slub_check+0x4fc>
ffffffffc020222a:	020d8793          	addi	a5,s11,32
ffffffffc020222e:	38f46963          	bltu	s0,a5,ffffffffc02025c0 <slub_check+0x4f8>
    slub_free(small1); /* Recover a nonfirst object's slab and cache. */
ffffffffc0202232:	856e                	mv	a0,s11
ffffffffc0202234:	b3cff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    assert(nr_free_pages() == before - 2);
ffffffffc0202238:	ec5fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc020223c:	3eab1663          	bne	s6,a0,ffffffffc0202628 <slub_check+0x560>
    assert(slub_ready);
ffffffffc0202240:	409c                	lw	a5,0(s1)
ffffffffc0202242:	3c078363          	beqz	a5,ffffffffc0202608 <slub_check+0x540>
    if (size == 0) {
ffffffffc0202246:	02000513          	li	a0,32
ffffffffc020224a:	8caff0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
ffffffffc020224e:	85aa                	mv	a1,a0
    assert(again == small1);
ffffffffc0202250:	44ad9c63          	bne	s11,a0,ffffffffc02026a8 <slub_check+0x5e0>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0202254:	00f57793          	andi	a5,a0,15
ffffffffc0202258:	872a                	mv	a4,a0
ffffffffc020225a:	38079763          	bnez	a5,ffffffffc02025e8 <slub_check+0x520>
ffffffffc020225e:	47bd                	li	a5,15
    for (size_t i = 0; i < size; i++) {
ffffffffc0202260:	02f00513          	li	a0,47
ffffffffc0202264:	0117861b          	addiw	a2,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0202268:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc020226c:	0ff67793          	zext.b	a5,a2
ffffffffc0202270:	0705                	addi	a4,a4,1
ffffffffc0202272:	fea799e3          	bne	a5,a0,ffffffffc0202264 <slub_check+0x19c>
ffffffffc0202276:	47ad                	li	a5,11
    for (size_t i = 0; i < size; i++) {
ffffffffc0202278:	02b00613          	li	a2,43
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc020227c:	000cc703          	lbu	a4,0(s9)
ffffffffc0202280:	34f71463          	bne	a4,a5,ffffffffc02025c8 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc0202284:	27c5                	addiw	a5,a5,17
ffffffffc0202286:	0ff7f793          	zext.b	a5,a5
ffffffffc020228a:	0c85                	addi	s9,s9,1
ffffffffc020228c:	fec798e3          	bne	a5,a2,ffffffffc020227c <slub_check+0x1b4>
ffffffffc0202290:	8722                	mv	a4,s0
ffffffffc0202292:	47b5                	li	a5,13
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0202294:	00074603          	lbu	a2,0(a4)
ffffffffc0202298:	32f61863          	bne	a2,a5,ffffffffc02025c8 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc020229c:	27c5                	addiw	a5,a5,17
ffffffffc020229e:	0705                	addi	a4,a4,1
ffffffffc02022a0:	0ff7f793          	zext.b	a5,a5
ffffffffc02022a4:	ffa718e3          	bne	a4,s10,ffffffffc0202294 <slub_check+0x1cc>
ffffffffc02022a8:	874a                	mv	a4,s2
ffffffffc02022aa:	47b9                	li	a5,14
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02022ac:	00074603          	lbu	a2,0(a4)
ffffffffc02022b0:	30f61c63          	bne	a2,a5,ffffffffc02025c8 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc02022b4:	27c5                	addiw	a5,a5,17
ffffffffc02022b6:	0705                	addi	a4,a4,1
ffffffffc02022b8:	0ff7f793          	zext.b	a5,a5
ffffffffc02022bc:	feea98e3          	bne	s5,a4,ffffffffc02022ac <slub_check+0x1e4>
    slub_free(small0);
ffffffffc02022c0:	854e                	mv	a0,s3
ffffffffc02022c2:	e02e                	sd	a1,0(sp)
ffffffffc02022c4:	aacff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    assert(nr_free_pages() == before - 2);
ffffffffc02022c8:	e35fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc02022cc:	6582                	ld	a1,0(sp)
ffffffffc02022ce:	56ab1d63          	bne	s6,a0,ffffffffc0202848 <slub_check+0x780>
    slub_free(again);
ffffffffc02022d2:	852e                	mv	a0,a1
ffffffffc02022d4:	a9cff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    assert(nr_free_pages() == before - 1);
ffffffffc02022d8:	e25fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc02022dc:	fffa0993          	addi	s3,s4,-1
ffffffffc02022e0:	47b5                	li	a5,13
ffffffffc02022e2:	4b351363          	bne	a0,s3,ffffffffc0202788 <slub_check+0x6c0>
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02022e6:	000bc703          	lbu	a4,0(s7) # fffffffffffff000 <end+0x3fdf7df4>
ffffffffc02022ea:	2cf71f63          	bne	a4,a5,ffffffffc02025c8 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc02022ee:	27c5                	addiw	a5,a5,17
ffffffffc02022f0:	0b85                	addi	s7,s7,1
ffffffffc02022f2:	0ff7f793          	zext.b	a5,a5
ffffffffc02022f6:	ffab98e3          	bne	s7,s10,ffffffffc02022e6 <slub_check+0x21e>
ffffffffc02022fa:	47b9                	li	a5,14
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02022fc:	000c4703          	lbu	a4,0(s8)
ffffffffc0202300:	2cf71463          	bne	a4,a5,ffffffffc02025c8 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc0202304:	27c5                	addiw	a5,a5,17
ffffffffc0202306:	0c05                	addi	s8,s8,1
ffffffffc0202308:	0ff7f793          	zext.b	a5,a5
ffffffffc020230c:	ff8a98e3          	bne	s5,s8,ffffffffc02022fc <slub_check+0x234>
    slub_free(medium0);
ffffffffc0202310:	8522                	mv	a0,s0
ffffffffc0202312:	a5eff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    assert(nr_free_pages() == before - 1);
ffffffffc0202316:	de7fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc020231a:	36a99763          	bne	s3,a0,ffffffffc0202688 <slub_check+0x5c0>
    slub_free(medium1);
ffffffffc020231e:	854a                	mv	a0,s2
ffffffffc0202320:	a50ff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    assert(nr_free_pages() == before);
ffffffffc0202324:	dd9fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0202328:	34aa1063          	bne	s4,a0,ffffffffc0202668 <slub_check+0x5a0>
    slub_test_cache_isolation();
    cprintf("slub test: large contiguous allocations and PMM restoration\n");
ffffffffc020232c:	00001517          	auipc	a0,0x1
ffffffffc0202330:	6b450513          	addi	a0,a0,1716 # ffffffffc02039e0 <best_fit_pmm_manager+0x638>
ffffffffc0202334:	e2dfd0ef          	jal	ra,ffffffffc0200160 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0202338:	dc5fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
    assert(slub_ready);
ffffffffc020233c:	409c                	lw	a5,0(s1)
    size_t before = nr_free_pages();
ffffffffc020233e:	8a2a                	mv	s4,a0
    assert(slub_ready);
ffffffffc0202340:	2c078463          	beqz	a5,ffffffffc0202608 <slub_check+0x540>
    if (size == 0) {
ffffffffc0202344:	4541                	li	a0,16
ffffffffc0202346:	fcffe0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
ffffffffc020234a:	842a                	mv	s0,a0
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc020234c:	28050e63          	beqz	a0,ffffffffc02025e8 <slub_check+0x520>
ffffffffc0202350:	00f57793          	andi	a5,a0,15
ffffffffc0202354:	28079a63          	bnez	a5,ffffffffc02025e8 <slub_check+0x520>
ffffffffc0202358:	872a                	mv	a4,a0
ffffffffc020235a:	47d5                	li	a5,21
    for (size_t i = 0; i < size; i++) {
ffffffffc020235c:	02500613          	li	a2,37
ffffffffc0202360:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0202364:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0202368:	0ff6f793          	zext.b	a5,a3
ffffffffc020236c:	0705                	addi	a4,a4,1
ffffffffc020236e:	fec799e3          	bne	a5,a2,ffffffffc0202360 <slub_check+0x298>
    size_t with_small = nr_free_pages();
ffffffffc0202372:	d8bfe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
    assert(with_small == before - 1);
ffffffffc0202376:	fffa0793          	addi	a5,s4,-1
ffffffffc020237a:	2cf51763          	bne	a0,a5,ffffffffc0202648 <slub_check+0x580>
    const size_t sizes[] = { limit + 1, 2 * PGSIZE + 17 };
ffffffffc020237e:	6785                	lui	a5,0x1
ffffffffc0202380:	fc178793          	addi	a5,a5,-63 # fc1 <kern_entry-0xffffffffc01ff03f>
ffffffffc0202384:	e83e                	sd	a5,16(sp)
ffffffffc0202386:	6789                	lui	a5,0x2
ffffffffc0202388:	07c5                	addi	a5,a5,17
ffffffffc020238a:	ec3e                	sd	a5,24(sp)
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc020238c:	01010993          	addi	s3,sp,16
    const size_t sizes[] = { limit + 1, 2 * PGSIZE + 17 };
ffffffffc0202390:	497d                	li	s2,31
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0202392:	01040b13          	addi	s6,s0,16
    for (size_t i = 0; i < size; i++) {
ffffffffc0202396:	02500d13          	li	s10,37
ffffffffc020239a:	02000b93          	li	s7,32
        size_t free_before_large = nr_free_pages();
ffffffffc020239e:	d5ffe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
    assert(slub_ready);
ffffffffc02023a2:	409c                	lw	a5,0(s1)
        void *large = slub_alloc(sizes[i]);
ffffffffc02023a4:	0009bd83          	ld	s11,0(s3)
        size_t free_before_large = nr_free_pages();
ffffffffc02023a8:	8c2a                	mv	s8,a0
    assert(slub_ready);
ffffffffc02023aa:	24078f63          	beqz	a5,ffffffffc0202608 <slub_check+0x540>
    if (size == 0) {
ffffffffc02023ae:	220d8d63          	beqz	s11,ffffffffc02025e8 <slub_check+0x520>
ffffffffc02023b2:	856e                	mv	a0,s11
ffffffffc02023b4:	f61fe0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
ffffffffc02023b8:	8aaa                	mv	s5,a0
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02023ba:	22050763          	beqz	a0,ffffffffc02025e8 <slub_check+0x520>
ffffffffc02023be:	00f57793          	andi	a5,a0,15
ffffffffc02023c2:	8caa                	mv	s9,a0
ffffffffc02023c4:	22079263          	bnez	a5,ffffffffc02025e8 <slub_check+0x520>
ffffffffc02023c8:	9daa                	add	s11,s11,a0
ffffffffc02023ca:	872a                	mv	a4,a0
ffffffffc02023cc:	87ca                	mv	a5,s2
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc02023ce:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02023d2:	27c5                	addiw	a5,a5,17
ffffffffc02023d4:	0705                	addi	a4,a4,1
ffffffffc02023d6:	0ff7f793          	zext.b	a5,a5
ffffffffc02023da:	feed9ae3          	bne	s11,a4,ffffffffc02023ce <slub_check+0x306>
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc02023de:	016af463          	bgeu	s5,s6,ffffffffc02023e6 <slub_check+0x31e>
ffffffffc02023e2:	1fb46163          	bltu	s0,s11,ffffffffc02025c4 <slub_check+0x4fc>
        assert(nr_free_pages() < free_before_large);
ffffffffc02023e6:	d17fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc02023ea:	35857f63          	bgeu	a0,s8,ffffffffc0202748 <slub_check+0x680>
ffffffffc02023ee:	87ca                	mv	a5,s2
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02023f0:	000cc703          	lbu	a4,0(s9)
ffffffffc02023f4:	1cf71a63          	bne	a4,a5,ffffffffc02025c8 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc02023f8:	27c5                	addiw	a5,a5,17
ffffffffc02023fa:	0c85                	addi	s9,s9,1
ffffffffc02023fc:	0ff7f793          	zext.b	a5,a5
ffffffffc0202400:	ff9d98e3          	bne	s11,s9,ffffffffc02023f0 <slub_check+0x328>
ffffffffc0202404:	8722                	mv	a4,s0
ffffffffc0202406:	47d5                	li	a5,21
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0202408:	00074683          	lbu	a3,0(a4)
ffffffffc020240c:	1af69e63          	bne	a3,a5,ffffffffc02025c8 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc0202410:	27c5                	addiw	a5,a5,17
ffffffffc0202412:	0ff7f793          	zext.b	a5,a5
ffffffffc0202416:	0705                	addi	a4,a4,1
ffffffffc0202418:	ffa798e3          	bne	a5,s10,ffffffffc0202408 <slub_check+0x340>
        slub_free(large);
ffffffffc020241c:	8556                	mv	a0,s5
ffffffffc020241e:	952ff0ef          	jal	ra,ffffffffc0201570 <slub_free>
        assert(nr_free_pages() == free_before_large);
ffffffffc0202422:	cdbfe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0202426:	2aac1163          	bne	s8,a0,ffffffffc02026c8 <slub_check+0x600>
ffffffffc020242a:	8722                	mv	a4,s0
ffffffffc020242c:	47d5                	li	a5,21
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc020242e:	00074683          	lbu	a3,0(a4)
ffffffffc0202432:	18f69b63          	bne	a3,a5,ffffffffc02025c8 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc0202436:	27c5                	addiw	a5,a5,17
ffffffffc0202438:	0ff7f793          	zext.b	a5,a5
ffffffffc020243c:	0705                	addi	a4,a4,1
ffffffffc020243e:	ffa798e3          	bne	a5,s10,ffffffffc020242e <slub_check+0x366>
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc0202442:	09a1                	addi	s3,s3,8
ffffffffc0202444:	17791b63          	bne	s2,s7,ffffffffc02025ba <slub_check+0x4f2>
    slub_free(small);
ffffffffc0202448:	8522                	mv	a0,s0
ffffffffc020244a:	926ff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    assert(nr_free_pages() == before);
ffffffffc020244e:	caffe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0202452:	2aaa1b63          	bne	s4,a0,ffffffffc0202708 <slub_check+0x640>
    slub_test_large();
    cprintf("slub test: coexistence with direct PMM allocation\n");
ffffffffc0202456:	00001517          	auipc	a0,0x1
ffffffffc020245a:	63a50513          	addi	a0,a0,1594 # ffffffffc0203a90 <best_fit_pmm_manager+0x6e8>
ffffffffc020245e:	d03fd0ef          	jal	ra,ffffffffc0200160 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0202462:	c9bfe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
    assert(slub_ready);
ffffffffc0202466:	409c                	lw	a5,0(s1)
    size_t before = nr_free_pages();
ffffffffc0202468:	84aa                	mv	s1,a0
    assert(slub_ready);
ffffffffc020246a:	18078f63          	beqz	a5,ffffffffc0202608 <slub_check+0x540>
    if (size == 0) {
ffffffffc020246e:	04000513          	li	a0,64
ffffffffc0202472:	ea3fe0ef          	jal	ra,ffffffffc0201314 <slub_alloc.part.0>
ffffffffc0202476:	8b2a                	mv	s6,a0
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0202478:	16050863          	beqz	a0,ffffffffc02025e8 <slub_check+0x520>
ffffffffc020247c:	00f57793          	andi	a5,a0,15
ffffffffc0202480:	89aa                	mv	s3,a0
ffffffffc0202482:	16079363          	bnez	a5,ffffffffc02025e8 <slub_check+0x520>
ffffffffc0202486:	872a                	mv	a4,a0
ffffffffc0202488:	04900793          	li	a5,73
    for (size_t i = 0; i < size; i++) {
ffffffffc020248c:	08900613          	li	a2,137
ffffffffc0202490:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0202494:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0202498:	0ff6f793          	zext.b	a5,a3
ffffffffc020249c:	0705                	addi	a4,a4,1
ffffffffc020249e:	fec799e3          	bne	a5,a2,ffffffffc0202490 <slub_check+0x3c8>
    assert(nr_free_pages() == before - 1);
ffffffffc02024a2:	c5bfe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc02024a6:	fff48913          	addi	s2,s1,-1
ffffffffc02024aa:	23251f63          	bne	a0,s2,ffffffffc02026e8 <slub_check+0x620>
    struct Page *page = alloc_pages(1);
ffffffffc02024ae:	4505                	li	a0,1
ffffffffc02024b0:	c35fe0ef          	jal	ra,ffffffffc02010e4 <alloc_pages>
ffffffffc02024b4:	8baa                	mv	s7,a0
    assert(page != NULL);
ffffffffc02024b6:	2a050963          	beqz	a0,ffffffffc0202768 <slub_check+0x6a0>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02024ba:	00005417          	auipc	s0,0x5
ffffffffc02024be:	d2643403          	ld	s0,-730(s0) # ffffffffc02071e0 <pages>
ffffffffc02024c2:	40850433          	sub	s0,a0,s0
ffffffffc02024c6:	00002797          	auipc	a5,0x2
ffffffffc02024ca:	a3a7b783          	ld	a5,-1478(a5) # ffffffffc0203f00 <error_string+0x38>
ffffffffc02024ce:	840d                	srai	s0,s0,0x3
ffffffffc02024d0:	02f40433          	mul	s0,s0,a5
ffffffffc02024d4:	00002717          	auipc	a4,0x2
ffffffffc02024d8:	a3473703          	ld	a4,-1484(a4) # ffffffffc0203f08 <nbase>
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc02024dc:	77fd                	lui	a5,0xfffff
ffffffffc02024de:	00fb77b3          	and	a5,s6,a5
ffffffffc02024e2:	943a                	add	s0,s0,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc02024e4:	0432                	slli	s0,s0,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc02024e6:	00005717          	auipc	a4,0x5
ffffffffc02024ea:	d1a73703          	ld	a4,-742(a4) # ffffffffc0207200 <va_pa_offset>
ffffffffc02024ee:	943a                	add	s0,s0,a4
    assert(slub_test_page(object) != (uintptr_t)page_data);
ffffffffc02024f0:	2cf40c63          	beq	s0,a5,ffffffffc02027c8 <slub_check+0x700>
    assert(nr_free_pages() == before - 2);
ffffffffc02024f4:	c09fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc02024f8:	ffe48793          	addi	a5,s1,-2
ffffffffc02024fc:	2af51663          	bne	a0,a5,ffffffffc02027a8 <slub_check+0x6e0>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0202500:	0e040463          	beqz	s0,ffffffffc02025e8 <slub_check+0x520>
ffffffffc0202504:	00f47793          	andi	a5,s0,15
ffffffffc0202508:	0e079063          	bnez	a5,ffffffffc02025e8 <slub_check+0x520>
ffffffffc020250c:	6a05                	lui	s4,0x1
ffffffffc020250e:	9a22                	add	s4,s4,s0
ffffffffc0202510:	8722                	mv	a4,s0
ffffffffc0202512:	04a00793          	li	a5,74
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0202516:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc020251a:	27c5                	addiw	a5,a5,17
ffffffffc020251c:	0705                	addi	a4,a4,1
ffffffffc020251e:	0ff7f793          	zext.b	a5,a5
ffffffffc0202522:	ff471ae3          	bne	a4,s4,ffffffffc0202516 <slub_check+0x44e>
ffffffffc0202526:	04900793          	li	a5,73
    for (size_t i = 0; i < size; i++) {
ffffffffc020252a:	08900693          	li	a3,137
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc020252e:	0009c703          	lbu	a4,0(s3)
ffffffffc0202532:	08f71b63          	bne	a4,a5,ffffffffc02025c8 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc0202536:	27c5                	addiw	a5,a5,17
ffffffffc0202538:	0ff7f793          	zext.b	a5,a5
ffffffffc020253c:	0985                	addi	s3,s3,1
ffffffffc020253e:	fed798e3          	bne	a5,a3,ffffffffc020252e <slub_check+0x466>
    slub_free(object);
ffffffffc0202542:	855a                	mv	a0,s6
ffffffffc0202544:	82cff0ef          	jal	ra,ffffffffc0201570 <slub_free>
    assert(nr_free_pages() == before - 1);
ffffffffc0202548:	bb5fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc020254c:	04a00793          	li	a5,74
ffffffffc0202550:	2aa91c63          	bne	s2,a0,ffffffffc0202808 <slub_check+0x740>
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0202554:	00044703          	lbu	a4,0(s0)
ffffffffc0202558:	06f71863          	bne	a4,a5,ffffffffc02025c8 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc020255c:	27c5                	addiw	a5,a5,17
ffffffffc020255e:	0405                	addi	s0,s0,1
ffffffffc0202560:	0ff7f793          	zext.b	a5,a5
ffffffffc0202564:	ff4418e3          	bne	s0,s4,ffffffffc0202554 <slub_check+0x48c>
    free_pages(page, 1);
ffffffffc0202568:	4585                	li	a1,1
ffffffffc020256a:	855e                	mv	a0,s7
ffffffffc020256c:	b85fe0ef          	jal	ra,ffffffffc02010f0 <free_pages>
    assert(nr_free_pages() == before);
ffffffffc0202570:	b8dfe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc0202574:	26a49a63          	bne	s1,a0,ffffffffc02027e8 <slub_check+0x720>
    slub_test_pmm_interaction();
    cprintf("slub test: mixed allocations and out-of-order release\n");
ffffffffc0202578:	00001517          	auipc	a0,0x1
ffffffffc020257c:	59050513          	addi	a0,a0,1424 # ffffffffc0203b08 <best_fit_pmm_manager+0x760>
ffffffffc0202580:	be1fd0ef          	jal	ra,ffffffffc0200160 <cprintf>
    slub_test_mixed();
ffffffffc0202584:	8bfff0ef          	jal	ra,ffffffffc0201e42 <slub_test_mixed>
    assert(nr_free_pages() == free_before);
ffffffffc0202588:	b75fe0ef          	jal	ra,ffffffffc02010fc <nr_free_pages>
ffffffffc020258c:	67a2                	ld	a5,8(sp)
ffffffffc020258e:	18f51d63          	bne	a0,a5,ffffffffc0202728 <slub_check+0x660>
    cprintf("slub extended tests succeeded!\n");
}
ffffffffc0202592:	640a                	ld	s0,128(sp)
ffffffffc0202594:	60aa                	ld	ra,136(sp)
ffffffffc0202596:	74e6                	ld	s1,120(sp)
ffffffffc0202598:	7946                	ld	s2,112(sp)
ffffffffc020259a:	79a6                	ld	s3,104(sp)
ffffffffc020259c:	7a06                	ld	s4,96(sp)
ffffffffc020259e:	6ae6                	ld	s5,88(sp)
ffffffffc02025a0:	6b46                	ld	s6,80(sp)
ffffffffc02025a2:	6ba6                	ld	s7,72(sp)
ffffffffc02025a4:	6c06                	ld	s8,64(sp)
ffffffffc02025a6:	7ce2                	ld	s9,56(sp)
ffffffffc02025a8:	7d42                	ld	s10,48(sp)
ffffffffc02025aa:	7da2                	ld	s11,40(sp)
    cprintf("slub extended tests succeeded!\n");
ffffffffc02025ac:	00001517          	auipc	a0,0x1
ffffffffc02025b0:	5b450513          	addi	a0,a0,1460 # ffffffffc0203b60 <best_fit_pmm_manager+0x7b8>
}
ffffffffc02025b4:	6149                	addi	sp,sp,144
    cprintf("slub extended tests succeeded!\n");
ffffffffc02025b6:	babfd06f          	j	ffffffffc0200160 <cprintf>
ffffffffc02025ba:	02000913          	li	s2,32
ffffffffc02025be:	b3c5                	j	ffffffffc020239e <slub_check+0x2d6>
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc02025c0:	c7adf9e3          	bgeu	s11,s10,ffffffffc0202232 <slub_check+0x16a>
ffffffffc02025c4:	d2dfe0ef          	jal	ra,ffffffffc02012f0 <slub_test_disjoint.part.0>
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02025c8:	00001697          	auipc	a3,0x1
ffffffffc02025cc:	18868693          	addi	a3,a3,392 # ffffffffc0203750 <best_fit_pmm_manager+0x3a8>
ffffffffc02025d0:	00001617          	auipc	a2,0x1
ffffffffc02025d4:	9f860613          	addi	a2,a2,-1544 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02025d8:	0c700593          	li	a1,199
ffffffffc02025dc:	00001517          	auipc	a0,0x1
ffffffffc02025e0:	fb450513          	addi	a0,a0,-76 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02025e4:	bf3fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02025e8:	00001697          	auipc	a3,0x1
ffffffffc02025ec:	13868693          	addi	a3,a3,312 # ffffffffc0203720 <best_fit_pmm_manager+0x378>
ffffffffc02025f0:	00001617          	auipc	a2,0x1
ffffffffc02025f4:	9d860613          	addi	a2,a2,-1576 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02025f8:	0be00593          	li	a1,190
ffffffffc02025fc:	00001517          	auipc	a0,0x1
ffffffffc0202600:	f9450513          	addi	a0,a0,-108 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202604:	bd3fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0202608:	00001697          	auipc	a3,0x1
ffffffffc020260c:	02868693          	addi	a3,a3,40 # ffffffffc0203630 <best_fit_pmm_manager+0x288>
ffffffffc0202610:	00001617          	auipc	a2,0x1
ffffffffc0202614:	9b860613          	addi	a2,a2,-1608 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202618:	06e00593          	li	a1,110
ffffffffc020261c:	00001517          	auipc	a0,0x1
ffffffffc0202620:	f7450513          	addi	a0,a0,-140 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202624:	bb3fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc0202628:	00001697          	auipc	a3,0x1
ffffffffc020262c:	27868693          	addi	a3,a3,632 # ffffffffc02038a0 <best_fit_pmm_manager+0x4f8>
ffffffffc0202630:	00001617          	auipc	a2,0x1
ffffffffc0202634:	99860613          	addi	a2,a2,-1640 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202638:	14d00593          	li	a1,333
ffffffffc020263c:	00001517          	auipc	a0,0x1
ffffffffc0202640:	f5450513          	addi	a0,a0,-172 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202644:	b93fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(with_small == before - 1);
ffffffffc0202648:	00001697          	auipc	a3,0x1
ffffffffc020264c:	3d868693          	addi	a3,a3,984 # ffffffffc0203a20 <best_fit_pmm_manager+0x678>
ffffffffc0202650:	00001617          	auipc	a2,0x1
ffffffffc0202654:	97860613          	addi	a2,a2,-1672 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202658:	16700593          	li	a1,359
ffffffffc020265c:	00001517          	auipc	a0,0x1
ffffffffc0202660:	f3450513          	addi	a0,a0,-204 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202664:	b73fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0202668:	00001697          	auipc	a3,0x1
ffffffffc020266c:	12868693          	addi	a3,a3,296 # ffffffffc0203790 <best_fit_pmm_manager+0x3e8>
ffffffffc0202670:	00001617          	auipc	a2,0x1
ffffffffc0202674:	95860613          	addi	a2,a2,-1704 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202678:	15d00593          	li	a1,349
ffffffffc020267c:	00001517          	auipc	a0,0x1
ffffffffc0202680:	f1450513          	addi	a0,a0,-236 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202684:	b53fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0202688:	00001697          	auipc	a3,0x1
ffffffffc020268c:	16068693          	addi	a3,a3,352 # ffffffffc02037e8 <best_fit_pmm_manager+0x440>
ffffffffc0202690:	00001617          	auipc	a2,0x1
ffffffffc0202694:	93860613          	addi	a2,a2,-1736 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202698:	15b00593          	li	a1,347
ffffffffc020269c:	00001517          	auipc	a0,0x1
ffffffffc02026a0:	ef450513          	addi	a0,a0,-268 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02026a4:	b33fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(again == small1);
ffffffffc02026a8:	00001697          	auipc	a3,0x1
ffffffffc02026ac:	32868693          	addi	a3,a3,808 # ffffffffc02039d0 <best_fit_pmm_manager+0x628>
ffffffffc02026b0:	00001617          	auipc	a2,0x1
ffffffffc02026b4:	91860613          	addi	a2,a2,-1768 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02026b8:	14f00593          	li	a1,335
ffffffffc02026bc:	00001517          	auipc	a0,0x1
ffffffffc02026c0:	ed450513          	addi	a0,a0,-300 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02026c4:	b13fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nr_free_pages() == free_before_large);
ffffffffc02026c8:	00001697          	auipc	a3,0x1
ffffffffc02026cc:	3a068693          	addi	a3,a3,928 # ffffffffc0203a68 <best_fit_pmm_manager+0x6c0>
ffffffffc02026d0:	00001617          	auipc	a2,0x1
ffffffffc02026d4:	8f860613          	addi	a2,a2,-1800 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02026d8:	17300593          	li	a1,371
ffffffffc02026dc:	00001517          	auipc	a0,0x1
ffffffffc02026e0:	eb450513          	addi	a0,a0,-332 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02026e4:	af3fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc02026e8:	00001697          	auipc	a3,0x1
ffffffffc02026ec:	10068693          	addi	a3,a3,256 # ffffffffc02037e8 <best_fit_pmm_manager+0x440>
ffffffffc02026f0:	00001617          	auipc	a2,0x1
ffffffffc02026f4:	8d860613          	addi	a2,a2,-1832 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02026f8:	17f00593          	li	a1,383
ffffffffc02026fc:	00001517          	auipc	a0,0x1
ffffffffc0202700:	e9450513          	addi	a0,a0,-364 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202704:	ad3fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0202708:	00001697          	auipc	a3,0x1
ffffffffc020270c:	08868693          	addi	a3,a3,136 # ffffffffc0203790 <best_fit_pmm_manager+0x3e8>
ffffffffc0202710:	00001617          	auipc	a2,0x1
ffffffffc0202714:	8b860613          	addi	a2,a2,-1864 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202718:	17700593          	li	a1,375
ffffffffc020271c:	00001517          	auipc	a0,0x1
ffffffffc0202720:	e7450513          	addi	a0,a0,-396 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202724:	ab3fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == free_before);
ffffffffc0202728:	00001697          	auipc	a3,0x1
ffffffffc020272c:	41868693          	addi	a3,a3,1048 # ffffffffc0203b40 <best_fit_pmm_manager+0x798>
ffffffffc0202730:	00001617          	auipc	a2,0x1
ffffffffc0202734:	89860613          	addi	a2,a2,-1896 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202738:	1c300593          	li	a1,451
ffffffffc020273c:	00001517          	auipc	a0,0x1
ffffffffc0202740:	e5450513          	addi	a0,a0,-428 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202744:	a93fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nr_free_pages() < free_before_large);
ffffffffc0202748:	00001697          	auipc	a3,0x1
ffffffffc020274c:	2f868693          	addi	a3,a3,760 # ffffffffc0203a40 <best_fit_pmm_manager+0x698>
ffffffffc0202750:	00001617          	auipc	a2,0x1
ffffffffc0202754:	87860613          	addi	a2,a2,-1928 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202758:	16f00593          	li	a1,367
ffffffffc020275c:	00001517          	auipc	a0,0x1
ffffffffc0202760:	e3450513          	addi	a0,a0,-460 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202764:	a73fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(page != NULL);
ffffffffc0202768:	00001697          	auipc	a3,0x1
ffffffffc020276c:	36068693          	addi	a3,a3,864 # ffffffffc0203ac8 <best_fit_pmm_manager+0x720>
ffffffffc0202770:	00001617          	auipc	a2,0x1
ffffffffc0202774:	85860613          	addi	a2,a2,-1960 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202778:	18200593          	li	a1,386
ffffffffc020277c:	00001517          	auipc	a0,0x1
ffffffffc0202780:	e1450513          	addi	a0,a0,-492 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202784:	a53fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0202788:	00001697          	auipc	a3,0x1
ffffffffc020278c:	06068693          	addi	a3,a3,96 # ffffffffc02037e8 <best_fit_pmm_manager+0x440>
ffffffffc0202790:	00001617          	auipc	a2,0x1
ffffffffc0202794:	83860613          	addi	a2,a2,-1992 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202798:	15700593          	li	a1,343
ffffffffc020279c:	00001517          	auipc	a0,0x1
ffffffffc02027a0:	df450513          	addi	a0,a0,-524 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02027a4:	a33fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc02027a8:	00001697          	auipc	a3,0x1
ffffffffc02027ac:	0f868693          	addi	a3,a3,248 # ffffffffc02038a0 <best_fit_pmm_manager+0x4f8>
ffffffffc02027b0:	00001617          	auipc	a2,0x1
ffffffffc02027b4:	81860613          	addi	a2,a2,-2024 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02027b8:	18500593          	li	a1,389
ffffffffc02027bc:	00001517          	auipc	a0,0x1
ffffffffc02027c0:	dd450513          	addi	a0,a0,-556 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02027c4:	a13fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_test_page(object) != (uintptr_t)page_data);
ffffffffc02027c8:	00001697          	auipc	a3,0x1
ffffffffc02027cc:	31068693          	addi	a3,a3,784 # ffffffffc0203ad8 <best_fit_pmm_manager+0x730>
ffffffffc02027d0:	00000617          	auipc	a2,0x0
ffffffffc02027d4:	7f860613          	addi	a2,a2,2040 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02027d8:	18400593          	li	a1,388
ffffffffc02027dc:	00001517          	auipc	a0,0x1
ffffffffc02027e0:	db450513          	addi	a0,a0,-588 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc02027e4:	9f3fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc02027e8:	00001697          	auipc	a3,0x1
ffffffffc02027ec:	fa868693          	addi	a3,a3,-88 # ffffffffc0203790 <best_fit_pmm_manager+0x3e8>
ffffffffc02027f0:	00000617          	auipc	a2,0x0
ffffffffc02027f4:	7d860613          	addi	a2,a2,2008 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc02027f8:	18d00593          	li	a1,397
ffffffffc02027fc:	00001517          	auipc	a0,0x1
ffffffffc0202800:	d9450513          	addi	a0,a0,-620 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202804:	9d3fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0202808:	00001697          	auipc	a3,0x1
ffffffffc020280c:	fe068693          	addi	a3,a3,-32 # ffffffffc02037e8 <best_fit_pmm_manager+0x440>
ffffffffc0202810:	00000617          	auipc	a2,0x0
ffffffffc0202814:	7b860613          	addi	a2,a2,1976 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202818:	18a00593          	li	a1,394
ffffffffc020281c:	00001517          	auipc	a0,0x1
ffffffffc0202820:	d7450513          	addi	a0,a0,-652 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202824:	9b3fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc0202828:	00001697          	auipc	a3,0x1
ffffffffc020282c:	07868693          	addi	a3,a3,120 # ffffffffc02038a0 <best_fit_pmm_manager+0x4f8>
ffffffffc0202830:	00000617          	auipc	a2,0x0
ffffffffc0202834:	79860613          	addi	a2,a2,1944 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202838:	14700593          	li	a1,327
ffffffffc020283c:	00001517          	auipc	a0,0x1
ffffffffc0202840:	d5450513          	addi	a0,a0,-684 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202844:	993fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc0202848:	00001697          	auipc	a3,0x1
ffffffffc020284c:	05868693          	addi	a3,a3,88 # ffffffffc02038a0 <best_fit_pmm_manager+0x4f8>
ffffffffc0202850:	00000617          	auipc	a2,0x0
ffffffffc0202854:	77860613          	addi	a2,a2,1912 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202858:	15500593          	li	a1,341
ffffffffc020285c:	00001517          	auipc	a0,0x1
ffffffffc0202860:	d3450513          	addi	a0,a0,-716 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202864:	973fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0202868:	00001697          	auipc	a3,0x1
ffffffffc020286c:	dc868693          	addi	a3,a3,-568 # ffffffffc0203630 <best_fit_pmm_manager+0x288>
ffffffffc0202870:	00000617          	auipc	a2,0x0
ffffffffc0202874:	75860613          	addi	a2,a2,1880 # ffffffffc0202fc8 <etext+0x2ac>
ffffffffc0202878:	1b500593          	li	a1,437
ffffffffc020287c:	00001517          	auipc	a0,0x1
ffffffffc0202880:	d1450513          	addi	a0,a0,-748 # ffffffffc0203590 <best_fit_pmm_manager+0x1e8>
ffffffffc0202884:	953fd0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0202888 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0202888:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020288c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020288e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202892:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0202894:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202898:	f022                	sd	s0,32(sp)
ffffffffc020289a:	ec26                	sd	s1,24(sp)
ffffffffc020289c:	e84a                	sd	s2,16(sp)
ffffffffc020289e:	f406                	sd	ra,40(sp)
ffffffffc02028a0:	e44e                	sd	s3,8(sp)
ffffffffc02028a2:	84aa                	mv	s1,a0
ffffffffc02028a4:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02028a6:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02028aa:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02028ac:	03067e63          	bgeu	a2,a6,ffffffffc02028e8 <printnum+0x60>
ffffffffc02028b0:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02028b2:	00805763          	blez	s0,ffffffffc02028c0 <printnum+0x38>
ffffffffc02028b6:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02028b8:	85ca                	mv	a1,s2
ffffffffc02028ba:	854e                	mv	a0,s3
ffffffffc02028bc:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02028be:	fc65                	bnez	s0,ffffffffc02028b6 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02028c0:	1a02                	slli	s4,s4,0x20
ffffffffc02028c2:	00001797          	auipc	a5,0x1
ffffffffc02028c6:	3f678793          	addi	a5,a5,1014 # ffffffffc0203cb8 <slub_sizes+0x50>
ffffffffc02028ca:	020a5a13          	srli	s4,s4,0x20
ffffffffc02028ce:	9a3e                	add	s4,s4,a5
}
ffffffffc02028d0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02028d2:	000a4503          	lbu	a0,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
}
ffffffffc02028d6:	70a2                	ld	ra,40(sp)
ffffffffc02028d8:	69a2                	ld	s3,8(sp)
ffffffffc02028da:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02028dc:	85ca                	mv	a1,s2
ffffffffc02028de:	87a6                	mv	a5,s1
}
ffffffffc02028e0:	6942                	ld	s2,16(sp)
ffffffffc02028e2:	64e2                	ld	s1,24(sp)
ffffffffc02028e4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02028e6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02028e8:	03065633          	divu	a2,a2,a6
ffffffffc02028ec:	8722                	mv	a4,s0
ffffffffc02028ee:	f9bff0ef          	jal	ra,ffffffffc0202888 <printnum>
ffffffffc02028f2:	b7f9                	j	ffffffffc02028c0 <printnum+0x38>

ffffffffc02028f4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02028f4:	7119                	addi	sp,sp,-128
ffffffffc02028f6:	f4a6                	sd	s1,104(sp)
ffffffffc02028f8:	f0ca                	sd	s2,96(sp)
ffffffffc02028fa:	ecce                	sd	s3,88(sp)
ffffffffc02028fc:	e8d2                	sd	s4,80(sp)
ffffffffc02028fe:	e4d6                	sd	s5,72(sp)
ffffffffc0202900:	e0da                	sd	s6,64(sp)
ffffffffc0202902:	fc5e                	sd	s7,56(sp)
ffffffffc0202904:	f06a                	sd	s10,32(sp)
ffffffffc0202906:	fc86                	sd	ra,120(sp)
ffffffffc0202908:	f8a2                	sd	s0,112(sp)
ffffffffc020290a:	f862                	sd	s8,48(sp)
ffffffffc020290c:	f466                	sd	s9,40(sp)
ffffffffc020290e:	ec6e                	sd	s11,24(sp)
ffffffffc0202910:	892a                	mv	s2,a0
ffffffffc0202912:	84ae                	mv	s1,a1
ffffffffc0202914:	8d32                	mv	s10,a2
ffffffffc0202916:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202918:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020291c:	5b7d                	li	s6,-1
ffffffffc020291e:	00001a97          	auipc	s5,0x1
ffffffffc0202922:	3cea8a93          	addi	s5,s5,974 # ffffffffc0203cec <slub_sizes+0x84>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202926:	00001b97          	auipc	s7,0x1
ffffffffc020292a:	5a2b8b93          	addi	s7,s7,1442 # ffffffffc0203ec8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020292e:	000d4503          	lbu	a0,0(s10)
ffffffffc0202932:	001d0413          	addi	s0,s10,1
ffffffffc0202936:	01350a63          	beq	a0,s3,ffffffffc020294a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020293a:	c121                	beqz	a0,ffffffffc020297a <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020293c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020293e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0202940:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202942:	fff44503          	lbu	a0,-1(s0)
ffffffffc0202946:	ff351ae3          	bne	a0,s3,ffffffffc020293a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020294a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020294e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0202952:	4c81                	li	s9,0
ffffffffc0202954:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0202956:	5c7d                	li	s8,-1
ffffffffc0202958:	5dfd                	li	s11,-1
ffffffffc020295a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020295e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202960:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0202964:	0ff5f593          	zext.b	a1,a1
ffffffffc0202968:	00140d13          	addi	s10,s0,1
ffffffffc020296c:	04b56263          	bltu	a0,a1,ffffffffc02029b0 <vprintfmt+0xbc>
ffffffffc0202970:	058a                	slli	a1,a1,0x2
ffffffffc0202972:	95d6                	add	a1,a1,s5
ffffffffc0202974:	4194                	lw	a3,0(a1)
ffffffffc0202976:	96d6                	add	a3,a3,s5
ffffffffc0202978:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020297a:	70e6                	ld	ra,120(sp)
ffffffffc020297c:	7446                	ld	s0,112(sp)
ffffffffc020297e:	74a6                	ld	s1,104(sp)
ffffffffc0202980:	7906                	ld	s2,96(sp)
ffffffffc0202982:	69e6                	ld	s3,88(sp)
ffffffffc0202984:	6a46                	ld	s4,80(sp)
ffffffffc0202986:	6aa6                	ld	s5,72(sp)
ffffffffc0202988:	6b06                	ld	s6,64(sp)
ffffffffc020298a:	7be2                	ld	s7,56(sp)
ffffffffc020298c:	7c42                	ld	s8,48(sp)
ffffffffc020298e:	7ca2                	ld	s9,40(sp)
ffffffffc0202990:	7d02                	ld	s10,32(sp)
ffffffffc0202992:	6de2                	ld	s11,24(sp)
ffffffffc0202994:	6109                	addi	sp,sp,128
ffffffffc0202996:	8082                	ret
            padc = '0';
ffffffffc0202998:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020299a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020299e:	846a                	mv	s0,s10
ffffffffc02029a0:	00140d13          	addi	s10,s0,1
ffffffffc02029a4:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02029a8:	0ff5f593          	zext.b	a1,a1
ffffffffc02029ac:	fcb572e3          	bgeu	a0,a1,ffffffffc0202970 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02029b0:	85a6                	mv	a1,s1
ffffffffc02029b2:	02500513          	li	a0,37
ffffffffc02029b6:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02029b8:	fff44783          	lbu	a5,-1(s0)
ffffffffc02029bc:	8d22                	mv	s10,s0
ffffffffc02029be:	f73788e3          	beq	a5,s3,ffffffffc020292e <vprintfmt+0x3a>
ffffffffc02029c2:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02029c6:	1d7d                	addi	s10,s10,-1
ffffffffc02029c8:	ff379de3          	bne	a5,s3,ffffffffc02029c2 <vprintfmt+0xce>
ffffffffc02029cc:	b78d                	j	ffffffffc020292e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02029ce:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02029d2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02029d6:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02029d8:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02029dc:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02029e0:	02d86463          	bltu	a6,a3,ffffffffc0202a08 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02029e4:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02029e8:	002c169b          	slliw	a3,s8,0x2
ffffffffc02029ec:	0186873b          	addw	a4,a3,s8
ffffffffc02029f0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02029f4:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02029f6:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02029fa:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02029fc:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0202a00:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0202a04:	fed870e3          	bgeu	a6,a3,ffffffffc02029e4 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0202a08:	f40ddce3          	bgez	s11,ffffffffc0202960 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0202a0c:	8de2                	mv	s11,s8
ffffffffc0202a0e:	5c7d                	li	s8,-1
ffffffffc0202a10:	bf81                	j	ffffffffc0202960 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0202a12:	fffdc693          	not	a3,s11
ffffffffc0202a16:	96fd                	srai	a3,a3,0x3f
ffffffffc0202a18:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202a1c:	00144603          	lbu	a2,1(s0)
ffffffffc0202a20:	2d81                	sext.w	s11,s11
ffffffffc0202a22:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202a24:	bf35                	j	ffffffffc0202960 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0202a26:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202a2a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0202a2e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202a30:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0202a32:	bfd9                	j	ffffffffc0202a08 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0202a34:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202a36:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202a3a:	01174463          	blt	a4,a7,ffffffffc0202a42 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0202a3e:	1a088e63          	beqz	a7,ffffffffc0202bfa <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0202a42:	000a3603          	ld	a2,0(s4)
ffffffffc0202a46:	46c1                	li	a3,16
ffffffffc0202a48:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0202a4a:	2781                	sext.w	a5,a5
ffffffffc0202a4c:	876e                	mv	a4,s11
ffffffffc0202a4e:	85a6                	mv	a1,s1
ffffffffc0202a50:	854a                	mv	a0,s2
ffffffffc0202a52:	e37ff0ef          	jal	ra,ffffffffc0202888 <printnum>
            break;
ffffffffc0202a56:	bde1                	j	ffffffffc020292e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0202a58:	000a2503          	lw	a0,0(s4)
ffffffffc0202a5c:	85a6                	mv	a1,s1
ffffffffc0202a5e:	0a21                	addi	s4,s4,8
ffffffffc0202a60:	9902                	jalr	s2
            break;
ffffffffc0202a62:	b5f1                	j	ffffffffc020292e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0202a64:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202a66:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202a6a:	01174463          	blt	a4,a7,ffffffffc0202a72 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0202a6e:	18088163          	beqz	a7,ffffffffc0202bf0 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0202a72:	000a3603          	ld	a2,0(s4)
ffffffffc0202a76:	46a9                	li	a3,10
ffffffffc0202a78:	8a2e                	mv	s4,a1
ffffffffc0202a7a:	bfc1                	j	ffffffffc0202a4a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202a7c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0202a80:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202a82:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202a84:	bdf1                	j	ffffffffc0202960 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0202a86:	85a6                	mv	a1,s1
ffffffffc0202a88:	02500513          	li	a0,37
ffffffffc0202a8c:	9902                	jalr	s2
            break;
ffffffffc0202a8e:	b545                	j	ffffffffc020292e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202a90:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0202a94:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202a96:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202a98:	b5e1                	j	ffffffffc0202960 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0202a9a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202a9c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202aa0:	01174463          	blt	a4,a7,ffffffffc0202aa8 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0202aa4:	14088163          	beqz	a7,ffffffffc0202be6 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0202aa8:	000a3603          	ld	a2,0(s4)
ffffffffc0202aac:	46a1                	li	a3,8
ffffffffc0202aae:	8a2e                	mv	s4,a1
ffffffffc0202ab0:	bf69                	j	ffffffffc0202a4a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0202ab2:	03000513          	li	a0,48
ffffffffc0202ab6:	85a6                	mv	a1,s1
ffffffffc0202ab8:	e03e                	sd	a5,0(sp)
ffffffffc0202aba:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0202abc:	85a6                	mv	a1,s1
ffffffffc0202abe:	07800513          	li	a0,120
ffffffffc0202ac2:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202ac4:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0202ac6:	6782                	ld	a5,0(sp)
ffffffffc0202ac8:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202aca:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0202ace:	bfb5                	j	ffffffffc0202a4a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202ad0:	000a3403          	ld	s0,0(s4)
ffffffffc0202ad4:	008a0713          	addi	a4,s4,8
ffffffffc0202ad8:	e03a                	sd	a4,0(sp)
ffffffffc0202ada:	14040263          	beqz	s0,ffffffffc0202c1e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0202ade:	0fb05763          	blez	s11,ffffffffc0202bcc <vprintfmt+0x2d8>
ffffffffc0202ae2:	02d00693          	li	a3,45
ffffffffc0202ae6:	0cd79163          	bne	a5,a3,ffffffffc0202ba8 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202aea:	00044783          	lbu	a5,0(s0)
ffffffffc0202aee:	0007851b          	sext.w	a0,a5
ffffffffc0202af2:	cf85                	beqz	a5,ffffffffc0202b2a <vprintfmt+0x236>
ffffffffc0202af4:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202af8:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202afc:	000c4563          	bltz	s8,ffffffffc0202b06 <vprintfmt+0x212>
ffffffffc0202b00:	3c7d                	addiw	s8,s8,-1
ffffffffc0202b02:	036c0263          	beq	s8,s6,ffffffffc0202b26 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0202b06:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202b08:	0e0c8e63          	beqz	s9,ffffffffc0202c04 <vprintfmt+0x310>
ffffffffc0202b0c:	3781                	addiw	a5,a5,-32
ffffffffc0202b0e:	0ef47b63          	bgeu	s0,a5,ffffffffc0202c04 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0202b12:	03f00513          	li	a0,63
ffffffffc0202b16:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202b18:	000a4783          	lbu	a5,0(s4)
ffffffffc0202b1c:	3dfd                	addiw	s11,s11,-1
ffffffffc0202b1e:	0a05                	addi	s4,s4,1
ffffffffc0202b20:	0007851b          	sext.w	a0,a5
ffffffffc0202b24:	ffe1                	bnez	a5,ffffffffc0202afc <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0202b26:	01b05963          	blez	s11,ffffffffc0202b38 <vprintfmt+0x244>
ffffffffc0202b2a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0202b2c:	85a6                	mv	a1,s1
ffffffffc0202b2e:	02000513          	li	a0,32
ffffffffc0202b32:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0202b34:	fe0d9be3          	bnez	s11,ffffffffc0202b2a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202b38:	6a02                	ld	s4,0(sp)
ffffffffc0202b3a:	bbd5                	j	ffffffffc020292e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0202b3c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202b3e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0202b42:	01174463          	blt	a4,a7,ffffffffc0202b4a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0202b46:	08088d63          	beqz	a7,ffffffffc0202be0 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0202b4a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0202b4e:	0a044d63          	bltz	s0,ffffffffc0202c08 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0202b52:	8622                	mv	a2,s0
ffffffffc0202b54:	8a66                	mv	s4,s9
ffffffffc0202b56:	46a9                	li	a3,10
ffffffffc0202b58:	bdcd                	j	ffffffffc0202a4a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0202b5a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202b5e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0202b60:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0202b62:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0202b66:	8fb5                	xor	a5,a5,a3
ffffffffc0202b68:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202b6c:	02d74163          	blt	a4,a3,ffffffffc0202b8e <vprintfmt+0x29a>
ffffffffc0202b70:	00369793          	slli	a5,a3,0x3
ffffffffc0202b74:	97de                	add	a5,a5,s7
ffffffffc0202b76:	639c                	ld	a5,0(a5)
ffffffffc0202b78:	cb99                	beqz	a5,ffffffffc0202b8e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0202b7a:	86be                	mv	a3,a5
ffffffffc0202b7c:	00001617          	auipc	a2,0x1
ffffffffc0202b80:	16c60613          	addi	a2,a2,364 # ffffffffc0203ce8 <slub_sizes+0x80>
ffffffffc0202b84:	85a6                	mv	a1,s1
ffffffffc0202b86:	854a                	mv	a0,s2
ffffffffc0202b88:	0ce000ef          	jal	ra,ffffffffc0202c56 <printfmt>
ffffffffc0202b8c:	b34d                	j	ffffffffc020292e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0202b8e:	00001617          	auipc	a2,0x1
ffffffffc0202b92:	14a60613          	addi	a2,a2,330 # ffffffffc0203cd8 <slub_sizes+0x70>
ffffffffc0202b96:	85a6                	mv	a1,s1
ffffffffc0202b98:	854a                	mv	a0,s2
ffffffffc0202b9a:	0bc000ef          	jal	ra,ffffffffc0202c56 <printfmt>
ffffffffc0202b9e:	bb41                	j	ffffffffc020292e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0202ba0:	00001417          	auipc	s0,0x1
ffffffffc0202ba4:	13040413          	addi	s0,s0,304 # ffffffffc0203cd0 <slub_sizes+0x68>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202ba8:	85e2                	mv	a1,s8
ffffffffc0202baa:	8522                	mv	a0,s0
ffffffffc0202bac:	e43e                	sd	a5,8(sp)
ffffffffc0202bae:	0fc000ef          	jal	ra,ffffffffc0202caa <strnlen>
ffffffffc0202bb2:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0202bb6:	01b05b63          	blez	s11,ffffffffc0202bcc <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0202bba:	67a2                	ld	a5,8(sp)
ffffffffc0202bbc:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202bc0:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0202bc2:	85a6                	mv	a1,s1
ffffffffc0202bc4:	8552                	mv	a0,s4
ffffffffc0202bc6:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202bc8:	fe0d9ce3          	bnez	s11,ffffffffc0202bc0 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202bcc:	00044783          	lbu	a5,0(s0)
ffffffffc0202bd0:	00140a13          	addi	s4,s0,1
ffffffffc0202bd4:	0007851b          	sext.w	a0,a5
ffffffffc0202bd8:	d3a5                	beqz	a5,ffffffffc0202b38 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202bda:	05e00413          	li	s0,94
ffffffffc0202bde:	bf39                	j	ffffffffc0202afc <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0202be0:	000a2403          	lw	s0,0(s4)
ffffffffc0202be4:	b7ad                	j	ffffffffc0202b4e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0202be6:	000a6603          	lwu	a2,0(s4)
ffffffffc0202bea:	46a1                	li	a3,8
ffffffffc0202bec:	8a2e                	mv	s4,a1
ffffffffc0202bee:	bdb1                	j	ffffffffc0202a4a <vprintfmt+0x156>
ffffffffc0202bf0:	000a6603          	lwu	a2,0(s4)
ffffffffc0202bf4:	46a9                	li	a3,10
ffffffffc0202bf6:	8a2e                	mv	s4,a1
ffffffffc0202bf8:	bd89                	j	ffffffffc0202a4a <vprintfmt+0x156>
ffffffffc0202bfa:	000a6603          	lwu	a2,0(s4)
ffffffffc0202bfe:	46c1                	li	a3,16
ffffffffc0202c00:	8a2e                	mv	s4,a1
ffffffffc0202c02:	b5a1                	j	ffffffffc0202a4a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0202c04:	9902                	jalr	s2
ffffffffc0202c06:	bf09                	j	ffffffffc0202b18 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0202c08:	85a6                	mv	a1,s1
ffffffffc0202c0a:	02d00513          	li	a0,45
ffffffffc0202c0e:	e03e                	sd	a5,0(sp)
ffffffffc0202c10:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0202c12:	6782                	ld	a5,0(sp)
ffffffffc0202c14:	8a66                	mv	s4,s9
ffffffffc0202c16:	40800633          	neg	a2,s0
ffffffffc0202c1a:	46a9                	li	a3,10
ffffffffc0202c1c:	b53d                	j	ffffffffc0202a4a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0202c1e:	03b05163          	blez	s11,ffffffffc0202c40 <vprintfmt+0x34c>
ffffffffc0202c22:	02d00693          	li	a3,45
ffffffffc0202c26:	f6d79de3          	bne	a5,a3,ffffffffc0202ba0 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0202c2a:	00001417          	auipc	s0,0x1
ffffffffc0202c2e:	0a640413          	addi	s0,s0,166 # ffffffffc0203cd0 <slub_sizes+0x68>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202c32:	02800793          	li	a5,40
ffffffffc0202c36:	02800513          	li	a0,40
ffffffffc0202c3a:	00140a13          	addi	s4,s0,1
ffffffffc0202c3e:	bd6d                	j	ffffffffc0202af8 <vprintfmt+0x204>
ffffffffc0202c40:	00001a17          	auipc	s4,0x1
ffffffffc0202c44:	091a0a13          	addi	s4,s4,145 # ffffffffc0203cd1 <slub_sizes+0x69>
ffffffffc0202c48:	02800513          	li	a0,40
ffffffffc0202c4c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202c50:	05e00413          	li	s0,94
ffffffffc0202c54:	b565                	j	ffffffffc0202afc <vprintfmt+0x208>

ffffffffc0202c56 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202c56:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0202c58:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202c5c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0202c5e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202c60:	ec06                	sd	ra,24(sp)
ffffffffc0202c62:	f83a                	sd	a4,48(sp)
ffffffffc0202c64:	fc3e                	sd	a5,56(sp)
ffffffffc0202c66:	e0c2                	sd	a6,64(sp)
ffffffffc0202c68:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0202c6a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0202c6c:	c89ff0ef          	jal	ra,ffffffffc02028f4 <vprintfmt>
}
ffffffffc0202c70:	60e2                	ld	ra,24(sp)
ffffffffc0202c72:	6161                	addi	sp,sp,80
ffffffffc0202c74:	8082                	ret

ffffffffc0202c76 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0202c76:	4781                	li	a5,0
ffffffffc0202c78:	00004717          	auipc	a4,0x4
ffffffffc0202c7c:	39873703          	ld	a4,920(a4) # ffffffffc0207010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0202c80:	88ba                	mv	a7,a4
ffffffffc0202c82:	852a                	mv	a0,a0
ffffffffc0202c84:	85be                	mv	a1,a5
ffffffffc0202c86:	863e                	mv	a2,a5
ffffffffc0202c88:	00000073          	ecall
ffffffffc0202c8c:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0202c8e:	8082                	ret

ffffffffc0202c90 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0202c90:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0202c94:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0202c96:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0202c98:	cb81                	beqz	a5,ffffffffc0202ca8 <strlen+0x18>
        cnt ++;
ffffffffc0202c9a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0202c9c:	00a707b3          	add	a5,a4,a0
ffffffffc0202ca0:	0007c783          	lbu	a5,0(a5)
ffffffffc0202ca4:	fbfd                	bnez	a5,ffffffffc0202c9a <strlen+0xa>
ffffffffc0202ca6:	8082                	ret
    }
    return cnt;
}
ffffffffc0202ca8:	8082                	ret

ffffffffc0202caa <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0202caa:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202cac:	e589                	bnez	a1,ffffffffc0202cb6 <strnlen+0xc>
ffffffffc0202cae:	a811                	j	ffffffffc0202cc2 <strnlen+0x18>
        cnt ++;
ffffffffc0202cb0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202cb2:	00f58863          	beq	a1,a5,ffffffffc0202cc2 <strnlen+0x18>
ffffffffc0202cb6:	00f50733          	add	a4,a0,a5
ffffffffc0202cba:	00074703          	lbu	a4,0(a4)
ffffffffc0202cbe:	fb6d                	bnez	a4,ffffffffc0202cb0 <strnlen+0x6>
ffffffffc0202cc0:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0202cc2:	852e                	mv	a0,a1
ffffffffc0202cc4:	8082                	ret

ffffffffc0202cc6 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202cc6:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202cca:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202cce:	cb89                	beqz	a5,ffffffffc0202ce0 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0202cd0:	0505                	addi	a0,a0,1
ffffffffc0202cd2:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202cd4:	fee789e3          	beq	a5,a4,ffffffffc0202cc6 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202cd8:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0202cdc:	9d19                	subw	a0,a0,a4
ffffffffc0202cde:	8082                	ret
ffffffffc0202ce0:	4501                	li	a0,0
ffffffffc0202ce2:	bfed                	j	ffffffffc0202cdc <strcmp+0x16>

ffffffffc0202ce4 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202ce4:	c20d                	beqz	a2,ffffffffc0202d06 <strncmp+0x22>
ffffffffc0202ce6:	962e                	add	a2,a2,a1
ffffffffc0202ce8:	a031                	j	ffffffffc0202cf4 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0202cea:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202cec:	00e79a63          	bne	a5,a4,ffffffffc0202d00 <strncmp+0x1c>
ffffffffc0202cf0:	00b60b63          	beq	a2,a1,ffffffffc0202d06 <strncmp+0x22>
ffffffffc0202cf4:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0202cf8:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202cfa:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0202cfe:	f7f5                	bnez	a5,ffffffffc0202cea <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202d00:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0202d04:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202d06:	4501                	li	a0,0
ffffffffc0202d08:	8082                	ret

ffffffffc0202d0a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0202d0a:	ca01                	beqz	a2,ffffffffc0202d1a <memset+0x10>
ffffffffc0202d0c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0202d0e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0202d10:	0785                	addi	a5,a5,1
ffffffffc0202d12:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0202d16:	fec79de3          	bne	a5,a2,ffffffffc0202d10 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0202d1a:	8082                	ret
