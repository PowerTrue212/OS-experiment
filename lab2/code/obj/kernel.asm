
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00008297          	auipc	t0,0x8
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0208000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00008297          	auipc	t0,0x8
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0208008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02072b7          	lui	t0,0xc0207
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
ffffffffc020003c:	c0207137          	lui	sp,0xc0207

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
ffffffffc0200050:	0cc50513          	addi	a0,a0,204 # ffffffffc0203118 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	10a000ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00003517          	auipc	a0,0x3
ffffffffc0200066:	0d650513          	addi	a0,a0,214 # ffffffffc0203138 <etext+0x24>
ffffffffc020006a:	0f6000ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00003597          	auipc	a1,0x3
ffffffffc0200072:	0a658593          	addi	a1,a1,166 # ffffffffc0203114 <etext>
ffffffffc0200076:	00003517          	auipc	a0,0x3
ffffffffc020007a:	0e250513          	addi	a0,a0,226 # ffffffffc0203158 <etext+0x44>
ffffffffc020007e:	0e2000ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00008597          	auipc	a1,0x8
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0208018 <slub_caches>
ffffffffc020008a:	00003517          	auipc	a0,0x3
ffffffffc020008e:	0ee50513          	addi	a0,a0,238 # ffffffffc0203178 <etext+0x64>
ffffffffc0200092:	0ce000ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00018597          	auipc	a1,0x18
ffffffffc020009a:	16a58593          	addi	a1,a1,362 # ffffffffc0218200 <end>
ffffffffc020009e:	00003517          	auipc	a0,0x3
ffffffffc02000a2:	0fa50513          	addi	a0,a0,250 # ffffffffc0203198 <etext+0x84>
ffffffffc02000a6:	0ba000ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00018597          	auipc	a1,0x18
ffffffffc02000ae:	55558593          	addi	a1,a1,1365 # ffffffffc02185ff <end+0x3ff>
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
ffffffffc02000d0:	0ec50513          	addi	a0,a0,236 # ffffffffc02031b8 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a069                	j	ffffffffc0200160 <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00008517          	auipc	a0,0x8
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0208018 <slub_caches>
ffffffffc02000e0:	00018617          	auipc	a2,0x18
ffffffffc02000e4:	12060613          	addi	a2,a2,288 # ffffffffc0218200 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	012030ef          	jal	ra,ffffffffc0203102 <memset>
    dtb_init();
ffffffffc02000f4:	140000ef          	jal	ra,ffffffffc0200234 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	132000ef          	jal	ra,ffffffffc020022a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00003517          	auipc	a0,0x3
ffffffffc0200100:	10c50513          	addi	a0,a0,268 # ffffffffc0203208 <etext+0xf4>
ffffffffc0200104:	092000ef          	jal	ra,ffffffffc0200196 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	4fc000ef          	jal	ra,ffffffffc0200608 <pmm_init>
    slub_init();
ffffffffc0200110:	0df000ef          	jal	ra,ffffffffc02009ee <slub_init>
    slub_check();
ffffffffc0200114:	4b2010ef          	jal	ra,ffffffffc02015c6 <slub_check>
    cprintf("slub_check() succeeded!\n");
ffffffffc0200118:	00003517          	auipc	a0,0x3
ffffffffc020011c:	0d050513          	addi	a0,a0,208 # ffffffffc02031e8 <etext+0xd4>
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
ffffffffc0200154:	399020ef          	jal	ra,ffffffffc0202cec <vprintfmt>
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
ffffffffc0200162:	02810313          	addi	t1,sp,40 # ffffffffc0207028 <boot_page_table_sv39+0x28>
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
ffffffffc020018a:	363020ef          	jal	ra,ffffffffc0202cec <vprintfmt>
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
ffffffffc02001d6:	00018317          	auipc	t1,0x18
ffffffffc02001da:	fd230313          	addi	t1,t1,-46 # ffffffffc02181a8 <is_panic>
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
ffffffffc020020a:	02250513          	addi	a0,a0,34 # ffffffffc0203228 <etext+0x114>
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
ffffffffc0200220:	fc450513          	addi	a0,a0,-60 # ffffffffc02031e0 <etext+0xcc>
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
ffffffffc0200230:	63f0206f          	j	ffffffffc020306e <sbi_console_putchar>

ffffffffc0200234 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200234:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200236:	00003517          	auipc	a0,0x3
ffffffffc020023a:	01250513          	addi	a0,a0,18 # ffffffffc0203248 <etext+0x134>
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
ffffffffc020025c:	00008597          	auipc	a1,0x8
ffffffffc0200260:	da45b583          	ld	a1,-604(a1) # ffffffffc0208000 <boot_hartid>
ffffffffc0200264:	00003517          	auipc	a0,0x3
ffffffffc0200268:	ff450513          	addi	a0,a0,-12 # ffffffffc0203258 <etext+0x144>
ffffffffc020026c:	ef5ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200270:	00008417          	auipc	s0,0x8
ffffffffc0200274:	d9840413          	addi	s0,s0,-616 # ffffffffc0208008 <boot_dtb>
ffffffffc0200278:	600c                	ld	a1,0(s0)
ffffffffc020027a:	00003517          	auipc	a0,0x3
ffffffffc020027e:	fee50513          	addi	a0,a0,-18 # ffffffffc0203268 <etext+0x154>
ffffffffc0200282:	edfff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200286:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020028a:	00003517          	auipc	a0,0x3
ffffffffc020028e:	ff650513          	addi	a0,a0,-10 # ffffffffc0203280 <etext+0x16c>
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
ffffffffc02002d2:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfec7ced>
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
ffffffffc0200348:	f8c90913          	addi	s2,s2,-116 # ffffffffc02032d0 <etext+0x1bc>
ffffffffc020034c:	49bd                	li	s3,15
        switch (token) {
ffffffffc020034e:	4d91                	li	s11,4
ffffffffc0200350:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200352:	00003497          	auipc	s1,0x3
ffffffffc0200356:	f7648493          	addi	s1,s1,-138 # ffffffffc02032c8 <etext+0x1b4>
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
ffffffffc02003aa:	fa250513          	addi	a0,a0,-94 # ffffffffc0203348 <etext+0x234>
ffffffffc02003ae:	db3ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02003b2:	00003517          	auipc	a0,0x3
ffffffffc02003b6:	fce50513          	addi	a0,a0,-50 # ffffffffc0203380 <etext+0x26c>
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
ffffffffc02003f6:	eae50513          	addi	a0,a0,-338 # ffffffffc02032a0 <etext+0x18c>
}
ffffffffc02003fa:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003fc:	b395                	j	ffffffffc0200160 <cprintf>
                int name_len = strlen(name);
ffffffffc02003fe:	8556                	mv	a0,s5
ffffffffc0200400:	489020ef          	jal	ra,ffffffffc0203088 <strlen>
ffffffffc0200404:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200406:	4619                	li	a2,6
ffffffffc0200408:	85a6                	mv	a1,s1
ffffffffc020040a:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc020040c:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020040e:	4cf020ef          	jal	ra,ffffffffc02030dc <strncmp>
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
ffffffffc02004a4:	41b020ef          	jal	ra,ffffffffc02030be <strcmp>
ffffffffc02004a8:	66a2                	ld	a3,8(sp)
ffffffffc02004aa:	f94d                	bnez	a0,ffffffffc020045c <dtb_init+0x228>
ffffffffc02004ac:	fb59f8e3          	bgeu	s3,s5,ffffffffc020045c <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02004b0:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004b4:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004b8:	00003517          	auipc	a0,0x3
ffffffffc02004bc:	e2050513          	addi	a0,a0,-480 # ffffffffc02032d8 <etext+0x1c4>
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
ffffffffc020058a:	d7250513          	addi	a0,a0,-654 # ffffffffc02032f8 <etext+0x1e4>
ffffffffc020058e:	bd3ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200592:	014b5613          	srli	a2,s6,0x14
ffffffffc0200596:	85da                	mv	a1,s6
ffffffffc0200598:	00003517          	auipc	a0,0x3
ffffffffc020059c:	d7850513          	addi	a0,a0,-648 # ffffffffc0203310 <etext+0x1fc>
ffffffffc02005a0:	bc1ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02005a4:	008b05b3          	add	a1,s6,s0
ffffffffc02005a8:	15fd                	addi	a1,a1,-1
ffffffffc02005aa:	00003517          	auipc	a0,0x3
ffffffffc02005ae:	d8650513          	addi	a0,a0,-634 # ffffffffc0203330 <etext+0x21c>
ffffffffc02005b2:	bafff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005b6:	00003517          	auipc	a0,0x3
ffffffffc02005ba:	dca50513          	addi	a0,a0,-566 # ffffffffc0203380 <etext+0x26c>
        memory_base = mem_base;
ffffffffc02005be:	00018797          	auipc	a5,0x18
ffffffffc02005c2:	be87b923          	sd	s0,-1038(a5) # ffffffffc02181b0 <memory_base>
        memory_size = mem_size;
ffffffffc02005c6:	00018797          	auipc	a5,0x18
ffffffffc02005ca:	bf67b923          	sd	s6,-1038(a5) # ffffffffc02181b8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ce:	b3f5                	j	ffffffffc02003ba <dtb_init+0x186>

ffffffffc02005d0 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005d0:	00018517          	auipc	a0,0x18
ffffffffc02005d4:	be053503          	ld	a0,-1056(a0) # ffffffffc02181b0 <memory_base>
ffffffffc02005d8:	8082                	ret

ffffffffc02005da <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005da:	00018517          	auipc	a0,0x18
ffffffffc02005de:	bde53503          	ld	a0,-1058(a0) # ffffffffc02181b8 <memory_size>
ffffffffc02005e2:	8082                	ret

ffffffffc02005e4 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc02005e4:	00018797          	auipc	a5,0x18
ffffffffc02005e8:	bec7b783          	ld	a5,-1044(a5) # ffffffffc02181d0 <pmm_manager>
ffffffffc02005ec:	6f9c                	ld	a5,24(a5)
ffffffffc02005ee:	8782                	jr	a5

ffffffffc02005f0 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02005f0:	00018797          	auipc	a5,0x18
ffffffffc02005f4:	be07b783          	ld	a5,-1056(a5) # ffffffffc02181d0 <pmm_manager>
ffffffffc02005f8:	739c                	ld	a5,32(a5)
ffffffffc02005fa:	8782                	jr	a5

ffffffffc02005fc <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02005fc:	00018797          	auipc	a5,0x18
ffffffffc0200600:	bd47b783          	ld	a5,-1068(a5) # ffffffffc02181d0 <pmm_manager>
ffffffffc0200604:	779c                	ld	a5,40(a5)
ffffffffc0200606:	8782                	jr	a5

ffffffffc0200608 <pmm_init>:
    pmm_manager = &tree_buddy_pmm_manager;
ffffffffc0200608:	00004797          	auipc	a5,0x4
ffffffffc020060c:	df878793          	addi	a5,a5,-520 # ffffffffc0204400 <tree_buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200610:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(free_start), (free_end - free_start) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200612:	7179                	addi	sp,sp,-48
ffffffffc0200614:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200616:	00003517          	auipc	a0,0x3
ffffffffc020061a:	d8250513          	addi	a0,a0,-638 # ffffffffc0203398 <etext+0x284>
    pmm_manager = &tree_buddy_pmm_manager;
ffffffffc020061e:	00018417          	auipc	s0,0x18
ffffffffc0200622:	bb240413          	addi	s0,s0,-1102 # ffffffffc02181d0 <pmm_manager>
void pmm_init(void) {
ffffffffc0200626:	f406                	sd	ra,40(sp)
ffffffffc0200628:	ec26                	sd	s1,24(sp)
ffffffffc020062a:	e84a                	sd	s2,16(sp)
ffffffffc020062c:	e44e                	sd	s3,8(sp)
    pmm_manager = &tree_buddy_pmm_manager;
ffffffffc020062e:	e01c                	sd	a5,0(s0)
void pmm_init(void) {
ffffffffc0200630:	e052                	sd	s4,0(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200632:	b2fff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    pmm_manager->init();
ffffffffc0200636:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200638:	00018497          	auipc	s1,0x18
ffffffffc020063c:	bb048493          	addi	s1,s1,-1104 # ffffffffc02181e8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200640:	679c                	ld	a5,8(a5)
ffffffffc0200642:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200644:	57f5                	li	a5,-3
ffffffffc0200646:	07fa                	slli	a5,a5,0x1e
ffffffffc0200648:	e09c                	sd	a5,0(s1)
    uint64_t mem_base = get_memory_base();
ffffffffc020064a:	f87ff0ef          	jal	ra,ffffffffc02005d0 <get_memory_base>
ffffffffc020064e:	89aa                	mv	s3,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0200650:	f8bff0ef          	jal	ra,ffffffffc02005da <get_memory_size>
    if (mem_base == 0 || mem_size == 0 || mem_base < DRAM_BASE) {
ffffffffc0200654:	800007b7          	lui	a5,0x80000
ffffffffc0200658:	fff7c793          	not	a5,a5
    uint64_t mem_size = get_memory_size();
ffffffffc020065c:	892a                	mv	s2,a0
    if (mem_base == 0 || mem_size == 0 || mem_base < DRAM_BASE) {
ffffffffc020065e:	1337f563          	bgeu	a5,s3,ffffffffc0200788 <pmm_init+0x180>
ffffffffc0200662:	12050363          	beqz	a0,ffffffffc0200788 <pmm_init+0x180>
    uint64_t mem_end = mem_base + mem_size;
ffffffffc0200666:	47c5                	li	a5,17
ffffffffc0200668:	00a98a33          	add	s4,s3,a0
    if (mem_end > PHYSICAL_MEMORY_END) {
ffffffffc020066c:	07ee                	slli	a5,a5,0x1b
ffffffffc020066e:	0f47e863          	bltu	a5,s4,ffffffffc020075e <pmm_init+0x156>
    cprintf("physical memory map:\n");
ffffffffc0200672:	00003517          	auipc	a0,0x3
ffffffffc0200676:	d9650513          	addi	a0,a0,-618 # ffffffffc0203408 <etext+0x2f4>
ffffffffc020067a:	ae7ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_base,
ffffffffc020067e:	fffa0693          	addi	a3,s4,-1
ffffffffc0200682:	864e                	mv	a2,s3
ffffffffc0200684:	85ca                	mv	a1,s2
ffffffffc0200686:	00003517          	auipc	a0,0x3
ffffffffc020068a:	d9a50513          	addi	a0,a0,-614 # ffffffffc0203420 <etext+0x30c>
ffffffffc020068e:	ad3ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    npage = ROUNDDOWN(mem_end, PGSIZE) / PGSIZE;
ffffffffc0200692:	777d                	lui	a4,0xfffff
ffffffffc0200694:	00019797          	auipc	a5,0x19
ffffffffc0200698:	b6b78793          	addi	a5,a5,-1173 # ffffffffc02191ff <end+0xfff>
ffffffffc020069c:	8ff9                	and	a5,a5,a4
ffffffffc020069e:	00ca5613          	srli	a2,s4,0xc
    size_t nr_desc = npage - nbase;
ffffffffc02006a2:	fff805b7          	lui	a1,0xfff80
    npage = ROUNDDOWN(mem_end, PGSIZE) / PGSIZE;
ffffffffc02006a6:	00018717          	auipc	a4,0x18
ffffffffc02006aa:	b0c73d23          	sd	a2,-1254(a4) # ffffffffc02181c0 <npage>
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02006ae:	00018717          	auipc	a4,0x18
ffffffffc02006b2:	b0f73d23          	sd	a5,-1254(a4) # ffffffffc02181c8 <pages>
    size_t nr_desc = npage - nbase;
ffffffffc02006b6:	00b606b3          	add	a3,a2,a1
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02006ba:	853e                	mv	a0,a5
    for (i = 0; i < nr_desc; i++) {
ffffffffc02006bc:	c685                	beqz	a3,ffffffffc02006e4 <pmm_init+0xdc>
ffffffffc02006be:	00261593          	slli	a1,a2,0x2
ffffffffc02006c2:	95b2                	add	a1,a1,a2
ffffffffc02006c4:	fec00737          	lui	a4,0xfec00
ffffffffc02006c8:	973e                	add	a4,a4,a5
ffffffffc02006ca:	058e                	slli	a1,a1,0x3
ffffffffc02006cc:	972e                	add	a4,a4,a1
        SetPageReserved(p);
ffffffffc02006ce:	4805                	li	a6,1
        p->property = 0;
ffffffffc02006d0:	0007a823          	sw	zero,16(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02006d4:	0007a023          	sw	zero,0(a5)
        SetPageReserved(p);
ffffffffc02006d8:	0107b423          	sd	a6,8(a5)
    for (i = 0; i < nr_desc; i++) {
ffffffffc02006dc:	02878793          	addi	a5,a5,40
ffffffffc02006e0:	fef718e3          	bne	a4,a5,ffffffffc02006d0 <pmm_init+0xc8>
    uintptr_t free_start = ROUNDUP(PADDR(pages + nr_desc), PGSIZE);
ffffffffc02006e4:	00269593          	slli	a1,a3,0x2
ffffffffc02006e8:	95b6                	add	a1,a1,a3
ffffffffc02006ea:	058e                	slli	a1,a1,0x3
ffffffffc02006ec:	00b506b3          	add	a3,a0,a1
ffffffffc02006f0:	c02007b7          	lui	a5,0xc0200
ffffffffc02006f4:	0af6e863          	bltu	a3,a5,ffffffffc02007a4 <pmm_init+0x19c>
ffffffffc02006f8:	609c                	ld	a5,0(s1)
ffffffffc02006fa:	6585                	lui	a1,0x1
ffffffffc02006fc:	15fd                	addi	a1,a1,-1
ffffffffc02006fe:	8d9d                	sub	a1,a1,a5
ffffffffc0200700:	95b6                	add	a1,a1,a3
ffffffffc0200702:	76fd                	lui	a3,0xfffff
ffffffffc0200704:	8df5                	and	a1,a1,a3
    uintptr_t free_end = npage * PGSIZE;
ffffffffc0200706:	00c61793          	slli	a5,a2,0xc
    if (free_start < free_end) {
ffffffffc020070a:	04f5ec63          	bltu	a1,a5,ffffffffc0200762 <pmm_init+0x15a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020070e:	601c                	ld	a5,0(s0)
ffffffffc0200710:	7b9c                	ld	a5,48(a5)
ffffffffc0200712:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200714:	00003517          	auipc	a0,0x3
ffffffffc0200718:	d9450513          	addi	a0,a0,-620 # ffffffffc02034a8 <etext+0x394>
ffffffffc020071c:	a45ff0ef          	jal	ra,ffffffffc0200160 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200720:	00007597          	auipc	a1,0x7
ffffffffc0200724:	8e058593          	addi	a1,a1,-1824 # ffffffffc0207000 <boot_page_table_sv39>
ffffffffc0200728:	00018797          	auipc	a5,0x18
ffffffffc020072c:	aab7bc23          	sd	a1,-1352(a5) # ffffffffc02181e0 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200730:	c02007b7          	lui	a5,0xc0200
ffffffffc0200734:	08f5e463          	bltu	a1,a5,ffffffffc02007bc <pmm_init+0x1b4>
ffffffffc0200738:	6090                	ld	a2,0(s1)
}
ffffffffc020073a:	7402                	ld	s0,32(sp)
ffffffffc020073c:	70a2                	ld	ra,40(sp)
ffffffffc020073e:	64e2                	ld	s1,24(sp)
ffffffffc0200740:	6942                	ld	s2,16(sp)
ffffffffc0200742:	69a2                	ld	s3,8(sp)
ffffffffc0200744:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200746:	40c58633          	sub	a2,a1,a2
ffffffffc020074a:	00018797          	auipc	a5,0x18
ffffffffc020074e:	a8c7b723          	sd	a2,-1394(a5) # ffffffffc02181d8 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200752:	00003517          	auipc	a0,0x3
ffffffffc0200756:	d7650513          	addi	a0,a0,-650 # ffffffffc02034c8 <etext+0x3b4>
}
ffffffffc020075a:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020075c:	b411                	j	ffffffffc0200160 <cprintf>
ffffffffc020075e:	8a3e                	mv	s4,a5
ffffffffc0200760:	bf09                	j	ffffffffc0200672 <pmm_init+0x6a>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200762:	00c5d713          	srli	a4,a1,0xc
ffffffffc0200766:	06c77863          	bgeu	a4,a2,ffffffffc02007d6 <pmm_init+0x1ce>
    pmm_manager->init_memmap(base, n);
ffffffffc020076a:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020076c:	fff806b7          	lui	a3,0xfff80
ffffffffc0200770:	96ba                	add	a3,a3,a4
ffffffffc0200772:	00269713          	slli	a4,a3,0x2
ffffffffc0200776:	9736                	add	a4,a4,a3
ffffffffc0200778:	6a14                	ld	a3,16(a2)
        init_memmap(pa2page(free_start), (free_end - free_start) / PGSIZE);
ffffffffc020077a:	40b785b3          	sub	a1,a5,a1
ffffffffc020077e:	070e                	slli	a4,a4,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200780:	81b1                	srli	a1,a1,0xc
ffffffffc0200782:	953a                	add	a0,a0,a4
ffffffffc0200784:	9682                	jalr	a3
}
ffffffffc0200786:	b761                	j	ffffffffc020070e <pmm_init+0x106>
        panic("page_init: invalid physical memory info (base=0x%lx, size=0x%lx)",
ffffffffc0200788:	874a                	mv	a4,s2
ffffffffc020078a:	86ce                	mv	a3,s3
ffffffffc020078c:	00003617          	auipc	a2,0x3
ffffffffc0200790:	c2460613          	addi	a2,a2,-988 # ffffffffc02033b0 <etext+0x29c>
ffffffffc0200794:	05700593          	li	a1,87
ffffffffc0200798:	00003517          	auipc	a0,0x3
ffffffffc020079c:	c6050513          	addi	a0,a0,-928 # ffffffffc02033f8 <etext+0x2e4>
ffffffffc02007a0:	a37ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    uintptr_t free_start = ROUNDUP(PADDR(pages + nr_desc), PGSIZE);
ffffffffc02007a4:	00003617          	auipc	a2,0x3
ffffffffc02007a8:	cac60613          	addi	a2,a2,-852 # ffffffffc0203450 <etext+0x33c>
ffffffffc02007ac:	07b00593          	li	a1,123
ffffffffc02007b0:	00003517          	auipc	a0,0x3
ffffffffc02007b4:	c4850513          	addi	a0,a0,-952 # ffffffffc02033f8 <etext+0x2e4>
ffffffffc02007b8:	a1fff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02007bc:	86ae                	mv	a3,a1
ffffffffc02007be:	00003617          	auipc	a2,0x3
ffffffffc02007c2:	c9260613          	addi	a2,a2,-878 # ffffffffc0203450 <etext+0x33c>
ffffffffc02007c6:	09600593          	li	a1,150
ffffffffc02007ca:	00003517          	auipc	a0,0x3
ffffffffc02007ce:	c2e50513          	addi	a0,a0,-978 # ffffffffc02033f8 <etext+0x2e4>
ffffffffc02007d2:	a05ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02007d6:	00003617          	auipc	a2,0x3
ffffffffc02007da:	ca260613          	addi	a2,a2,-862 # ffffffffc0203478 <etext+0x364>
ffffffffc02007de:	06a00593          	li	a1,106
ffffffffc02007e2:	00003517          	auipc	a0,0x3
ffffffffc02007e6:	cb650513          	addi	a0,a0,-842 # ffffffffc0203498 <etext+0x384>
ffffffffc02007ea:	9edff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02007ee <slub_test_disjoint.part.0>:
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
    }
}

static void
slub_test_disjoint(void *a, size_t a_size, void *b, size_t b_size) {
ffffffffc02007ee:	1141                	addi	sp,sp,-16
    uintptr_t a_start = (uintptr_t)a, b_start = (uintptr_t)b;
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc02007f0:	00003697          	auipc	a3,0x3
ffffffffc02007f4:	d1868693          	addi	a3,a3,-744 # ffffffffc0203508 <etext+0x3f4>
ffffffffc02007f8:	00003617          	auipc	a2,0x3
ffffffffc02007fc:	d5060613          	addi	a2,a2,-688 # ffffffffc0203548 <etext+0x434>
ffffffffc0200800:	0ce00593          	li	a1,206
ffffffffc0200804:	00003517          	auipc	a0,0x3
ffffffffc0200808:	d5c50513          	addi	a0,a0,-676 # ffffffffc0203560 <etext+0x44c>
slub_test_disjoint(void *a, size_t a_size, void *b, size_t b_size) {
ffffffffc020080c:	e406                	sd	ra,8(sp)
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc020080e:	9c9ff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0200812 <slub_alloc.part.0>:
slub_alloc(size_t size) {
ffffffffc0200812:	7139                	addi	sp,sp,-64
ffffffffc0200814:	f04a                	sd	s2,32(sp)
ffffffffc0200816:	00008917          	auipc	s2,0x8
ffffffffc020081a:	80290913          	addi	s2,s2,-2046 # ffffffffc0208018 <slub_caches>
ffffffffc020081e:	ec4e                	sd	s3,24(sp)
ffffffffc0200820:	fc06                	sd	ra,56(sp)
ffffffffc0200822:	f822                	sd	s0,48(sp)
ffffffffc0200824:	f426                	sd	s1,40(sp)
ffffffffc0200826:	e852                	sd	s4,16(sp)
ffffffffc0200828:	e456                	sd	s5,8(sp)
ffffffffc020082a:	87ca                	mv	a5,s2
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc020082c:	4981                	li	s3,0
ffffffffc020082e:	46a9                	li	a3,10
        if (size > cache->object_size) {
ffffffffc0200830:	6398                	ld	a4,0(a5)
ffffffffc0200832:	06a76963          	bltu	a4,a0,ffffffffc02008a4 <slub_alloc.part.0+0x92>
ffffffffc0200836:	00299a13          	slli	s4,s3,0x2
ffffffffc020083a:	013a04b3          	add	s1,s4,s3
ffffffffc020083e:	048e                	slli	s1,s1,0x3
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
ffffffffc0200840:	00990ab3          	add	s5,s2,s1
ffffffffc0200844:	010ab403          	ld	s0,16(s5)
        if (list_empty(&cache->partial)) {
ffffffffc0200848:	00848793          	addi	a5,s1,8
ffffffffc020084c:	97ca                	add	a5,a5,s2
ffffffffc020084e:	0cf40563          	beq	s0,a5,ffffffffc0200918 <slub_alloc.part.0+0x106>
        void *object = slab->freelist;
ffffffffc0200852:	7008                	ld	a0,32(s0)
        assert(object != NULL && slab->inuse < slab->capacity);
ffffffffc0200854:	14050d63          	beqz	a0,ffffffffc02009ae <slub_alloc.part.0+0x19c>
ffffffffc0200858:	741c                	ld	a5,40(s0)
ffffffffc020085a:	7818                	ld	a4,48(s0)
ffffffffc020085c:	14e7f963          	bgeu	a5,a4,ffffffffc02009ae <slub_alloc.part.0+0x19c>
        slab->freelist = *(void **)object;
ffffffffc0200860:	6114                	ld	a3,0(a0)
        slab->inuse++;
ffffffffc0200862:	0785                	addi	a5,a5,1
ffffffffc0200864:	f41c                	sd	a5,40(s0)
        slab->freelist = *(void **)object;
ffffffffc0200866:	f014                	sd	a3,32(s0)
        if (slab->inuse == slab->capacity) {
ffffffffc0200868:	02f71563          	bne	a4,a5,ffffffffc0200892 <slub_alloc.part.0+0x80>
    __list_del(listelm->prev, listelm->next);
ffffffffc020086c:	641c                	ld	a5,8(s0)
ffffffffc020086e:	6018                	ld	a4,0(s0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200870:	99d2                	add	s3,s3,s4
ffffffffc0200872:	098e                	slli	s3,s3,0x3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200874:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200876:	e398                	sd	a4,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0200878:	e400                	sd	s0,8(s0)
ffffffffc020087a:	e000                	sd	s0,0(s0)
    __list_add(elm, listelm, listelm->next);
ffffffffc020087c:	99ca                	add	s3,s3,s2
ffffffffc020087e:	0209b783          	ld	a5,32(s3)
            list_add(&cache->full, &slab->link);
ffffffffc0200882:	04e1                	addi	s1,s1,24
ffffffffc0200884:	9926                	add	s2,s2,s1
    prev->next = next->prev = elm;
ffffffffc0200886:	e380                	sd	s0,0(a5)
ffffffffc0200888:	0289b023          	sd	s0,32(s3)
    elm->next = next;
ffffffffc020088c:	e41c                	sd	a5,8(s0)
    elm->prev = prev;
ffffffffc020088e:	01243023          	sd	s2,0(s0)
}
ffffffffc0200892:	70e2                	ld	ra,56(sp)
ffffffffc0200894:	7442                	ld	s0,48(sp)
ffffffffc0200896:	74a2                	ld	s1,40(sp)
ffffffffc0200898:	7902                	ld	s2,32(sp)
ffffffffc020089a:	69e2                	ld	s3,24(sp)
ffffffffc020089c:	6a42                	ld	s4,16(sp)
ffffffffc020089e:	6aa2                	ld	s5,8(sp)
ffffffffc02008a0:	6121                	addi	sp,sp,64
ffffffffc02008a2:	8082                	ret
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc02008a4:	0985                	addi	s3,s3,1
ffffffffc02008a6:	02878793          	addi	a5,a5,40
ffffffffc02008aa:	f8d993e3          	bne	s3,a3,ffffffffc0200830 <slub_alloc.part.0+0x1e>
    if (size > (size_t)-1 - SLUB_HEADER_SIZE - (PGSIZE - 1)) {
ffffffffc02008ae:	77fd                	lui	a5,0xfffff
ffffffffc02008b0:	fc078793          	addi	a5,a5,-64 # ffffffffffffefc0 <end+0x3fde6dc0>
ffffffffc02008b4:	0ea7eb63          	bltu	a5,a0,ffffffffc02009aa <slub_alloc.part.0+0x198>
    size_t nr_pages = (size + SLUB_HEADER_SIZE + PGSIZE - 1) / PGSIZE;
ffffffffc02008b8:	6405                	lui	s0,0x1
ffffffffc02008ba:	03f40413          	addi	s0,s0,63 # 103f <kern_entry-0xffffffffc01fefc1>
ffffffffc02008be:	9522                	add	a0,a0,s0
ffffffffc02008c0:	00c55413          	srli	s0,a0,0xc
    struct Page *page = alloc_pages(nr_pages);
ffffffffc02008c4:	8522                	mv	a0,s0
ffffffffc02008c6:	d1fff0ef          	jal	ra,ffffffffc02005e4 <alloc_pages>
    if (page == NULL) {
ffffffffc02008ca:	c165                	beqz	a0,ffffffffc02009aa <slub_alloc.part.0+0x198>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02008cc:	00018797          	auipc	a5,0x18
ffffffffc02008d0:	8fc7b783          	ld	a5,-1796(a5) # ffffffffc02181c8 <pages>
ffffffffc02008d4:	40f507b3          	sub	a5,a0,a5
ffffffffc02008d8:	00004717          	auipc	a4,0x4
ffffffffc02008dc:	db073703          	ld	a4,-592(a4) # ffffffffc0204688 <nbase+0x8>
ffffffffc02008e0:	878d                	srai	a5,a5,0x3
ffffffffc02008e2:	02e787b3          	mul	a5,a5,a4
ffffffffc02008e6:	00004697          	auipc	a3,0x4
ffffffffc02008ea:	d9a6b683          	ld	a3,-614(a3) # ffffffffc0204680 <nbase>
    slab->inuse = 1;
ffffffffc02008ee:	4705                	li	a4,1
ffffffffc02008f0:	97b6                	add	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02008f2:	07b2                	slli	a5,a5,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc02008f4:	00018697          	auipc	a3,0x18
ffffffffc02008f8:	8f46b683          	ld	a3,-1804(a3) # ffffffffc02181e8 <va_pa_offset>
ffffffffc02008fc:	97b6                	add	a5,a5,a3
    slab->page = page;
ffffffffc02008fe:	ef88                	sd	a0,24(a5)
    elm->prev = elm->next = elm;
ffffffffc0200900:	e79c                	sd	a5,8(a5)
ffffffffc0200902:	e39c                	sd	a5,0(a5)
    slab->cache = NULL;
ffffffffc0200904:	0007b823          	sd	zero,16(a5)
    slab->freelist = NULL;
ffffffffc0200908:	0207b023          	sd	zero,32(a5)
    slab->inuse = 1;
ffffffffc020090c:	f798                	sd	a4,40(a5)
    slab->capacity = 1;
ffffffffc020090e:	fb98                	sd	a4,48(a5)
    slab->nr_pages = nr_pages;
ffffffffc0200910:	ff80                	sd	s0,56(a5)
    return (char *)slab + SLUB_HEADER_SIZE;
ffffffffc0200912:	04078513          	addi	a0,a5,64
ffffffffc0200916:	bfb5                	j	ffffffffc0200892 <slub_alloc.part.0+0x80>
    struct Page *page = alloc_pages(1);
ffffffffc0200918:	4505                	li	a0,1
ffffffffc020091a:	ccbff0ef          	jal	ra,ffffffffc02005e4 <alloc_pages>
    if (page == NULL) {
ffffffffc020091e:	c551                	beqz	a0,ffffffffc02009aa <slub_alloc.part.0+0x198>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200920:	00018717          	auipc	a4,0x18
ffffffffc0200924:	8a873703          	ld	a4,-1880(a4) # ffffffffc02181c8 <pages>
ffffffffc0200928:	40e50733          	sub	a4,a0,a4
ffffffffc020092c:	00004797          	auipc	a5,0x4
ffffffffc0200930:	d5c7b783          	ld	a5,-676(a5) # ffffffffc0204688 <nbase+0x8>
ffffffffc0200934:	870d                	srai	a4,a4,0x3
ffffffffc0200936:	02f70733          	mul	a4,a4,a5
ffffffffc020093a:	00004697          	auipc	a3,0x4
ffffffffc020093e:	d466b683          	ld	a3,-698(a3) # ffffffffc0204680 <nbase>
    slab->capacity = (PGSIZE - SLUB_HEADER_SIZE) / cache->object_size;
ffffffffc0200942:	6785                	lui	a5,0x1
ffffffffc0200944:	fc078793          	addi	a5,a5,-64 # fc0 <kern_entry-0xffffffffc01ff040>
ffffffffc0200948:	9736                	add	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020094a:	0732                	slli	a4,a4,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc020094c:	00018697          	auipc	a3,0x18
ffffffffc0200950:	89c6b683          	ld	a3,-1892(a3) # ffffffffc02181e8 <va_pa_offset>
ffffffffc0200954:	9736                	add	a4,a4,a3
ffffffffc0200956:	e718                	sd	a4,8(a4)
ffffffffc0200958:	e318                	sd	a4,0(a4)
    slab->capacity = (PGSIZE - SLUB_HEADER_SIZE) / cache->object_size;
ffffffffc020095a:	000ab583          	ld	a1,0(s5)
    slab->nr_pages = 1;
ffffffffc020095e:	4685                	li	a3,1
    slab->cache = cache;
ffffffffc0200960:	01573823          	sd	s5,16(a4)
    slab->capacity = (PGSIZE - SLUB_HEADER_SIZE) / cache->object_size;
ffffffffc0200964:	02b7d633          	divu	a2,a5,a1
    slab->page = page;
ffffffffc0200968:	ef08                	sd	a0,24(a4)
    slab->freelist = NULL;
ffffffffc020096a:	02073023          	sd	zero,32(a4)
    slab->inuse = 0;
ffffffffc020096e:	02073423          	sd	zero,40(a4)
    slab->nr_pages = 1;
ffffffffc0200972:	ff14                	sd	a3,56(a4)
    slab->capacity = (PGSIZE - SLUB_HEADER_SIZE) / cache->object_size;
ffffffffc0200974:	fb10                	sd	a2,48(a4)
    assert(slab->capacity > 0);
ffffffffc0200976:	04b7ec63          	bltu	a5,a1,ffffffffc02009ce <slub_alloc.part.0+0x1bc>
ffffffffc020097a:	167d                	addi	a2,a2,-1
ffffffffc020097c:	02b607b3          	mul	a5,a2,a1
ffffffffc0200980:	4681                	li	a3,0
ffffffffc0200982:	04078793          	addi	a5,a5,64
ffffffffc0200986:	97ba                	add	a5,a5,a4
ffffffffc0200988:	a011                	j	ffffffffc020098c <slub_alloc.part.0+0x17a>
ffffffffc020098a:	167d                	addi	a2,a2,-1
        *(void **)object = slab->freelist;
ffffffffc020098c:	e394                	sd	a3,0(a5)
        slab->freelist = object;
ffffffffc020098e:	f31c                	sd	a5,32(a4)
        void *object = objects + (i - 1) * cache->object_size;
ffffffffc0200990:	86be                	mv	a3,a5
    for (size_t i = slab->capacity; i > 0; i--) {
ffffffffc0200992:	8f8d                	sub	a5,a5,a1
ffffffffc0200994:	fa7d                	bnez	a2,ffffffffc020098a <slub_alloc.part.0+0x178>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200996:	010ab783          	ld	a5,16(s5)
        void *object = slab->freelist;
ffffffffc020099a:	7308                	ld	a0,32(a4)
    prev->next = next->prev = elm;
ffffffffc020099c:	e398                	sd	a4,0(a5)
ffffffffc020099e:	00eab823          	sd	a4,16(s5)
    elm->prev = prev;
ffffffffc02009a2:	e300                	sd	s0,0(a4)
    elm->next = next;
ffffffffc02009a4:	e71c                	sd	a5,8(a4)
ffffffffc02009a6:	843a                	mv	s0,a4
ffffffffc02009a8:	bd45                	j	ffffffffc0200858 <slub_alloc.part.0+0x46>
                return NULL;
ffffffffc02009aa:	4501                	li	a0,0
ffffffffc02009ac:	b5dd                	j	ffffffffc0200892 <slub_alloc.part.0+0x80>
        assert(object != NULL && slab->inuse < slab->capacity);
ffffffffc02009ae:	00003697          	auipc	a3,0x3
ffffffffc02009b2:	bda68693          	addi	a3,a3,-1062 # ffffffffc0203588 <etext+0x474>
ffffffffc02009b6:	00003617          	auipc	a2,0x3
ffffffffc02009ba:	b9260613          	addi	a2,a2,-1134 # ffffffffc0203548 <etext+0x434>
ffffffffc02009be:	08400593          	li	a1,132
ffffffffc02009c2:	00003517          	auipc	a0,0x3
ffffffffc02009c6:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0203560 <etext+0x44c>
ffffffffc02009ca:	80dff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slab->capacity > 0);
ffffffffc02009ce:	00003697          	auipc	a3,0x3
ffffffffc02009d2:	ba268693          	addi	a3,a3,-1118 # ffffffffc0203570 <etext+0x45c>
ffffffffc02009d6:	00003617          	auipc	a2,0x3
ffffffffc02009da:	b7260613          	addi	a2,a2,-1166 # ffffffffc0203548 <etext+0x434>
ffffffffc02009de:	04a00593          	li	a1,74
ffffffffc02009e2:	00003517          	auipc	a0,0x3
ffffffffc02009e6:	b7e50513          	addi	a0,a0,-1154 # ffffffffc0203560 <etext+0x44c>
ffffffffc02009ea:	fecff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02009ee <slub_init>:
    if (slub_ready) {
ffffffffc02009ee:	00018817          	auipc	a6,0x18
ffffffffc02009f2:	80280813          	addi	a6,a6,-2046 # ffffffffc02181f0 <slub_ready>
ffffffffc02009f6:	00082783          	lw	a5,0(a6)
ffffffffc02009fa:	e7b9                	bnez	a5,ffffffffc0200a48 <slub_init+0x5a>
ffffffffc02009fc:	00003617          	auipc	a2,0x3
ffffffffc0200a00:	24460613          	addi	a2,a2,580 # ffffffffc0203c40 <slub_sizes+0x8>
ffffffffc0200a04:	00007797          	auipc	a5,0x7
ffffffffc0200a08:	61c78793          	addi	a5,a5,1564 # ffffffffc0208020 <slub_caches+0x8>
ffffffffc0200a0c:	00007597          	auipc	a1,0x7
ffffffffc0200a10:	77c58593          	addi	a1,a1,1916 # ffffffffc0208188 <slub_caches+0x170>
        assert(slub_sizes[i] >= sizeof(void *) &&
ffffffffc0200a14:	4741                	li	a4,16
ffffffffc0200a16:	451d                	li	a0,7
ffffffffc0200a18:	a039                	j	ffffffffc0200a26 <slub_init+0x38>
ffffffffc0200a1a:	6218                	ld	a4,0(a2)
ffffffffc0200a1c:	02878793          	addi	a5,a5,40
ffffffffc0200a20:	0621                	addi	a2,a2,8
ffffffffc0200a22:	02e57463          	bgeu	a0,a4,ffffffffc0200a4a <slub_init+0x5c>
ffffffffc0200a26:	00f77693          	andi	a3,a4,15
ffffffffc0200a2a:	e285                	bnez	a3,ffffffffc0200a4a <slub_init+0x5c>
        slub_caches[i].object_size = slub_sizes[i];
ffffffffc0200a2c:	01078693          	addi	a3,a5,16
ffffffffc0200a30:	fee7bc23          	sd	a4,-8(a5)
    elm->prev = elm->next = elm;
ffffffffc0200a34:	e79c                	sd	a5,8(a5)
ffffffffc0200a36:	e39c                	sd	a5,0(a5)
ffffffffc0200a38:	ef94                	sd	a3,24(a5)
ffffffffc0200a3a:	eb94                	sd	a3,16(a5)
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
ffffffffc0200a3c:	fcb79fe3          	bne	a5,a1,ffffffffc0200a1a <slub_init+0x2c>
    slub_ready = 1;
ffffffffc0200a40:	4785                	li	a5,1
ffffffffc0200a42:	00f82023          	sw	a5,0(a6)
ffffffffc0200a46:	8082                	ret
ffffffffc0200a48:	8082                	ret
slub_init(void) {
ffffffffc0200a4a:	1141                	addi	sp,sp,-16
        assert(slub_sizes[i] >= sizeof(void *) &&
ffffffffc0200a4c:	00003697          	auipc	a3,0x3
ffffffffc0200a50:	b6c68693          	addi	a3,a3,-1172 # ffffffffc02035b8 <etext+0x4a4>
ffffffffc0200a54:	00003617          	auipc	a2,0x3
ffffffffc0200a58:	af460613          	addi	a2,a2,-1292 # ffffffffc0203548 <etext+0x434>
ffffffffc0200a5c:	03200593          	li	a1,50
ffffffffc0200a60:	00003517          	auipc	a0,0x3
ffffffffc0200a64:	b0050513          	addi	a0,a0,-1280 # ffffffffc0203560 <etext+0x44c>
slub_init(void) {
ffffffffc0200a68:	e406                	sd	ra,8(sp)
        assert(slub_sizes[i] >= sizeof(void *) &&
ffffffffc0200a6a:	f6cff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0200a6e <slub_free>:
    if (ptr == NULL) {
ffffffffc0200a6e:	c15d                	beqz	a0,ffffffffc0200b14 <slub_free+0xa6>
slub_free(void *ptr) {
ffffffffc0200a70:	1141                	addi	sp,sp,-16
ffffffffc0200a72:	e406                	sd	ra,8(sp)
    assert(slub_ready);
ffffffffc0200a74:	00017797          	auipc	a5,0x17
ffffffffc0200a78:	77c7a783          	lw	a5,1916(a5) # ffffffffc02181f0 <slub_ready>
ffffffffc0200a7c:	cfe9                	beqz	a5,ffffffffc0200b56 <slub_free+0xe8>
    struct slub_slab *slab = (struct slub_slab *)ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0200a7e:	77fd                	lui	a5,0xfffff
ffffffffc0200a80:	8fe9                	and	a5,a5,a0
    assert(slab->page != NULL && slab->inuse > 0);
ffffffffc0200a82:	6f98                	ld	a4,24(a5)
ffffffffc0200a84:	cb4d                	beqz	a4,ffffffffc0200b36 <slub_free+0xc8>
ffffffffc0200a86:	7794                	ld	a3,40(a5)
ffffffffc0200a88:	c6dd                	beqz	a3,ffffffffc0200b36 <slub_free+0xc8>
    if (slab->cache == NULL) {
ffffffffc0200a8a:	6b90                	ld	a2,16(a5)
ffffffffc0200a8c:	ce0d                	beqz	a2,ffffffffc0200ac6 <slub_free+0x58>
    uintptr_t offset = (uintptr_t)ptr - ((uintptr_t)slab + SLUB_HEADER_SIZE);
ffffffffc0200a8e:	fc050713          	addi	a4,a0,-64
    assert((uintptr_t)ptr >= (uintptr_t)slab + SLUB_HEADER_SIZE &&
ffffffffc0200a92:	04078593          	addi	a1,a5,64 # fffffffffffff040 <end+0x3fde6e40>
    uintptr_t offset = (uintptr_t)ptr - ((uintptr_t)slab + SLUB_HEADER_SIZE);
ffffffffc0200a96:	8f1d                	sub	a4,a4,a5
    assert((uintptr_t)ptr >= (uintptr_t)slab + SLUB_HEADER_SIZE &&
ffffffffc0200a98:	06b56f63          	bltu	a0,a1,ffffffffc0200b16 <slub_free+0xa8>
ffffffffc0200a9c:	7b8c                	ld	a1,48(a5)
ffffffffc0200a9e:	00063803          	ld	a6,0(a2)
ffffffffc0200aa2:	030588b3          	mul	a7,a1,a6
ffffffffc0200aa6:	07177863          	bgeu	a4,a7,ffffffffc0200b16 <slub_free+0xa8>
ffffffffc0200aaa:	03077733          	remu	a4,a4,a6
ffffffffc0200aae:	e725                	bnez	a4,ffffffffc0200b16 <slub_free+0xa8>
    if (slab->inuse == slab->capacity) {
ffffffffc0200ab0:	02b68463          	beq	a3,a1,ffffffffc0200ad8 <slub_free+0x6a>
    *(void **)ptr = slab->freelist;
ffffffffc0200ab4:	7398                	ld	a4,32(a5)
    slab->inuse--;
ffffffffc0200ab6:	16fd                	addi	a3,a3,-1
    *(void **)ptr = slab->freelist;
ffffffffc0200ab8:	e118                	sd	a4,0(a0)
    slab->freelist = ptr;
ffffffffc0200aba:	f388                	sd	a0,32(a5)
    slab->inuse--;
ffffffffc0200abc:	f794                	sd	a3,40(a5)
    if (slab->inuse == 0) {
ffffffffc0200abe:	c2a1                	beqz	a3,ffffffffc0200afe <slub_free+0x90>
}
ffffffffc0200ac0:	60a2                	ld	ra,8(sp)
ffffffffc0200ac2:	0141                	addi	sp,sp,16
ffffffffc0200ac4:	8082                	ret
        assert(ptr == (char *)slab + SLUB_HEADER_SIZE);
ffffffffc0200ac6:	04078693          	addi	a3,a5,64
ffffffffc0200aca:	0ad51663          	bne	a0,a3,ffffffffc0200b76 <slub_free+0x108>
}
ffffffffc0200ace:	60a2                	ld	ra,8(sp)
        free_pages(slab->page, slab->nr_pages);
ffffffffc0200ad0:	7f8c                	ld	a1,56(a5)
ffffffffc0200ad2:	853a                	mv	a0,a4
}
ffffffffc0200ad4:	0141                	addi	sp,sp,16
        free_pages(slab->page, slab->nr_pages);
ffffffffc0200ad6:	be29                	j	ffffffffc02005f0 <free_pages>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ad8:	6798                	ld	a4,8(a5)
ffffffffc0200ada:	638c                	ld	a1,0(a5)
        list_add(&cache->partial, &slab->link);
ffffffffc0200adc:	00860813          	addi	a6,a2,8
    slab->inuse--;
ffffffffc0200ae0:	16fd                	addi	a3,a3,-1
    prev->next = next;
ffffffffc0200ae2:	e598                	sd	a4,8(a1)
    next->prev = prev;
ffffffffc0200ae4:	e30c                	sd	a1,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0200ae6:	e79c                	sd	a5,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200ae8:	6a18                	ld	a4,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200aea:	e31c                	sd	a5,0(a4)
ffffffffc0200aec:	ea1c                	sd	a5,16(a2)
    elm->next = next;
ffffffffc0200aee:	e798                	sd	a4,8(a5)
    *(void **)ptr = slab->freelist;
ffffffffc0200af0:	7398                	ld	a4,32(a5)
    elm->prev = prev;
ffffffffc0200af2:	0107b023          	sd	a6,0(a5)
ffffffffc0200af6:	e118                	sd	a4,0(a0)
    slab->freelist = ptr;
ffffffffc0200af8:	f388                	sd	a0,32(a5)
    slab->inuse--;
ffffffffc0200afa:	f794                	sd	a3,40(a5)
    if (slab->inuse == 0) {
ffffffffc0200afc:	f2f1                	bnez	a3,ffffffffc0200ac0 <slub_free+0x52>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200afe:	6394                	ld	a3,0(a5)
ffffffffc0200b00:	6798                	ld	a4,8(a5)
        free_pages(slab->page, 1);
ffffffffc0200b02:	6f88                	ld	a0,24(a5)
}
ffffffffc0200b04:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200b06:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0200b08:	e314                	sd	a3,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0200b0a:	e79c                	sd	a5,8(a5)
ffffffffc0200b0c:	e39c                	sd	a5,0(a5)
        free_pages(slab->page, 1);
ffffffffc0200b0e:	4585                	li	a1,1
}
ffffffffc0200b10:	0141                	addi	sp,sp,16
        free_pages(slab->page, 1);
ffffffffc0200b12:	bcf9                	j	ffffffffc02005f0 <free_pages>
ffffffffc0200b14:	8082                	ret
    assert((uintptr_t)ptr >= (uintptr_t)slab + SLUB_HEADER_SIZE &&
ffffffffc0200b16:	00003697          	auipc	a3,0x3
ffffffffc0200b1a:	b4a68693          	addi	a3,a3,-1206 # ffffffffc0203660 <etext+0x54c>
ffffffffc0200b1e:	00003617          	auipc	a2,0x3
ffffffffc0200b22:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0203548 <etext+0x434>
ffffffffc0200b26:	0a100593          	li	a1,161
ffffffffc0200b2a:	00003517          	auipc	a0,0x3
ffffffffc0200b2e:	a3650513          	addi	a0,a0,-1482 # ffffffffc0203560 <etext+0x44c>
ffffffffc0200b32:	ea4ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slab->page != NULL && slab->inuse > 0);
ffffffffc0200b36:	00003697          	auipc	a3,0x3
ffffffffc0200b3a:	ada68693          	addi	a3,a3,-1318 # ffffffffc0203610 <etext+0x4fc>
ffffffffc0200b3e:	00003617          	auipc	a2,0x3
ffffffffc0200b42:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0203548 <etext+0x434>
ffffffffc0200b46:	09800593          	li	a1,152
ffffffffc0200b4a:	00003517          	auipc	a0,0x3
ffffffffc0200b4e:	a1650513          	addi	a0,a0,-1514 # ffffffffc0203560 <etext+0x44c>
ffffffffc0200b52:	e84ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0200b56:	00003697          	auipc	a3,0x3
ffffffffc0200b5a:	aaa68693          	addi	a3,a3,-1366 # ffffffffc0203600 <etext+0x4ec>
ffffffffc0200b5e:	00003617          	auipc	a2,0x3
ffffffffc0200b62:	9ea60613          	addi	a2,a2,-1558 # ffffffffc0203548 <etext+0x434>
ffffffffc0200b66:	09500593          	li	a1,149
ffffffffc0200b6a:	00003517          	auipc	a0,0x3
ffffffffc0200b6e:	9f650513          	addi	a0,a0,-1546 # ffffffffc0203560 <etext+0x44c>
ffffffffc0200b72:	e64ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(ptr == (char *)slab + SLUB_HEADER_SIZE);
ffffffffc0200b76:	00003697          	auipc	a3,0x3
ffffffffc0200b7a:	ac268693          	addi	a3,a3,-1342 # ffffffffc0203638 <etext+0x524>
ffffffffc0200b7e:	00003617          	auipc	a2,0x3
ffffffffc0200b82:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0203548 <etext+0x434>
ffffffffc0200b86:	09a00593          	li	a1,154
ffffffffc0200b8a:	00003517          	auipc	a0,0x3
ffffffffc0200b8e:	9d650513          	addi	a0,a0,-1578 # ffffffffc0203560 <etext+0x44c>
ffffffffc0200b92:	e44ff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0200b96 <slub_test_sizes>:
}

static void
slub_test_sizes(void) {
ffffffffc0200b96:	de010113          	addi	sp,sp,-544
ffffffffc0200b9a:	20913423          	sd	s1,520(sp)
ffffffffc0200b9e:	20113c23          	sd	ra,536(sp)
ffffffffc0200ba2:	20813823          	sd	s0,528(sp)
ffffffffc0200ba6:	21213023          	sd	s2,512(sp)
ffffffffc0200baa:	ffce                	sd	s3,504(sp)
ffffffffc0200bac:	fbd2                	sd	s4,496(sp)
ffffffffc0200bae:	f7d6                	sd	s5,488(sp)
ffffffffc0200bb0:	f3da                	sd	s6,480(sp)
ffffffffc0200bb2:	efde                	sd	s7,472(sp)
    size_t before = nr_free_pages();
ffffffffc0200bb4:	a49ff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0200bb8:	84aa                	mv	s1,a0
    const size_t sizes[] = {
ffffffffc0200bba:	00003797          	auipc	a5,0x3
ffffffffc0200bbe:	f9678793          	addi	a5,a5,-106 # ffffffffc0203b50 <etext+0xa3c>
ffffffffc0200bc2:	870a                	mv	a4,sp
ffffffffc0200bc4:	00003817          	auipc	a6,0x3
ffffffffc0200bc8:	06c80813          	addi	a6,a6,108 # ffffffffc0203c30 <etext+0xb1c>
ffffffffc0200bcc:	6388                	ld	a0,0(a5)
ffffffffc0200bce:	678c                	ld	a1,8(a5)
ffffffffc0200bd0:	6b90                	ld	a2,16(a5)
ffffffffc0200bd2:	6f94                	ld	a3,24(a5)
ffffffffc0200bd4:	e308                	sd	a0,0(a4)
ffffffffc0200bd6:	e70c                	sd	a1,8(a4)
ffffffffc0200bd8:	eb10                	sd	a2,16(a4)
ffffffffc0200bda:	ef14                	sd	a3,24(a4)
ffffffffc0200bdc:	02078793          	addi	a5,a5,32
ffffffffc0200be0:	02070713          	addi	a4,a4,32
ffffffffc0200be4:	ff0794e3          	bne	a5,a6,ffffffffc0200bcc <slub_test_sizes+0x36>
ffffffffc0200be8:	6394                	ld	a3,0(a5)
    assert(slub_ready);
ffffffffc0200bea:	00017917          	auipc	s2,0x17
ffffffffc0200bee:	60690913          	addi	s2,s2,1542 # ffffffffc02181f0 <slub_ready>
ffffffffc0200bf2:	00092783          	lw	a5,0(s2)
    const size_t sizes[] = {
ffffffffc0200bf6:	e314                	sd	a3,0(a4)
    assert(slub_ready);
ffffffffc0200bf8:	16078b63          	beqz	a5,ffffffffc0200d6e <slub_test_sizes+0x1d8>
ffffffffc0200bfc:	11a0                	addi	s0,sp,232
ffffffffc0200bfe:	8aa2                	mv	s5,s0
ffffffffc0200c00:	4b85                	li	s7,1
ffffffffc0200c02:	4b01                	li	s6,0
    enum { count = sizeof(sizes) / sizeof(sizes[0]) };
    void *objects[count];

    assert(slub_alloc(0) == NULL);
    for (size_t i = 0; i < count; i++) {
        objects[i] = slub_alloc(sizes[i]);
ffffffffc0200c04:	4a05                	li	s4,1
    for (size_t i = 0; i < count; i++) {
ffffffffc0200c06:	49f5                	li	s3,29
ffffffffc0200c08:	8552                	mv	a0,s4
ffffffffc0200c0a:	c09ff0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
        objects[i] = slub_alloc(sizes[i]);
ffffffffc0200c0e:	00aab023          	sd	a0,0(s5)
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0200c12:	c535                	beqz	a0,ffffffffc0200c7e <slub_test_sizes+0xe8>
ffffffffc0200c14:	00f57813          	andi	a6,a0,15
ffffffffc0200c18:	06081363          	bnez	a6,ffffffffc0200c7e <slub_test_sizes+0xe8>
ffffffffc0200c1c:	0ffb7793          	zext.b	a5,s6
ffffffffc0200c20:	014505b3          	add	a1,a0,s4
ffffffffc0200c24:	872a                	mv	a4,a0
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0200c26:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0200c2a:	27c5                	addiw	a5,a5,17
ffffffffc0200c2c:	0705                	addi	a4,a4,1
ffffffffc0200c2e:	0ff7f793          	zext.b	a5,a5
ffffffffc0200c32:	feb71ae3          	bne	a4,a1,ffffffffc0200c26 <slub_test_sizes+0x90>
        slub_test_write(objects[i], sizes[i], (unsigned char)i);
        for (size_t j = 0; j < i; j++) {
ffffffffc0200c36:	020b0563          	beqz	s6,ffffffffc0200c60 <slub_test_sizes+0xca>
ffffffffc0200c3a:	00810893          	addi	a7,sp,8
ffffffffc0200c3e:	8746                	mv	a4,a7
ffffffffc0200c40:	87a2                	mv	a5,s0
ffffffffc0200c42:	4605                	li	a2,1
ffffffffc0200c44:	a019                	j	ffffffffc0200c4a <slub_test_sizes+0xb4>
            slub_test_disjoint(objects[i], sizes[i], objects[j], sizes[j]);
ffffffffc0200c46:	6310                	ld	a2,0(a4)
ffffffffc0200c48:	0721                	addi	a4,a4,8
    uintptr_t a_start = (uintptr_t)a, b_start = (uintptr_t)b;
ffffffffc0200c4a:	6394                	ld	a3,0(a5)
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0200c4c:	00b6f563          	bgeu	a3,a1,ffffffffc0200c56 <slub_test_sizes+0xc0>
ffffffffc0200c50:	96b2                	add	a3,a3,a2
ffffffffc0200c52:	0cd56e63          	bltu	a0,a3,ffffffffc0200d2e <slub_test_sizes+0x198>
        for (size_t j = 0; j < i; j++) {
ffffffffc0200c56:	07a1                	addi	a5,a5,8
ffffffffc0200c58:	ff5797e3          	bne	a5,s5,ffffffffc0200c46 <slub_test_sizes+0xb0>
    for (size_t i = 0; i < count; i++) {
ffffffffc0200c5c:	053b8163          	beq	s7,s3,ffffffffc0200c9e <slub_test_sizes+0x108>
    assert(slub_ready);
ffffffffc0200c60:	00092703          	lw	a4,0(s2)
        objects[i] = slub_alloc(sizes[i]);
ffffffffc0200c64:	003b9793          	slli	a5,s7,0x3
ffffffffc0200c68:	0b94                	addi	a3,sp,464
ffffffffc0200c6a:	97b6                	add	a5,a5,a3
ffffffffc0200c6c:	e307ba03          	ld	s4,-464(a5)
    assert(slub_ready);
ffffffffc0200c70:	0b05                	addi	s6,s6,1
ffffffffc0200c72:	0b85                	addi	s7,s7,1
ffffffffc0200c74:	0aa1                	addi	s5,s5,8
ffffffffc0200c76:	0e070c63          	beqz	a4,ffffffffc0200d6e <slub_test_sizes+0x1d8>
    if (size == 0) {
ffffffffc0200c7a:	f80a17e3          	bnez	s4,ffffffffc0200c08 <slub_test_sizes+0x72>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0200c7e:	00003697          	auipc	a3,0x3
ffffffffc0200c82:	a7268693          	addi	a3,a3,-1422 # ffffffffc02036f0 <etext+0x5dc>
ffffffffc0200c86:	00003617          	auipc	a2,0x3
ffffffffc0200c8a:	8c260613          	addi	a2,a2,-1854 # ffffffffc0203548 <etext+0x434>
ffffffffc0200c8e:	0be00593          	li	a1,190
ffffffffc0200c92:	00003517          	auipc	a0,0x3
ffffffffc0200c96:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0203560 <etext+0x44c>
ffffffffc0200c9a:	d3cff0ef          	jal	ra,ffffffffc02001d6 <__panic>
ffffffffc0200c9e:	85a2                	mv	a1,s0
ffffffffc0200ca0:	4605                	li	a2,1
        }
    }
    for (size_t i = 0; i < count; i++) {
ffffffffc0200ca2:	4575                	li	a0,29
        slub_test_read(objects[i], sizes[i], (unsigned char)i);
ffffffffc0200ca4:	6198                	ld	a4,0(a1)
ffffffffc0200ca6:	0ff87793          	zext.b	a5,a6
    for (size_t i = 0; i < size; i++) {
ffffffffc0200caa:	ce01                	beqz	a2,ffffffffc0200cc2 <slub_test_sizes+0x12c>
ffffffffc0200cac:	963a                	add	a2,a2,a4
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0200cae:	00074683          	lbu	a3,0(a4)
ffffffffc0200cb2:	04f69e63          	bne	a3,a5,ffffffffc0200d0e <slub_test_sizes+0x178>
    for (size_t i = 0; i < size; i++) {
ffffffffc0200cb6:	27c5                	addiw	a5,a5,17
ffffffffc0200cb8:	0705                	addi	a4,a4,1
ffffffffc0200cba:	0ff7f793          	zext.b	a5,a5
ffffffffc0200cbe:	fee618e3          	bne	a2,a4,ffffffffc0200cae <slub_test_sizes+0x118>
    for (size_t i = 0; i < count; i++) {
ffffffffc0200cc2:	0805                	addi	a6,a6,1
ffffffffc0200cc4:	05a1                	addi	a1,a1,8
ffffffffc0200cc6:	00a80663          	beq	a6,a0,ffffffffc0200cd2 <slub_test_sizes+0x13c>
        slub_test_read(objects[i], sizes[i], (unsigned char)i);
ffffffffc0200cca:	0008b603          	ld	a2,0(a7)
ffffffffc0200cce:	08a1                	addi	a7,a7,8
ffffffffc0200cd0:	bfd1                	j	ffffffffc0200ca4 <slub_test_sizes+0x10e>
ffffffffc0200cd2:	1c810913          	addi	s2,sp,456
    }
    for (size_t i = count; i > 0; i--) {
        slub_free(objects[i - 1]);
ffffffffc0200cd6:	00093503          	ld	a0,0(s2)
ffffffffc0200cda:	d95ff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    for (size_t i = count; i > 0; i--) {
ffffffffc0200cde:	87ca                	mv	a5,s2
ffffffffc0200ce0:	1961                	addi	s2,s2,-8
ffffffffc0200ce2:	fe879ae3          	bne	a5,s0,ffffffffc0200cd6 <slub_test_sizes+0x140>
    }
    assert(nr_free_pages() == before);
ffffffffc0200ce6:	917ff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0200cea:	06951263          	bne	a0,s1,ffffffffc0200d4e <slub_test_sizes+0x1b8>
}
ffffffffc0200cee:	21813083          	ld	ra,536(sp)
ffffffffc0200cf2:	21013403          	ld	s0,528(sp)
ffffffffc0200cf6:	20813483          	ld	s1,520(sp)
ffffffffc0200cfa:	20013903          	ld	s2,512(sp)
ffffffffc0200cfe:	79fe                	ld	s3,504(sp)
ffffffffc0200d00:	7a5e                	ld	s4,496(sp)
ffffffffc0200d02:	7abe                	ld	s5,488(sp)
ffffffffc0200d04:	7b1e                	ld	s6,480(sp)
ffffffffc0200d06:	6bfe                	ld	s7,472(sp)
ffffffffc0200d08:	22010113          	addi	sp,sp,544
ffffffffc0200d0c:	8082                	ret
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0200d0e:	00003697          	auipc	a3,0x3
ffffffffc0200d12:	a1268693          	addi	a3,a3,-1518 # ffffffffc0203720 <etext+0x60c>
ffffffffc0200d16:	00003617          	auipc	a2,0x3
ffffffffc0200d1a:	83260613          	addi	a2,a2,-1998 # ffffffffc0203548 <etext+0x434>
ffffffffc0200d1e:	0c700593          	li	a1,199
ffffffffc0200d22:	00003517          	auipc	a0,0x3
ffffffffc0200d26:	83e50513          	addi	a0,a0,-1986 # ffffffffc0203560 <etext+0x44c>
ffffffffc0200d2a:	cacff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0200d2e:	00002697          	auipc	a3,0x2
ffffffffc0200d32:	7da68693          	addi	a3,a3,2010 # ffffffffc0203508 <etext+0x3f4>
ffffffffc0200d36:	00003617          	auipc	a2,0x3
ffffffffc0200d3a:	81260613          	addi	a2,a2,-2030 # ffffffffc0203548 <etext+0x434>
ffffffffc0200d3e:	0ce00593          	li	a1,206
ffffffffc0200d42:	00003517          	auipc	a0,0x3
ffffffffc0200d46:	81e50513          	addi	a0,a0,-2018 # ffffffffc0203560 <etext+0x44c>
ffffffffc0200d4a:	c8cff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0200d4e:	00003697          	auipc	a3,0x3
ffffffffc0200d52:	a1268693          	addi	a3,a3,-1518 # ffffffffc0203760 <etext+0x64c>
ffffffffc0200d56:	00002617          	auipc	a2,0x2
ffffffffc0200d5a:	7f260613          	addi	a2,a2,2034 # ffffffffc0203548 <etext+0x434>
ffffffffc0200d5e:	0eb00593          	li	a1,235
ffffffffc0200d62:	00002517          	auipc	a0,0x2
ffffffffc0200d66:	7fe50513          	addi	a0,a0,2046 # ffffffffc0203560 <etext+0x44c>
ffffffffc0200d6a:	c6cff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0200d6e:	00003697          	auipc	a3,0x3
ffffffffc0200d72:	89268693          	addi	a3,a3,-1902 # ffffffffc0203600 <etext+0x4ec>
ffffffffc0200d76:	00002617          	auipc	a2,0x2
ffffffffc0200d7a:	7d260613          	addi	a2,a2,2002 # ffffffffc0203548 <etext+0x434>
ffffffffc0200d7e:	06e00593          	li	a1,110
ffffffffc0200d82:	00002517          	auipc	a0,0x2
ffffffffc0200d86:	7de50513          	addi	a0,a0,2014 # ffffffffc0203560 <etext+0x44c>
ffffffffc0200d8a:	c4cff0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0200d8e <slub_test_same_cache>:

static void
slub_test_same_cache(void) {
ffffffffc0200d8e:	99010113          	addi	sp,sp,-1648
ffffffffc0200d92:	65213823          	sd	s2,1616(sp)
ffffffffc0200d96:	63513c23          	sd	s5,1592(sp)
ffffffffc0200d9a:	63613823          	sd	s6,1584(sp)
ffffffffc0200d9e:	63713423          	sd	s7,1576(sp)
ffffffffc0200da2:	61913c23          	sd	s9,1560(sp)
ffffffffc0200da6:	61a13823          	sd	s10,1552(sp)
ffffffffc0200daa:	61b13423          	sd	s11,1544(sp)
ffffffffc0200dae:	66113423          	sd	ra,1640(sp)
ffffffffc0200db2:	66813023          	sd	s0,1632(sp)
ffffffffc0200db6:	64913c23          	sd	s1,1624(sp)
ffffffffc0200dba:	65313423          	sd	s3,1608(sp)
ffffffffc0200dbe:	65413023          	sd	s4,1600(sp)
ffffffffc0200dc2:	63813023          	sd	s8,1568(sp)
    size_t before = nr_free_pages();
ffffffffc0200dc6:	837ff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0200dca:	e42a                	sd	a0,8(sp)
ffffffffc0200dcc:	01810b93          	addi	s7,sp,24
ffffffffc0200dd0:	04000c93          	li	s9,64
ffffffffc0200dd4:	4d85                	li	s11,1
ffffffffc0200dd6:	4d01                	li	s10,0
ffffffffc0200dd8:	00017917          	auipc	s2,0x17
ffffffffc0200ddc:	41890913          	addi	s2,s2,1048 # ffffffffc02181f0 <slub_ready>
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0200de0:	7afd                	lui	s5,0xfffff
    void *reused[SLUB_TEST_CAPACITY];
    void *second[SLUB_TEST_CAPACITY];
    size_t reused_count = 0;

    /* Fill one page. Every returned object must be distinct and writable. */
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
ffffffffc0200de2:	03f00b13          	li	s6,63
    assert(slub_ready);
ffffffffc0200de6:	00092783          	lw	a5,0(s2)
ffffffffc0200dea:	3c078b63          	beqz	a5,ffffffffc02011c0 <slub_test_same_cache+0x432>
    if (size == 0) {
ffffffffc0200dee:	04000513          	li	a0,64
ffffffffc0200df2:	a21ff0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
        first[i] = slub_alloc(SLUB_TEST_OBJECT_SIZE);
ffffffffc0200df6:	00abb023          	sd	a0,0(s7)
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0200dfa:	36050363          	beqz	a0,ffffffffc0201160 <slub_test_same_cache+0x3d2>
ffffffffc0200dfe:	00f57413          	andi	s0,a0,15
ffffffffc0200e02:	34041f63          	bnez	s0,ffffffffc0201160 <slub_test_same_cache+0x3d2>
ffffffffc0200e06:	0ffd7793          	zext.b	a5,s10
ffffffffc0200e0a:	872a                	mv	a4,a0
    for (size_t i = 0; i < size; i++) {
ffffffffc0200e0c:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0200e10:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0200e14:	0ff6f793          	zext.b	a5,a3
ffffffffc0200e18:	0705                	addi	a4,a4,1
ffffffffc0200e1a:	ff9799e3          	bne	a5,s9,ffffffffc0200e0c <slub_test_same_cache+0x7e>
        slub_test_write(first[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)i);
        if (i != 0) {
ffffffffc0200e1e:	020d0b63          	beqz	s10,ffffffffc0200e54 <slub_test_same_cache+0xc6>
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc0200e22:	6c62                	ld	s8,24(sp)
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0200e24:	015577b3          	and	a5,a0,s5
ffffffffc0200e28:	015c79b3          	and	s3,s8,s5
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc0200e2c:	41379a63          	bne	a5,s3,ffffffffc0201240 <slub_test_same_cache+0x4b2>
ffffffffc0200e30:	1004                	addi	s1,sp,32
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0200e32:	04050693          	addi	a3,a0,64
ffffffffc0200e36:	87a6                	mv	a5,s1
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc0200e38:	8762                	mv	a4,s8
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0200e3a:	00d77663          	bgeu	a4,a3,ffffffffc0200e46 <slub_test_same_cache+0xb8>
ffffffffc0200e3e:	04070713          	addi	a4,a4,64
ffffffffc0200e42:	2ee56f63          	bltu	a0,a4,ffffffffc0201140 <slub_test_same_cache+0x3b2>
        }
        for (size_t j = 0; j < i; j++) {
ffffffffc0200e46:	01778563          	beq	a5,s7,ffffffffc0200e50 <slub_test_same_cache+0xc2>
            slub_test_disjoint(first[i], SLUB_TEST_OBJECT_SIZE,
ffffffffc0200e4a:	6398                	ld	a4,0(a5)
ffffffffc0200e4c:	07a1                	addi	a5,a5,8
ffffffffc0200e4e:	b7f5                	j	ffffffffc0200e3a <slub_test_same_cache+0xac>
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
ffffffffc0200e50:	016d8963          	beq	s11,s6,ffffffffc0200e62 <slub_test_same_cache+0xd4>
ffffffffc0200e54:	2c85                	addiw	s9,s9,1
ffffffffc0200e56:	0d05                	addi	s10,s10,1
ffffffffc0200e58:	0d85                	addi	s11,s11,1
ffffffffc0200e5a:	0ba1                	addi	s7,s7,8
ffffffffc0200e5c:	0ffcfc93          	zext.b	s9,s9
ffffffffc0200e60:	b759                	j	ffffffffc0200de6 <slub_test_same_cache+0x58>
                               first[j], SLUB_TEST_OBJECT_SIZE);
        }
    }
    assert(nr_free_pages() == before - 1);
ffffffffc0200e62:	f9aff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0200e66:	67a2                	ld	a5,8(sp)
ffffffffc0200e68:	fff78a93          	addi	s5,a5,-1
ffffffffc0200e6c:	39551a63          	bne	a0,s5,ffffffffc0201200 <slub_test_same_cache+0x472>
ffffffffc0200e70:	21810d13          	addi	s10,sp,536
ffffffffc0200e74:	02810b13          	addi	s6,sp,40
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc0200e78:	8562                	mv	a0,s8
ffffffffc0200e7a:	a021                	j	ffffffffc0200e82 <slub_test_same_cache+0xf4>

    /* Free alternate slots. Replacements must come from those slots only. */
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i += 2) {
        slub_free(first[i]);
ffffffffc0200e7c:	000b3503          	ld	a0,0(s6) # 10000 <kern_entry-0xffffffffc01f0000>
ffffffffc0200e80:	0b41                	addi	s6,s6,16
ffffffffc0200e82:	bedff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
        assert(nr_free_pages() == before - 1);
ffffffffc0200e86:	f76ff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0200e8a:	34aa9b63          	bne	s5,a0,ffffffffc02011e0 <slub_test_same_cache+0x452>
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0200e8e:	ffab17e3          	bne	s6,s10,ffffffffc0200e7c <slub_test_same_cache+0xee>
ffffffffc0200e92:	8526                	mv	a0,s1
ffffffffc0200e94:	04100613          	li	a2,65
    }
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0200e98:	4585                	li	a1,1
ffffffffc0200e9a:	03f00813          	li	a6,63
        slub_test_read(first[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)i);
ffffffffc0200e9e:	6118                	ld	a4,0(a0)
ffffffffc0200ea0:	0ff5f793          	zext.b	a5,a1
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0200ea4:	00074683          	lbu	a3,0(a4)
ffffffffc0200ea8:	1cf69063          	bne	a3,a5,ffffffffc0201068 <slub_test_same_cache+0x2da>
    for (size_t i = 0; i < size; i++) {
ffffffffc0200eac:	27c5                	addiw	a5,a5,17
ffffffffc0200eae:	0ff7f793          	zext.b	a5,a5
ffffffffc0200eb2:	0705                	addi	a4,a4,1
ffffffffc0200eb4:	fec798e3          	bne	a5,a2,ffffffffc0200ea4 <slub_test_same_cache+0x116>
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0200eb8:	2789                	addiw	a5,a5,2
ffffffffc0200eba:	0589                	addi	a1,a1,2
ffffffffc0200ebc:	0541                	addi	a0,a0,16
ffffffffc0200ebe:	0ff7f613          	zext.b	a2,a5
ffffffffc0200ec2:	fd059ee3          	bne	a1,a6,ffffffffc0200e9e <slub_test_same_cache+0x110>
ffffffffc0200ec6:	21010b13          	addi	s6,sp,528
ffffffffc0200eca:	8dda                	mv	s11,s6
ffffffffc0200ecc:	09b00a13          	li	s4,155
    }
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0200ed0:	0db00b93          	li	s7,219
    assert(slub_ready);
ffffffffc0200ed4:	00092783          	lw	a5,0(s2)
ffffffffc0200ed8:	2e078463          	beqz	a5,ffffffffc02011c0 <slub_test_same_cache+0x432>
    if (size == 0) {
ffffffffc0200edc:	04000513          	li	a0,64
ffffffffc0200ee0:	933ff0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
ffffffffc0200ee4:	8caa                	mv	s9,a0
        void *ptr = slub_alloc(SLUB_TEST_OBJECT_SIZE);
        bool was_freed = 0;
        for (size_t j = 0; j < SLUB_TEST_CAPACITY; j += 2) {
ffffffffc0200ee6:	1034                	addi	a3,sp,40
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc0200ee8:	87e2                	mv	a5,s8
        bool was_freed = 0;
ffffffffc0200eea:	4701                	li	a4,0
ffffffffc0200eec:	a019                	j	ffffffffc0200ef2 <slub_test_same_cache+0x164>
            was_freed |= ptr == first[j];
ffffffffc0200eee:	629c                	ld	a5,0(a3)
ffffffffc0200ef0:	06c1                	addi	a3,a3,16
ffffffffc0200ef2:	419787b3          	sub	a5,a5,s9
ffffffffc0200ef6:	0017b793          	seqz	a5,a5
ffffffffc0200efa:	8f5d                	or	a4,a4,a5
ffffffffc0200efc:	2701                	sext.w	a4,a4
        for (size_t j = 0; j < SLUB_TEST_CAPACITY; j += 2) {
ffffffffc0200efe:	ffa698e3          	bne	a3,s10,ffffffffc0200eee <slub_test_same_cache+0x160>
        }
        assert(was_freed);
ffffffffc0200f02:	30070f63          	beqz	a4,ffffffffc0201220 <slub_test_same_cache+0x492>
        for (size_t j = 0; j < reused_count; j++) {
ffffffffc0200f06:	87da                	mv	a5,s6
ffffffffc0200f08:	c419                	beqz	s0,ffffffffc0200f16 <slub_test_same_cache+0x188>
            assert(ptr != reused[j]);
ffffffffc0200f0a:	6398                	ld	a4,0(a5)
ffffffffc0200f0c:	27970a63          	beq	a4,s9,ffffffffc0201180 <slub_test_same_cache+0x3f2>
        for (size_t j = 0; j < reused_count; j++) {
ffffffffc0200f10:	07a1                	addi	a5,a5,8
ffffffffc0200f12:	ffb79ce3          	bne	a5,s11,ffffffffc0200f0a <slub_test_same_cache+0x17c>
        }
        reused[reused_count++] = ptr;
ffffffffc0200f16:	019db023          	sd	s9,0(s11)
ffffffffc0200f1a:	0405                	addi	s0,s0,1
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0200f1c:	240c8263          	beqz	s9,ffffffffc0201160 <slub_test_same_cache+0x3d2>
ffffffffc0200f20:	00fcf793          	andi	a5,s9,15
ffffffffc0200f24:	8766                	mv	a4,s9
ffffffffc0200f26:	22079d63          	bnez	a5,ffffffffc0201160 <slub_test_same_cache+0x3d2>
ffffffffc0200f2a:	fc0a079b          	addiw	a5,s4,-64
ffffffffc0200f2e:	0ff7f793          	zext.b	a5,a5
    for (size_t i = 0; i < size; i++) {
ffffffffc0200f32:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0200f36:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0200f3a:	0ff6f793          	zext.b	a5,a3
ffffffffc0200f3e:	0705                	addi	a4,a4,1
ffffffffc0200f40:	ff4799e3          	bne	a5,s4,ffffffffc0200f32 <slub_test_same_cache+0x1a4>
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0200f44:	2789                	addiw	a5,a5,2
ffffffffc0200f46:	0ff7fa13          	zext.b	s4,a5
ffffffffc0200f4a:	0da1                	addi	s11,s11,8
ffffffffc0200f4c:	f97a14e3          	bne	s4,s7,ffffffffc0200ed4 <slub_test_same_cache+0x146>
        slub_test_write(ptr, SLUB_TEST_OBJECT_SIZE, (unsigned char)(i + 91));
    }
    assert(nr_free_pages() == before - 1);
ffffffffc0200f50:	eacff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0200f54:	30aa9663          	bne	s5,a0,ffffffffc0201260 <slub_test_same_cache+0x4d2>
ffffffffc0200f58:	8526                	mv	a0,s1
ffffffffc0200f5a:	04100613          	li	a2,65
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0200f5e:	4585                	li	a1,1
ffffffffc0200f60:	03f00813          	li	a6,63
        slub_test_read(first[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)i);
ffffffffc0200f64:	6118                	ld	a4,0(a0)
ffffffffc0200f66:	0ff5f793          	zext.b	a5,a1
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0200f6a:	00074683          	lbu	a3,0(a4)
ffffffffc0200f6e:	0ef69d63          	bne	a3,a5,ffffffffc0201068 <slub_test_same_cache+0x2da>
    for (size_t i = 0; i < size; i++) {
ffffffffc0200f72:	27c5                	addiw	a5,a5,17
ffffffffc0200f74:	0ff7f793          	zext.b	a5,a5
ffffffffc0200f78:	0705                	addi	a4,a4,1
ffffffffc0200f7a:	fec798e3          	bne	a5,a2,ffffffffc0200f6a <slub_test_same_cache+0x1dc>
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0200f7e:	2789                	addiw	a5,a5,2
ffffffffc0200f80:	0589                	addi	a1,a1,2
ffffffffc0200f82:	0541                	addi	a0,a0,16
ffffffffc0200f84:	0ff7f613          	zext.b	a2,a5
ffffffffc0200f88:	fd059ee3          	bne	a1,a6,ffffffffc0200f64 <slub_test_same_cache+0x1d6>
ffffffffc0200f8c:	40810c13          	addi	s8,sp,1032
ffffffffc0200f90:	0c900d93          	li	s11,201
ffffffffc0200f94:	4d05                	li	s10,1
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0200f96:	7bfd                	lui	s7,0xfffff
    assert(slub_ready);
ffffffffc0200f98:	00092783          	lw	a5,0(s2)
ffffffffc0200f9c:	22078263          	beqz	a5,ffffffffc02011c0 <slub_test_same_cache+0x432>
    if (size == 0) {
ffffffffc0200fa0:	04000513          	li	a0,64
ffffffffc0200fa4:	86fff0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
    }

    /* A full slab forces a second page. Emptying one must spare the other. */
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
        second[i] = slub_alloc(SLUB_TEST_OBJECT_SIZE);
ffffffffc0200fa8:	00ac3023          	sd	a0,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0200fac:	1a050a63          	beqz	a0,ffffffffc0201160 <slub_test_same_cache+0x3d2>
ffffffffc0200fb0:	00f57793          	andi	a5,a0,15
ffffffffc0200fb4:	1a079663          	bnez	a5,ffffffffc0201160 <slub_test_same_cache+0x3d2>
ffffffffc0200fb8:	f88d079b          	addiw	a5,s10,-120
ffffffffc0200fbc:	0ff7f793          	zext.b	a5,a5
ffffffffc0200fc0:	872a                	mv	a4,a0
    for (size_t i = 0; i < size; i++) {
ffffffffc0200fc2:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0200fc6:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0200fca:	0ff6f793          	zext.b	a5,a3
ffffffffc0200fce:	0705                	addi	a4,a4,1
ffffffffc0200fd0:	fefd99e3          	bne	s11,a5,ffffffffc0200fc2 <slub_test_same_cache+0x234>
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0200fd4:	01757533          	and	a0,a0,s7
        slub_test_write(second[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)(i + 137));
        assert(slub_test_page(second[i]) != slub_test_page(first[0]));
ffffffffc0200fd8:	2aa98463          	beq	s3,a0,ffffffffc0201280 <slub_test_same_cache+0x4f2>
        if (i != 0) {
ffffffffc0200fdc:	4785                	li	a5,1
ffffffffc0200fde:	00fd0c63          	beq	s10,a5,ffffffffc0200ff6 <slub_test_same_cache+0x268>
            assert(slub_test_page(second[i]) == slub_test_page(second[0]));
ffffffffc0200fe2:	40813a03          	ld	s4,1032(sp)
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0200fe6:	017a77b3          	and	a5,s4,s7
            assert(slub_test_page(second[i]) == slub_test_page(second[0]));
ffffffffc0200fea:	2af51b63          	bne	a0,a5,ffffffffc02012a0 <slub_test_same_cache+0x512>
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
ffffffffc0200fee:	03f00793          	li	a5,63
ffffffffc0200ff2:	00fd0863          	beq	s10,a5,ffffffffc0201002 <slub_test_same_cache+0x274>
ffffffffc0200ff6:	2d85                	addiw	s11,s11,1
ffffffffc0200ff8:	0d05                	addi	s10,s10,1
ffffffffc0200ffa:	0ffdfd93          	zext.b	s11,s11
ffffffffc0200ffe:	0c21                	addi	s8,s8,8
ffffffffc0201000:	bf61                	j	ffffffffc0200f98 <slub_test_same_cache+0x20a>
        }
    }
    assert(nr_free_pages() == before - 2);
ffffffffc0201002:	dfaff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201006:	67a2                	ld	a5,8(sp)
ffffffffc0201008:	ffe78913          	addi	s2,a5,-2
ffffffffc020100c:	083c                	addi	a5,sp,24
ffffffffc020100e:	1f878993          	addi	s3,a5,504
ffffffffc0201012:	2b251763          	bne	a0,s2,ffffffffc02012c0 <slub_test_same_cache+0x532>
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
        slub_free(first[i]);
ffffffffc0201016:	6088                	ld	a0,0(s1)
ffffffffc0201018:	a57ff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
        assert(nr_free_pages() == before - 2);
ffffffffc020101c:	de0ff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201020:	2ca91063          	bne	s2,a0,ffffffffc02012e0 <slub_test_same_cache+0x552>
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
ffffffffc0201024:	04c1                	addi	s1,s1,16
ffffffffc0201026:	ff3498e3          	bne	s1,s3,ffffffffc0201016 <slub_test_same_cache+0x288>
ffffffffc020102a:	040e                	slli	s0,s0,0x3
ffffffffc020102c:	ff8b0793          	addi	a5,s6,-8
ffffffffc0201030:	943e                	add	s0,s0,a5
    }
    for (size_t i = 0; i + 1 < reused_count; i++) {
ffffffffc0201032:	048b0b63          	beq	s6,s0,ffffffffc0201088 <slub_test_same_cache+0x2fa>
        slub_free(reused[i]);
ffffffffc0201036:	000b3503          	ld	a0,0(s6)
        assert(nr_free_pages() == before - 2);
ffffffffc020103a:	0b21                	addi	s6,s6,8
        slub_free(reused[i]);
ffffffffc020103c:	a33ff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
        assert(nr_free_pages() == before - 2);
ffffffffc0201040:	dbcff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201044:	fea907e3          	beq	s2,a0,ffffffffc0201032 <slub_test_same_cache+0x2a4>
ffffffffc0201048:	00003697          	auipc	a3,0x3
ffffffffc020104c:	82868693          	addi	a3,a3,-2008 # ffffffffc0203870 <etext+0x75c>
ffffffffc0201050:	00002617          	auipc	a2,0x2
ffffffffc0201054:	4f860613          	addi	a2,a2,1272 # ffffffffc0203548 <etext+0x434>
ffffffffc0201058:	12e00593          	li	a1,302
ffffffffc020105c:	00002517          	auipc	a0,0x2
ffffffffc0201060:	50450513          	addi	a0,a0,1284 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201064:	972ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201068:	00002697          	auipc	a3,0x2
ffffffffc020106c:	6b868693          	addi	a3,a3,1720 # ffffffffc0203720 <etext+0x60c>
ffffffffc0201070:	00002617          	auipc	a2,0x2
ffffffffc0201074:	4d860613          	addi	a2,a2,1240 # ffffffffc0203548 <etext+0x434>
ffffffffc0201078:	0c700593          	li	a1,199
ffffffffc020107c:	00002517          	auipc	a0,0x2
ffffffffc0201080:	4e450513          	addi	a0,a0,1252 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201084:	952ff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    }
    slub_free(reused[reused_count - 1]);
ffffffffc0201088:	8566                	mv	a0,s9
ffffffffc020108a:	9e5ff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    assert(nr_free_pages() == before - 1);
ffffffffc020108e:	d6eff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201092:	26aa9763          	bne	s5,a0,ffffffffc0201300 <slub_test_same_cache+0x572>
ffffffffc0201096:	41010413          	addi	s0,sp,1040
ffffffffc020109a:	60010893          	addi	a7,sp,1536
ffffffffc020109e:	8522                	mv	a0,s0
            assert(slub_test_page(second[i]) == slub_test_page(second[0]));
ffffffffc02010a0:	8752                	mv	a4,s4
    assert(nr_free_pages() == before - 1);
ffffffffc02010a2:	08900593          	li	a1,137
ffffffffc02010a6:	0c900613          	li	a2,201
ffffffffc02010aa:	87ae                	mv	a5,a1
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02010ac:	00074683          	lbu	a3,0(a4)
ffffffffc02010b0:	faf69ce3          	bne	a3,a5,ffffffffc0201068 <slub_test_same_cache+0x2da>
    for (size_t i = 0; i < size; i++) {
ffffffffc02010b4:	27c5                	addiw	a5,a5,17
ffffffffc02010b6:	0ff7f793          	zext.b	a5,a5
ffffffffc02010ba:	0705                	addi	a4,a4,1
ffffffffc02010bc:	fef618e3          	bne	a2,a5,ffffffffc02010ac <slub_test_same_cache+0x31e>
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
ffffffffc02010c0:	2605                	addiw	a2,a2,1
ffffffffc02010c2:	2585                	addiw	a1,a1,1
ffffffffc02010c4:	0ff67613          	zext.b	a2,a2
ffffffffc02010c8:	0ff5f593          	zext.b	a1,a1
ffffffffc02010cc:	00a88563          	beq	a7,a0,ffffffffc02010d6 <slub_test_same_cache+0x348>
        slub_test_read(second[i], SLUB_TEST_OBJECT_SIZE,
ffffffffc02010d0:	6118                	ld	a4,0(a0)
ffffffffc02010d2:	0521                	addi	a0,a0,8
ffffffffc02010d4:	bfd9                	j	ffffffffc02010aa <slub_test_same_cache+0x31c>
ffffffffc02010d6:	5f810493          	addi	s1,sp,1528
ffffffffc02010da:	a021                	j	ffffffffc02010e2 <slub_test_same_cache+0x354>
                       (unsigned char)(i + 137));
    }
    for (size_t i = 0; i + 1 < SLUB_TEST_CAPACITY; i++) {
        slub_free(second[i]);
ffffffffc02010dc:	00043a03          	ld	s4,0(s0)
ffffffffc02010e0:	0421                	addi	s0,s0,8
ffffffffc02010e2:	8552                	mv	a0,s4
ffffffffc02010e4:	98bff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
        assert(nr_free_pages() == before - 1);
ffffffffc02010e8:	d14ff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc02010ec:	22aa9a63          	bne	s5,a0,ffffffffc0201320 <slub_test_same_cache+0x592>
    for (size_t i = 0; i + 1 < SLUB_TEST_CAPACITY; i++) {
ffffffffc02010f0:	fe9416e3          	bne	s0,s1,ffffffffc02010dc <slub_test_same_cache+0x34e>
    }
    slub_free(second[SLUB_TEST_CAPACITY - 1]);
ffffffffc02010f4:	5f813503          	ld	a0,1528(sp)
ffffffffc02010f8:	977ff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    assert(nr_free_pages() == before);
ffffffffc02010fc:	d00ff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201100:	67a2                	ld	a5,8(sp)
ffffffffc0201102:	08f51f63          	bne	a0,a5,ffffffffc02011a0 <slub_test_same_cache+0x412>
}
ffffffffc0201106:	66813083          	ld	ra,1640(sp)
ffffffffc020110a:	66013403          	ld	s0,1632(sp)
ffffffffc020110e:	65813483          	ld	s1,1624(sp)
ffffffffc0201112:	65013903          	ld	s2,1616(sp)
ffffffffc0201116:	64813983          	ld	s3,1608(sp)
ffffffffc020111a:	64013a03          	ld	s4,1600(sp)
ffffffffc020111e:	63813a83          	ld	s5,1592(sp)
ffffffffc0201122:	63013b03          	ld	s6,1584(sp)
ffffffffc0201126:	62813b83          	ld	s7,1576(sp)
ffffffffc020112a:	62013c03          	ld	s8,1568(sp)
ffffffffc020112e:	61813c83          	ld	s9,1560(sp)
ffffffffc0201132:	61013d03          	ld	s10,1552(sp)
ffffffffc0201136:	60813d83          	ld	s11,1544(sp)
ffffffffc020113a:	67010113          	addi	sp,sp,1648
ffffffffc020113e:	8082                	ret
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0201140:	00002697          	auipc	a3,0x2
ffffffffc0201144:	3c868693          	addi	a3,a3,968 # ffffffffc0203508 <etext+0x3f4>
ffffffffc0201148:	00002617          	auipc	a2,0x2
ffffffffc020114c:	40060613          	addi	a2,a2,1024 # ffffffffc0203548 <etext+0x434>
ffffffffc0201150:	0ce00593          	li	a1,206
ffffffffc0201154:	00002517          	auipc	a0,0x2
ffffffffc0201158:	40c50513          	addi	a0,a0,1036 # ffffffffc0203560 <etext+0x44c>
ffffffffc020115c:	87aff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201160:	00002697          	auipc	a3,0x2
ffffffffc0201164:	59068693          	addi	a3,a3,1424 # ffffffffc02036f0 <etext+0x5dc>
ffffffffc0201168:	00002617          	auipc	a2,0x2
ffffffffc020116c:	3e060613          	addi	a2,a2,992 # ffffffffc0203548 <etext+0x434>
ffffffffc0201170:	0be00593          	li	a1,190
ffffffffc0201174:	00002517          	auipc	a0,0x2
ffffffffc0201178:	3ec50513          	addi	a0,a0,1004 # ffffffffc0203560 <etext+0x44c>
ffffffffc020117c:	85aff0ef          	jal	ra,ffffffffc02001d6 <__panic>
            assert(ptr != reused[j]);
ffffffffc0201180:	00002697          	auipc	a3,0x2
ffffffffc0201184:	66868693          	addi	a3,a3,1640 # ffffffffc02037e8 <etext+0x6d4>
ffffffffc0201188:	00002617          	auipc	a2,0x2
ffffffffc020118c:	3c060613          	addi	a2,a2,960 # ffffffffc0203548 <etext+0x434>
ffffffffc0201190:	11400593          	li	a1,276
ffffffffc0201194:	00002517          	auipc	a0,0x2
ffffffffc0201198:	3cc50513          	addi	a0,a0,972 # ffffffffc0203560 <etext+0x44c>
ffffffffc020119c:	83aff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc02011a0:	00002697          	auipc	a3,0x2
ffffffffc02011a4:	5c068693          	addi	a3,a3,1472 # ffffffffc0203760 <etext+0x64c>
ffffffffc02011a8:	00002617          	auipc	a2,0x2
ffffffffc02011ac:	3a060613          	addi	a2,a2,928 # ffffffffc0203548 <etext+0x434>
ffffffffc02011b0:	13b00593          	li	a1,315
ffffffffc02011b4:	00002517          	auipc	a0,0x2
ffffffffc02011b8:	3ac50513          	addi	a0,a0,940 # ffffffffc0203560 <etext+0x44c>
ffffffffc02011bc:	81aff0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc02011c0:	00002697          	auipc	a3,0x2
ffffffffc02011c4:	44068693          	addi	a3,a3,1088 # ffffffffc0203600 <etext+0x4ec>
ffffffffc02011c8:	00002617          	auipc	a2,0x2
ffffffffc02011cc:	38060613          	addi	a2,a2,896 # ffffffffc0203548 <etext+0x434>
ffffffffc02011d0:	06e00593          	li	a1,110
ffffffffc02011d4:	00002517          	auipc	a0,0x2
ffffffffc02011d8:	38c50513          	addi	a0,a0,908 # ffffffffc0203560 <etext+0x44c>
ffffffffc02011dc:	ffbfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nr_free_pages() == before - 1);
ffffffffc02011e0:	00002697          	auipc	a3,0x2
ffffffffc02011e4:	5d868693          	addi	a3,a3,1496 # ffffffffc02037b8 <etext+0x6a4>
ffffffffc02011e8:	00002617          	auipc	a2,0x2
ffffffffc02011ec:	36060613          	addi	a2,a2,864 # ffffffffc0203548 <etext+0x434>
ffffffffc02011f0:	10700593          	li	a1,263
ffffffffc02011f4:	00002517          	auipc	a0,0x2
ffffffffc02011f8:	36c50513          	addi	a0,a0,876 # ffffffffc0203560 <etext+0x44c>
ffffffffc02011fc:	fdbfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0201200:	00002697          	auipc	a3,0x2
ffffffffc0201204:	5b868693          	addi	a3,a3,1464 # ffffffffc02037b8 <etext+0x6a4>
ffffffffc0201208:	00002617          	auipc	a2,0x2
ffffffffc020120c:	34060613          	addi	a2,a2,832 # ffffffffc0203548 <etext+0x434>
ffffffffc0201210:	10200593          	li	a1,258
ffffffffc0201214:	00002517          	auipc	a0,0x2
ffffffffc0201218:	34c50513          	addi	a0,a0,844 # ffffffffc0203560 <etext+0x44c>
ffffffffc020121c:	fbbfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(was_freed);
ffffffffc0201220:	00002697          	auipc	a3,0x2
ffffffffc0201224:	5b868693          	addi	a3,a3,1464 # ffffffffc02037d8 <etext+0x6c4>
ffffffffc0201228:	00002617          	auipc	a2,0x2
ffffffffc020122c:	32060613          	addi	a2,a2,800 # ffffffffc0203548 <etext+0x434>
ffffffffc0201230:	11200593          	li	a1,274
ffffffffc0201234:	00002517          	auipc	a0,0x2
ffffffffc0201238:	32c50513          	addi	a0,a0,812 # ffffffffc0203560 <etext+0x44c>
ffffffffc020123c:	f9bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
ffffffffc0201240:	00002697          	auipc	a3,0x2
ffffffffc0201244:	54068693          	addi	a3,a3,1344 # ffffffffc0203780 <etext+0x66c>
ffffffffc0201248:	00002617          	auipc	a2,0x2
ffffffffc020124c:	30060613          	addi	a2,a2,768 # ffffffffc0203548 <etext+0x434>
ffffffffc0201250:	0fb00593          	li	a1,251
ffffffffc0201254:	00002517          	auipc	a0,0x2
ffffffffc0201258:	30c50513          	addi	a0,a0,780 # ffffffffc0203560 <etext+0x44c>
ffffffffc020125c:	f7bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0201260:	00002697          	auipc	a3,0x2
ffffffffc0201264:	55868693          	addi	a3,a3,1368 # ffffffffc02037b8 <etext+0x6a4>
ffffffffc0201268:	00002617          	auipc	a2,0x2
ffffffffc020126c:	2e060613          	addi	a2,a2,736 # ffffffffc0203548 <etext+0x434>
ffffffffc0201270:	11900593          	li	a1,281
ffffffffc0201274:	00002517          	auipc	a0,0x2
ffffffffc0201278:	2ec50513          	addi	a0,a0,748 # ffffffffc0203560 <etext+0x44c>
ffffffffc020127c:	f5bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(slub_test_page(second[i]) != slub_test_page(first[0]));
ffffffffc0201280:	00002697          	auipc	a3,0x2
ffffffffc0201284:	58068693          	addi	a3,a3,1408 # ffffffffc0203800 <etext+0x6ec>
ffffffffc0201288:	00002617          	auipc	a2,0x2
ffffffffc020128c:	2c060613          	addi	a2,a2,704 # ffffffffc0203548 <etext+0x434>
ffffffffc0201290:	12200593          	li	a1,290
ffffffffc0201294:	00002517          	auipc	a0,0x2
ffffffffc0201298:	2cc50513          	addi	a0,a0,716 # ffffffffc0203560 <etext+0x44c>
ffffffffc020129c:	f3bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
            assert(slub_test_page(second[i]) == slub_test_page(second[0]));
ffffffffc02012a0:	00002697          	auipc	a3,0x2
ffffffffc02012a4:	59868693          	addi	a3,a3,1432 # ffffffffc0203838 <etext+0x724>
ffffffffc02012a8:	00002617          	auipc	a2,0x2
ffffffffc02012ac:	2a060613          	addi	a2,a2,672 # ffffffffc0203548 <etext+0x434>
ffffffffc02012b0:	12400593          	li	a1,292
ffffffffc02012b4:	00002517          	auipc	a0,0x2
ffffffffc02012b8:	2ac50513          	addi	a0,a0,684 # ffffffffc0203560 <etext+0x44c>
ffffffffc02012bc:	f1bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc02012c0:	00002697          	auipc	a3,0x2
ffffffffc02012c4:	5b068693          	addi	a3,a3,1456 # ffffffffc0203870 <etext+0x75c>
ffffffffc02012c8:	00002617          	auipc	a2,0x2
ffffffffc02012cc:	28060613          	addi	a2,a2,640 # ffffffffc0203548 <etext+0x434>
ffffffffc02012d0:	12700593          	li	a1,295
ffffffffc02012d4:	00002517          	auipc	a0,0x2
ffffffffc02012d8:	28c50513          	addi	a0,a0,652 # ffffffffc0203560 <etext+0x44c>
ffffffffc02012dc:	efbfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nr_free_pages() == before - 2);
ffffffffc02012e0:	00002697          	auipc	a3,0x2
ffffffffc02012e4:	59068693          	addi	a3,a3,1424 # ffffffffc0203870 <etext+0x75c>
ffffffffc02012e8:	00002617          	auipc	a2,0x2
ffffffffc02012ec:	26060613          	addi	a2,a2,608 # ffffffffc0203548 <etext+0x434>
ffffffffc02012f0:	12a00593          	li	a1,298
ffffffffc02012f4:	00002517          	auipc	a0,0x2
ffffffffc02012f8:	26c50513          	addi	a0,a0,620 # ffffffffc0203560 <etext+0x44c>
ffffffffc02012fc:	edbfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0201300:	00002697          	auipc	a3,0x2
ffffffffc0201304:	4b868693          	addi	a3,a3,1208 # ffffffffc02037b8 <etext+0x6a4>
ffffffffc0201308:	00002617          	auipc	a2,0x2
ffffffffc020130c:	24060613          	addi	a2,a2,576 # ffffffffc0203548 <etext+0x434>
ffffffffc0201310:	13100593          	li	a1,305
ffffffffc0201314:	00002517          	auipc	a0,0x2
ffffffffc0201318:	24c50513          	addi	a0,a0,588 # ffffffffc0203560 <etext+0x44c>
ffffffffc020131c:	ebbfe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nr_free_pages() == before - 1);
ffffffffc0201320:	00002697          	auipc	a3,0x2
ffffffffc0201324:	49868693          	addi	a3,a3,1176 # ffffffffc02037b8 <etext+0x6a4>
ffffffffc0201328:	00002617          	auipc	a2,0x2
ffffffffc020132c:	22060613          	addi	a2,a2,544 # ffffffffc0203548 <etext+0x434>
ffffffffc0201330:	13800593          	li	a1,312
ffffffffc0201334:	00002517          	auipc	a0,0x2
ffffffffc0201338:	22c50513          	addi	a0,a0,556 # ffffffffc0203560 <etext+0x44c>
ffffffffc020133c:	e9bfe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0201340 <slub_test_mixed>:
    free_pages(page, 1);
    assert(nr_free_pages() == before);
}

static void
slub_test_mixed(void) {
ffffffffc0201340:	b4010113          	addi	sp,sp,-1216
ffffffffc0201344:	4a813823          	sd	s0,1200(sp)
ffffffffc0201348:	4a913423          	sd	s1,1192(sp)
ffffffffc020134c:	4b213023          	sd	s2,1184(sp)
ffffffffc0201350:	49313c23          	sd	s3,1176(sp)
ffffffffc0201354:	49413823          	sd	s4,1168(sp)
ffffffffc0201358:	49513423          	sd	s5,1160(sp)
ffffffffc020135c:	49613023          	sd	s6,1152(sp)
ffffffffc0201360:	47713c23          	sd	s7,1144(sp)
ffffffffc0201364:	47813823          	sd	s8,1136(sp)
ffffffffc0201368:	47913423          	sd	s9,1128(sp)
ffffffffc020136c:	47a13023          	sd	s10,1120(sp)
ffffffffc0201370:	45b13c23          	sd	s11,1112(sp)
ffffffffc0201374:	4a113c23          	sd	ra,1208(sp)

    for (size_t i = 0; i < count; i++) {
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
                   i == SLUB_TEST_CAPACITY + 1 ? 1 :
                   i == SLUB_TEST_CAPACITY + 2 ? 255 :
                   i == SLUB_TEST_CAPACITY + 3 ? slub_sizes[SLUB_CACHE_COUNT - 1] :
ffffffffc0201378:	6a85                	lui	s5,0x1
    size_t before = nr_free_pages();
ffffffffc020137a:	a82ff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc020137e:	1c00                	addi	s0,sp,560
ffffffffc0201380:	e42a                	sd	a0,8(sp)
ffffffffc0201382:	01010d93          	addi	s11,sp,16
ffffffffc0201386:	8ca2                	mv	s9,s0
ffffffffc0201388:	4b85                	li	s7,1
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
ffffffffc020138a:	04000d13          	li	s10,64
ffffffffc020138e:	00017917          	auipc	s2,0x17
ffffffffc0201392:	e6290913          	addi	s2,s2,-414 # ffffffffc02181f0 <slub_ready>
                   slub_sizes[SLUB_CACHE_COUNT - 1] + 1;
        objects[i] = slub_alloc(sizes[i]);
        slub_test_write(objects[i], sizes[i], (unsigned char)(i + 51));
        for (size_t j = 0; j < i; j++) {
ffffffffc0201396:	4485                	li	s1,1
    for (size_t i = 0; i < count; i++) {
ffffffffc0201398:	04400993          	li	s3,68
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
ffffffffc020139c:	03f00a13          	li	s4,63
ffffffffc02013a0:	04000b13          	li	s6,64
                   i == SLUB_TEST_CAPACITY + 2 ? 255 :
ffffffffc02013a4:	04100c13          	li	s8,65
                   i == SLUB_TEST_CAPACITY + 3 ? slub_sizes[SLUB_CACHE_COUNT - 1] :
ffffffffc02013a8:	fc1a8a93          	addi	s5,s5,-63 # fc1 <kern_entry-0xffffffffc01ff03f>
    assert(slub_ready);
ffffffffc02013ac:	00092783          	lw	a5,0(s2)
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
ffffffffc02013b0:	01acb023          	sd	s10,0(s9)
    assert(slub_ready);
ffffffffc02013b4:	1c078963          	beqz	a5,ffffffffc0201586 <slub_test_mixed+0x246>
    if (size == 0) {
ffffffffc02013b8:	856a                	mv	a0,s10
ffffffffc02013ba:	c58ff0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
        objects[i] = slub_alloc(sizes[i]);
ffffffffc02013be:	00adb023          	sd	a0,0(s11)
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02013c2:	1e050263          	beqz	a0,ffffffffc02015a6 <slub_test_mixed+0x266>
ffffffffc02013c6:	00f57793          	andi	a5,a0,15
ffffffffc02013ca:	1c079e63          	bnez	a5,ffffffffc02015a6 <slub_test_mixed+0x266>
ffffffffc02013ce:	032b879b          	addiw	a5,s7,50
ffffffffc02013d2:	0ff7f793          	zext.b	a5,a5
ffffffffc02013d6:	01a50633          	add	a2,a0,s10
ffffffffc02013da:	872a                	mv	a4,a0
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc02013dc:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02013e0:	27c5                	addiw	a5,a5,17
ffffffffc02013e2:	0705                	addi	a4,a4,1
ffffffffc02013e4:	0ff7f793          	zext.b	a5,a5
ffffffffc02013e8:	fec71ae3          	bne	a4,a2,ffffffffc02013dc <slub_test_mixed+0x9c>
        for (size_t j = 0; j < i; j++) {
ffffffffc02013ec:	029b8363          	beq	s7,s1,ffffffffc0201412 <slub_test_mixed+0xd2>
ffffffffc02013f0:	86a2                	mv	a3,s0
ffffffffc02013f2:	081c                	addi	a5,sp,16
    uintptr_t a_start = (uintptr_t)a, b_start = (uintptr_t)b;
ffffffffc02013f4:	6398                	ld	a4,0(a5)
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc02013f6:	00c77663          	bgeu	a4,a2,ffffffffc0201402 <slub_test_mixed+0xc2>
ffffffffc02013fa:	628c                	ld	a1,0(a3)
ffffffffc02013fc:	972e                	add	a4,a4,a1
ffffffffc02013fe:	10e56463          	bltu	a0,a4,ffffffffc0201506 <slub_test_mixed+0x1c6>
        for (size_t j = 0; j < i; j++) {
ffffffffc0201402:	07a1                	addi	a5,a5,8
ffffffffc0201404:	06a1                	addi	a3,a3,8
ffffffffc0201406:	ffb797e3          	bne	a5,s11,ffffffffc02013f4 <slub_test_mixed+0xb4>
    for (size_t i = 0; i < count; i++) {
ffffffffc020140a:	033b8a63          	beq	s7,s3,ffffffffc020143e <slub_test_mixed+0xfe>
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
ffffffffc020140e:	017a6863          	bltu	s4,s7,ffffffffc020141e <slub_test_mixed+0xde>
ffffffffc0201412:	04000d13          	li	s10,64
ffffffffc0201416:	0ca1                	addi	s9,s9,8
ffffffffc0201418:	0b85                	addi	s7,s7,1
ffffffffc020141a:	0da1                	addi	s11,s11,8
ffffffffc020141c:	bf41                	j	ffffffffc02013ac <slub_test_mixed+0x6c>
                   i == SLUB_TEST_CAPACITY + 1 ? 1 :
ffffffffc020141e:	4d05                	li	s10,1
ffffffffc0201420:	ff6b8be3          	beq	s7,s6,ffffffffc0201416 <slub_test_mixed+0xd6>
                   i == SLUB_TEST_CAPACITY + 2 ? 255 :
ffffffffc0201424:	0ff00d13          	li	s10,255
ffffffffc0201428:	ff8b87e3          	beq	s7,s8,ffffffffc0201416 <slub_test_mixed+0xd6>
                   i == SLUB_TEST_CAPACITY + 3 ? slub_sizes[SLUB_CACHE_COUNT - 1] :
ffffffffc020142c:	6705                	lui	a4,0x1
ffffffffc020142e:	04200793          	li	a5,66
ffffffffc0201432:	fc070d13          	addi	s10,a4,-64 # fc0 <kern_entry-0xffffffffc01ff040>
ffffffffc0201436:	fefb80e3          	beq	s7,a5,ffffffffc0201416 <slub_test_mixed+0xd6>
ffffffffc020143a:	8d56                	mv	s10,s5
ffffffffc020143c:	bfe9                	j	ffffffffc0201416 <slub_test_mixed+0xd6>
            slub_test_disjoint(objects[i], sizes[i], objects[j], sizes[j]);
        }
    }
    assert(slub_test_page(objects[0]) !=
ffffffffc020143e:	64c2                	ld	s1,16(sp)
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0201440:	20813783          	ld	a5,520(sp)
ffffffffc0201444:	777d                	lui	a4,0xfffff
ffffffffc0201446:	00e4f6b3          	and	a3,s1,a4
ffffffffc020144a:	8ff9                	and	a5,a5,a4
ffffffffc020144c:	01810913          	addi	s2,sp,24
ffffffffc0201450:	23810993          	addi	s3,sp,568
    assert(slub_test_page(objects[0]) !=
ffffffffc0201454:	10d78963          	beq	a5,a3,ffffffffc0201566 <slub_test_mixed+0x226>
           slub_test_page(objects[SLUB_TEST_CAPACITY]));
    for (size_t i = 1; i < count; i += 2) {
        slub_free(objects[i]);
ffffffffc0201458:	00093503          	ld	a0,0(s2)
    for (size_t i = 1; i < count; i += 2) {
ffffffffc020145c:	0941                	addi	s2,s2,16
        slub_free(objects[i]);
ffffffffc020145e:	e10ff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    for (size_t i = 1; i < count; i += 2) {
ffffffffc0201462:	ff391be3          	bne	s2,s3,ffffffffc0201458 <slub_test_mixed+0x118>
ffffffffc0201466:	1008                	addi	a0,sp,32
ffffffffc0201468:	22040813          	addi	a6,s0,544
ffffffffc020146c:	03300593          	li	a1,51
    }
    for (size_t i = 0; i < count; i += 2) {
        slub_test_read(objects[i], sizes[i], (unsigned char)(i + 51));
ffffffffc0201470:	6010                	ld	a2,0(s0)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201472:	ce11                	beqz	a2,ffffffffc020148e <slub_test_mixed+0x14e>
ffffffffc0201474:	8726                	mv	a4,s1
ffffffffc0201476:	9626                	add	a2,a2,s1
ffffffffc0201478:	87ae                	mv	a5,a1
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc020147a:	00074683          	lbu	a3,0(a4) # fffffffffffff000 <end+0x3fde6e00>
ffffffffc020147e:	0af69463          	bne	a3,a5,ffffffffc0201526 <slub_test_mixed+0x1e6>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201482:	27c5                	addiw	a5,a5,17
ffffffffc0201484:	0705                	addi	a4,a4,1
ffffffffc0201486:	0ff7f793          	zext.b	a5,a5
ffffffffc020148a:	fec718e3          	bne	a4,a2,ffffffffc020147a <slub_test_mixed+0x13a>
    for (size_t i = 0; i < count; i += 2) {
ffffffffc020148e:	2589                	addiw	a1,a1,2
ffffffffc0201490:	0441                	addi	s0,s0,16
ffffffffc0201492:	0ff5f593          	zext.b	a1,a1
ffffffffc0201496:	00880563          	beq	a6,s0,ffffffffc02014a0 <slub_test_mixed+0x160>
        slub_test_read(objects[i], sizes[i], (unsigned char)(i + 51));
ffffffffc020149a:	6104                	ld	s1,0(a0)
ffffffffc020149c:	0541                	addi	a0,a0,16
ffffffffc020149e:	bfc9                	j	ffffffffc0201470 <slub_test_mixed+0x130>
ffffffffc02014a0:	1400                	addi	s0,sp,544
ffffffffc02014a2:	00810913          	addi	s2,sp,8
    for (size_t i = 0; i < count; i += 2) {
ffffffffc02014a6:	04200493          	li	s1,66
    }
    for (size_t i = count; i > 0; i--) {
ffffffffc02014aa:	00890c63          	beq	s2,s0,ffffffffc02014c2 <slub_test_mixed+0x182>
        if ((i - 1) % 2 == 0) {
ffffffffc02014ae:	0014f793          	andi	a5,s1,1
ffffffffc02014b2:	e781                	bnez	a5,ffffffffc02014ba <slub_test_mixed+0x17a>
            slub_free(objects[i - 1]);
ffffffffc02014b4:	6008                	ld	a0,0(s0)
ffffffffc02014b6:	db8ff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
ffffffffc02014ba:	1461                	addi	s0,s0,-8
ffffffffc02014bc:	14fd                	addi	s1,s1,-1
    for (size_t i = count; i > 0; i--) {
ffffffffc02014be:	fe8918e3          	bne	s2,s0,ffffffffc02014ae <slub_test_mixed+0x16e>
        }
    }
    assert(nr_free_pages() == before);
ffffffffc02014c2:	93aff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc02014c6:	67a2                	ld	a5,8(sp)
ffffffffc02014c8:	06f51f63          	bne	a0,a5,ffffffffc0201546 <slub_test_mixed+0x206>
}
ffffffffc02014cc:	4b813083          	ld	ra,1208(sp)
ffffffffc02014d0:	4b013403          	ld	s0,1200(sp)
ffffffffc02014d4:	4a813483          	ld	s1,1192(sp)
ffffffffc02014d8:	4a013903          	ld	s2,1184(sp)
ffffffffc02014dc:	49813983          	ld	s3,1176(sp)
ffffffffc02014e0:	49013a03          	ld	s4,1168(sp)
ffffffffc02014e4:	48813a83          	ld	s5,1160(sp)
ffffffffc02014e8:	48013b03          	ld	s6,1152(sp)
ffffffffc02014ec:	47813b83          	ld	s7,1144(sp)
ffffffffc02014f0:	47013c03          	ld	s8,1136(sp)
ffffffffc02014f4:	46813c83          	ld	s9,1128(sp)
ffffffffc02014f8:	46013d03          	ld	s10,1120(sp)
ffffffffc02014fc:	45813d83          	ld	s11,1112(sp)
ffffffffc0201500:	4c010113          	addi	sp,sp,1216
ffffffffc0201504:	8082                	ret
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0201506:	00002697          	auipc	a3,0x2
ffffffffc020150a:	00268693          	addi	a3,a3,2 # ffffffffc0203508 <etext+0x3f4>
ffffffffc020150e:	00002617          	auipc	a2,0x2
ffffffffc0201512:	03a60613          	addi	a2,a2,58 # ffffffffc0203548 <etext+0x434>
ffffffffc0201516:	0ce00593          	li	a1,206
ffffffffc020151a:	00002517          	auipc	a0,0x2
ffffffffc020151e:	04650513          	addi	a0,a0,70 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201522:	cb5fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201526:	00002697          	auipc	a3,0x2
ffffffffc020152a:	1fa68693          	addi	a3,a3,506 # ffffffffc0203720 <etext+0x60c>
ffffffffc020152e:	00002617          	auipc	a2,0x2
ffffffffc0201532:	01a60613          	addi	a2,a2,26 # ffffffffc0203548 <etext+0x434>
ffffffffc0201536:	0c700593          	li	a1,199
ffffffffc020153a:	00002517          	auipc	a0,0x2
ffffffffc020153e:	02650513          	addi	a0,a0,38 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201542:	c95fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0201546:	00002697          	auipc	a3,0x2
ffffffffc020154a:	21a68693          	addi	a3,a3,538 # ffffffffc0203760 <etext+0x64c>
ffffffffc020154e:	00002617          	auipc	a2,0x2
ffffffffc0201552:	ffa60613          	addi	a2,a2,-6 # ffffffffc0203548 <etext+0x434>
ffffffffc0201556:	1b000593          	li	a1,432
ffffffffc020155a:	00002517          	auipc	a0,0x2
ffffffffc020155e:	00650513          	addi	a0,a0,6 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201562:	c75fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_test_page(objects[0]) !=
ffffffffc0201566:	00002697          	auipc	a3,0x2
ffffffffc020156a:	32a68693          	addi	a3,a3,810 # ffffffffc0203890 <etext+0x77c>
ffffffffc020156e:	00002617          	auipc	a2,0x2
ffffffffc0201572:	fda60613          	addi	a2,a2,-38 # ffffffffc0203548 <etext+0x434>
ffffffffc0201576:	1a300593          	li	a1,419
ffffffffc020157a:	00002517          	auipc	a0,0x2
ffffffffc020157e:	fe650513          	addi	a0,a0,-26 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201582:	c55fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0201586:	00002697          	auipc	a3,0x2
ffffffffc020158a:	07a68693          	addi	a3,a3,122 # ffffffffc0203600 <etext+0x4ec>
ffffffffc020158e:	00002617          	auipc	a2,0x2
ffffffffc0201592:	fba60613          	addi	a2,a2,-70 # ffffffffc0203548 <etext+0x434>
ffffffffc0201596:	06e00593          	li	a1,110
ffffffffc020159a:	00002517          	auipc	a0,0x2
ffffffffc020159e:	fc650513          	addi	a0,a0,-58 # ffffffffc0203560 <etext+0x44c>
ffffffffc02015a2:	c35fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02015a6:	00002697          	auipc	a3,0x2
ffffffffc02015aa:	14a68693          	addi	a3,a3,330 # ffffffffc02036f0 <etext+0x5dc>
ffffffffc02015ae:	00002617          	auipc	a2,0x2
ffffffffc02015b2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0203548 <etext+0x434>
ffffffffc02015b6:	0be00593          	li	a1,190
ffffffffc02015ba:	00002517          	auipc	a0,0x2
ffffffffc02015be:	fa650513          	addi	a0,a0,-90 # ffffffffc0203560 <etext+0x44c>
ffffffffc02015c2:	c15fe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02015c6 <slub_check>:

void
slub_check(void) {
ffffffffc02015c6:	7175                	addi	sp,sp,-144
ffffffffc02015c8:	fca6                	sd	s1,120(sp)
    assert(slub_ready);
ffffffffc02015ca:	00017497          	auipc	s1,0x17
ffffffffc02015ce:	c2648493          	addi	s1,s1,-986 # ffffffffc02181f0 <slub_ready>
ffffffffc02015d2:	409c                	lw	a5,0(s1)
slub_check(void) {
ffffffffc02015d4:	e506                	sd	ra,136(sp)
ffffffffc02015d6:	e122                	sd	s0,128(sp)
ffffffffc02015d8:	f8ca                	sd	s2,112(sp)
ffffffffc02015da:	f4ce                	sd	s3,104(sp)
ffffffffc02015dc:	f0d2                	sd	s4,96(sp)
ffffffffc02015de:	ecd6                	sd	s5,88(sp)
ffffffffc02015e0:	e8da                	sd	s6,80(sp)
ffffffffc02015e2:	e4de                	sd	s7,72(sp)
ffffffffc02015e4:	e0e2                	sd	s8,64(sp)
ffffffffc02015e6:	fc66                	sd	s9,56(sp)
ffffffffc02015e8:	f86a                	sd	s10,48(sp)
ffffffffc02015ea:	f46e                	sd	s11,40(sp)
    assert(slub_ready);
ffffffffc02015ec:	76078d63          	beqz	a5,ffffffffc0201d66 <slub_check+0x7a0>
    size_t free_before = nr_free_pages();
ffffffffc02015f0:	80cff0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc02015f4:	8aaa                	mv	s5,a0
    cprintf("slub test: size classes, alignment and object isolation\n");
ffffffffc02015f6:	00002517          	auipc	a0,0x2
ffffffffc02015fa:	2ea50513          	addi	a0,a0,746 # ffffffffc02038e0 <etext+0x7cc>
    size_t free_before = nr_free_pages();
ffffffffc02015fe:	e456                	sd	s5,8(sp)
    cprintf("slub test: size classes, alignment and object isolation\n");
ffffffffc0201600:	b61fe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    slub_test_sizes();
ffffffffc0201604:	d92ff0ef          	jal	ra,ffffffffc0200b96 <slub_test_sizes>
    cprintf("slub test: freelist, slab extension and independent page reclaim\n");
ffffffffc0201608:	00002517          	auipc	a0,0x2
ffffffffc020160c:	31850513          	addi	a0,a0,792 # ffffffffc0203920 <etext+0x80c>
ffffffffc0201610:	b51fe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    slub_test_same_cache();
ffffffffc0201614:	f7aff0ef          	jal	ra,ffffffffc0200d8e <slub_test_same_cache>
    cprintf("slub test: cache isolation and pointer-based release\n");
ffffffffc0201618:	00002517          	auipc	a0,0x2
ffffffffc020161c:	35050513          	addi	a0,a0,848 # ffffffffc0203968 <etext+0x854>
ffffffffc0201620:	b41fe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0201624:	fd9fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
    assert(slub_ready);
ffffffffc0201628:	409c                	lw	a5,0(s1)
    size_t before = nr_free_pages();
ffffffffc020162a:	8a2a                	mv	s4,a0
    assert(slub_ready);
ffffffffc020162c:	4c078d63          	beqz	a5,ffffffffc0201b06 <slub_check+0x540>
    if (size == 0) {
ffffffffc0201630:	02000513          	li	a0,32
ffffffffc0201634:	9deff0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
    assert(slub_ready);
ffffffffc0201638:	409c                	lw	a5,0(s1)
ffffffffc020163a:	89aa                	mv	s3,a0
ffffffffc020163c:	4c078563          	beqz	a5,ffffffffc0201b06 <slub_check+0x540>
    if (size == 0) {
ffffffffc0201640:	02000513          	li	a0,32
ffffffffc0201644:	9ceff0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
    assert(slub_ready);
ffffffffc0201648:	409c                	lw	a5,0(s1)
ffffffffc020164a:	8daa                	mv	s11,a0
ffffffffc020164c:	4a078d63          	beqz	a5,ffffffffc0201b06 <slub_check+0x540>
    if (size == 0) {
ffffffffc0201650:	10000513          	li	a0,256
ffffffffc0201654:	9beff0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
    assert(slub_ready);
ffffffffc0201658:	409c                	lw	a5,0(s1)
ffffffffc020165a:	842a                	mv	s0,a0
ffffffffc020165c:	4a078563          	beqz	a5,ffffffffc0201b06 <slub_check+0x540>
    if (size == 0) {
ffffffffc0201660:	10000513          	li	a0,256
ffffffffc0201664:	9aeff0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
ffffffffc0201668:	892a                	mv	s2,a0
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc020166a:	46098e63          	beqz	s3,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc020166e:	00f9f793          	andi	a5,s3,15
ffffffffc0201672:	8cce                	mv	s9,s3
ffffffffc0201674:	46079963          	bnez	a5,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc0201678:	874e                	mv	a4,s3
ffffffffc020167a:	47ad                	li	a5,11
    for (size_t i = 0; i < size; i++) {
ffffffffc020167c:	02b00613          	li	a2,43
ffffffffc0201680:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0201684:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201688:	0ff6f793          	zext.b	a5,a3
ffffffffc020168c:	0705                	addi	a4,a4,1
ffffffffc020168e:	fec799e3          	bne	a5,a2,ffffffffc0201680 <slub_check+0xba>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201692:	440d8a63          	beqz	s11,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc0201696:	00fdf793          	andi	a5,s11,15
ffffffffc020169a:	44079663          	bnez	a5,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc020169e:	876e                	mv	a4,s11
ffffffffc02016a0:	47b1                	li	a5,12
    for (size_t i = 0; i < size; i++) {
ffffffffc02016a2:	02c00613          	li	a2,44
ffffffffc02016a6:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc02016aa:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02016ae:	0ff6f793          	zext.b	a5,a3
ffffffffc02016b2:	0705                	addi	a4,a4,1
ffffffffc02016b4:	fec799e3          	bne	a5,a2,ffffffffc02016a6 <slub_check+0xe0>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02016b8:	42040763          	beqz	s0,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc02016bc:	00f47793          	andi	a5,s0,15
ffffffffc02016c0:	8ba2                	mv	s7,s0
ffffffffc02016c2:	42079263          	bnez	a5,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc02016c6:	10040d13          	addi	s10,s0,256
ffffffffc02016ca:	8722                	mv	a4,s0
ffffffffc02016cc:	47b5                	li	a5,13
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc02016ce:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02016d2:	27c5                	addiw	a5,a5,17
ffffffffc02016d4:	0705                	addi	a4,a4,1
ffffffffc02016d6:	0ff7f793          	zext.b	a5,a5
ffffffffc02016da:	ffa71ae3          	bne	a4,s10,ffffffffc02016ce <slub_check+0x108>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02016de:	40090463          	beqz	s2,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc02016e2:	00f97793          	andi	a5,s2,15
ffffffffc02016e6:	8c4a                	mv	s8,s2
ffffffffc02016e8:	3e079f63          	bnez	a5,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc02016ec:	10090a93          	addi	s5,s2,256
ffffffffc02016f0:	874a                	mv	a4,s2
ffffffffc02016f2:	47b9                	li	a5,14
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc02016f4:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02016f8:	27c5                	addiw	a5,a5,17
ffffffffc02016fa:	0705                	addi	a4,a4,1
ffffffffc02016fc:	0ff7f793          	zext.b	a5,a5
ffffffffc0201700:	feea9ae3          	bne	s5,a4,ffffffffc02016f4 <slub_check+0x12e>
    assert(nr_free_pages() == before - 2);
ffffffffc0201704:	ef9fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201708:	ffea0b13          	addi	s6,s4,-2
ffffffffc020170c:	61651d63          	bne	a0,s6,ffffffffc0201d26 <slub_check+0x760>
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0201710:	02098793          	addi	a5,s3,32
ffffffffc0201714:	00fdf663          	bgeu	s11,a5,ffffffffc0201720 <slub_check+0x15a>
ffffffffc0201718:	020d8793          	addi	a5,s11,32
ffffffffc020171c:	3af9e363          	bltu	s3,a5,ffffffffc0201ac2 <slub_check+0x4fc>
ffffffffc0201720:	01a97463          	bgeu	s2,s10,ffffffffc0201728 <slub_check+0x162>
ffffffffc0201724:	39546f63          	bltu	s0,s5,ffffffffc0201ac2 <slub_check+0x4fc>
ffffffffc0201728:	020d8793          	addi	a5,s11,32
ffffffffc020172c:	38f46963          	bltu	s0,a5,ffffffffc0201abe <slub_check+0x4f8>
    slub_free(small1); /* Recover a nonfirst object's slab and cache. */
ffffffffc0201730:	856e                	mv	a0,s11
ffffffffc0201732:	b3cff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    assert(nr_free_pages() == before - 2);
ffffffffc0201736:	ec7fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc020173a:	3eab1663          	bne	s6,a0,ffffffffc0201b26 <slub_check+0x560>
    assert(slub_ready);
ffffffffc020173e:	409c                	lw	a5,0(s1)
ffffffffc0201740:	3c078363          	beqz	a5,ffffffffc0201b06 <slub_check+0x540>
    if (size == 0) {
ffffffffc0201744:	02000513          	li	a0,32
ffffffffc0201748:	8caff0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
ffffffffc020174c:	85aa                	mv	a1,a0
    assert(again == small1);
ffffffffc020174e:	44ad9c63          	bne	s11,a0,ffffffffc0201ba6 <slub_check+0x5e0>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201752:	00f57793          	andi	a5,a0,15
ffffffffc0201756:	872a                	mv	a4,a0
ffffffffc0201758:	38079763          	bnez	a5,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc020175c:	47bd                	li	a5,15
    for (size_t i = 0; i < size; i++) {
ffffffffc020175e:	02f00513          	li	a0,47
ffffffffc0201762:	0117861b          	addiw	a2,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0201766:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc020176a:	0ff67793          	zext.b	a5,a2
ffffffffc020176e:	0705                	addi	a4,a4,1
ffffffffc0201770:	fea799e3          	bne	a5,a0,ffffffffc0201762 <slub_check+0x19c>
ffffffffc0201774:	47ad                	li	a5,11
    for (size_t i = 0; i < size; i++) {
ffffffffc0201776:	02b00613          	li	a2,43
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc020177a:	000cc703          	lbu	a4,0(s9)
ffffffffc020177e:	34f71463          	bne	a4,a5,ffffffffc0201ac6 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201782:	27c5                	addiw	a5,a5,17
ffffffffc0201784:	0ff7f793          	zext.b	a5,a5
ffffffffc0201788:	0c85                	addi	s9,s9,1
ffffffffc020178a:	fec798e3          	bne	a5,a2,ffffffffc020177a <slub_check+0x1b4>
ffffffffc020178e:	8722                	mv	a4,s0
ffffffffc0201790:	47b5                	li	a5,13
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201792:	00074603          	lbu	a2,0(a4)
ffffffffc0201796:	32f61863          	bne	a2,a5,ffffffffc0201ac6 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc020179a:	27c5                	addiw	a5,a5,17
ffffffffc020179c:	0705                	addi	a4,a4,1
ffffffffc020179e:	0ff7f793          	zext.b	a5,a5
ffffffffc02017a2:	ffa718e3          	bne	a4,s10,ffffffffc0201792 <slub_check+0x1cc>
ffffffffc02017a6:	874a                	mv	a4,s2
ffffffffc02017a8:	47b9                	li	a5,14
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02017aa:	00074603          	lbu	a2,0(a4)
ffffffffc02017ae:	30f61c63          	bne	a2,a5,ffffffffc0201ac6 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc02017b2:	27c5                	addiw	a5,a5,17
ffffffffc02017b4:	0705                	addi	a4,a4,1
ffffffffc02017b6:	0ff7f793          	zext.b	a5,a5
ffffffffc02017ba:	feea98e3          	bne	s5,a4,ffffffffc02017aa <slub_check+0x1e4>
    slub_free(small0);
ffffffffc02017be:	854e                	mv	a0,s3
ffffffffc02017c0:	e02e                	sd	a1,0(sp)
ffffffffc02017c2:	aacff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    assert(nr_free_pages() == before - 2);
ffffffffc02017c6:	e37fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc02017ca:	6582                	ld	a1,0(sp)
ffffffffc02017cc:	56ab1d63          	bne	s6,a0,ffffffffc0201d46 <slub_check+0x780>
    slub_free(again);
ffffffffc02017d0:	852e                	mv	a0,a1
ffffffffc02017d2:	a9cff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    assert(nr_free_pages() == before - 1);
ffffffffc02017d6:	e27fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc02017da:	fffa0993          	addi	s3,s4,-1
ffffffffc02017de:	47b5                	li	a5,13
ffffffffc02017e0:	4b351363          	bne	a0,s3,ffffffffc0201c86 <slub_check+0x6c0>
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02017e4:	000bc703          	lbu	a4,0(s7) # fffffffffffff000 <end+0x3fde6e00>
ffffffffc02017e8:	2cf71f63          	bne	a4,a5,ffffffffc0201ac6 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc02017ec:	27c5                	addiw	a5,a5,17
ffffffffc02017ee:	0b85                	addi	s7,s7,1
ffffffffc02017f0:	0ff7f793          	zext.b	a5,a5
ffffffffc02017f4:	ffab98e3          	bne	s7,s10,ffffffffc02017e4 <slub_check+0x21e>
ffffffffc02017f8:	47b9                	li	a5,14
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02017fa:	000c4703          	lbu	a4,0(s8)
ffffffffc02017fe:	2cf71463          	bne	a4,a5,ffffffffc0201ac6 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201802:	27c5                	addiw	a5,a5,17
ffffffffc0201804:	0c05                	addi	s8,s8,1
ffffffffc0201806:	0ff7f793          	zext.b	a5,a5
ffffffffc020180a:	ff8a98e3          	bne	s5,s8,ffffffffc02017fa <slub_check+0x234>
    slub_free(medium0);
ffffffffc020180e:	8522                	mv	a0,s0
ffffffffc0201810:	a5eff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    assert(nr_free_pages() == before - 1);
ffffffffc0201814:	de9fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201818:	36a99763          	bne	s3,a0,ffffffffc0201b86 <slub_check+0x5c0>
    slub_free(medium1);
ffffffffc020181c:	854a                	mv	a0,s2
ffffffffc020181e:	a50ff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    assert(nr_free_pages() == before);
ffffffffc0201822:	ddbfe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201826:	34aa1063          	bne	s4,a0,ffffffffc0201b66 <slub_check+0x5a0>
    slub_test_cache_isolation();
    cprintf("slub test: large contiguous allocations and PMM restoration\n");
ffffffffc020182a:	00002517          	auipc	a0,0x2
ffffffffc020182e:	18650513          	addi	a0,a0,390 # ffffffffc02039b0 <etext+0x89c>
ffffffffc0201832:	92ffe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0201836:	dc7fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
    assert(slub_ready);
ffffffffc020183a:	409c                	lw	a5,0(s1)
    size_t before = nr_free_pages();
ffffffffc020183c:	8a2a                	mv	s4,a0
    assert(slub_ready);
ffffffffc020183e:	2c078463          	beqz	a5,ffffffffc0201b06 <slub_check+0x540>
    if (size == 0) {
ffffffffc0201842:	4541                	li	a0,16
ffffffffc0201844:	fcffe0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
ffffffffc0201848:	842a                	mv	s0,a0
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc020184a:	28050e63          	beqz	a0,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc020184e:	00f57793          	andi	a5,a0,15
ffffffffc0201852:	28079a63          	bnez	a5,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc0201856:	872a                	mv	a4,a0
ffffffffc0201858:	47d5                	li	a5,21
    for (size_t i = 0; i < size; i++) {
ffffffffc020185a:	02500613          	li	a2,37
ffffffffc020185e:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0201862:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201866:	0ff6f793          	zext.b	a5,a3
ffffffffc020186a:	0705                	addi	a4,a4,1
ffffffffc020186c:	fec799e3          	bne	a5,a2,ffffffffc020185e <slub_check+0x298>
    size_t with_small = nr_free_pages();
ffffffffc0201870:	d8dfe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
    assert(with_small == before - 1);
ffffffffc0201874:	fffa0793          	addi	a5,s4,-1
ffffffffc0201878:	2cf51763          	bne	a0,a5,ffffffffc0201b46 <slub_check+0x580>
    const size_t sizes[] = { limit + 1, 2 * PGSIZE + 17 };
ffffffffc020187c:	6785                	lui	a5,0x1
ffffffffc020187e:	fc178793          	addi	a5,a5,-63 # fc1 <kern_entry-0xffffffffc01ff03f>
ffffffffc0201882:	e83e                	sd	a5,16(sp)
ffffffffc0201884:	6789                	lui	a5,0x2
ffffffffc0201886:	07c5                	addi	a5,a5,17
ffffffffc0201888:	ec3e                	sd	a5,24(sp)
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc020188a:	01010993          	addi	s3,sp,16
    const size_t sizes[] = { limit + 1, 2 * PGSIZE + 17 };
ffffffffc020188e:	497d                	li	s2,31
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0201890:	01040b13          	addi	s6,s0,16
    for (size_t i = 0; i < size; i++) {
ffffffffc0201894:	02500d13          	li	s10,37
ffffffffc0201898:	02000b93          	li	s7,32
        size_t free_before_large = nr_free_pages();
ffffffffc020189c:	d61fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
    assert(slub_ready);
ffffffffc02018a0:	409c                	lw	a5,0(s1)
        void *large = slub_alloc(sizes[i]);
ffffffffc02018a2:	0009bd83          	ld	s11,0(s3)
        size_t free_before_large = nr_free_pages();
ffffffffc02018a6:	8c2a                	mv	s8,a0
    assert(slub_ready);
ffffffffc02018a8:	24078f63          	beqz	a5,ffffffffc0201b06 <slub_check+0x540>
    if (size == 0) {
ffffffffc02018ac:	220d8d63          	beqz	s11,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc02018b0:	856e                	mv	a0,s11
ffffffffc02018b2:	f61fe0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
ffffffffc02018b6:	8aaa                	mv	s5,a0
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02018b8:	22050763          	beqz	a0,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc02018bc:	00f57793          	andi	a5,a0,15
ffffffffc02018c0:	8caa                	mv	s9,a0
ffffffffc02018c2:	22079263          	bnez	a5,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc02018c6:	9daa                	add	s11,s11,a0
ffffffffc02018c8:	872a                	mv	a4,a0
ffffffffc02018ca:	87ca                	mv	a5,s2
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc02018cc:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02018d0:	27c5                	addiw	a5,a5,17
ffffffffc02018d2:	0705                	addi	a4,a4,1
ffffffffc02018d4:	0ff7f793          	zext.b	a5,a5
ffffffffc02018d8:	feed9ae3          	bne	s11,a4,ffffffffc02018cc <slub_check+0x306>
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc02018dc:	016af463          	bgeu	s5,s6,ffffffffc02018e4 <slub_check+0x31e>
ffffffffc02018e0:	1fb46163          	bltu	s0,s11,ffffffffc0201ac2 <slub_check+0x4fc>
        assert(nr_free_pages() < free_before_large);
ffffffffc02018e4:	d19fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc02018e8:	35857f63          	bgeu	a0,s8,ffffffffc0201c46 <slub_check+0x680>
ffffffffc02018ec:	87ca                	mv	a5,s2
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc02018ee:	000cc703          	lbu	a4,0(s9)
ffffffffc02018f2:	1cf71a63          	bne	a4,a5,ffffffffc0201ac6 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc02018f6:	27c5                	addiw	a5,a5,17
ffffffffc02018f8:	0c85                	addi	s9,s9,1
ffffffffc02018fa:	0ff7f793          	zext.b	a5,a5
ffffffffc02018fe:	ff9d98e3          	bne	s11,s9,ffffffffc02018ee <slub_check+0x328>
ffffffffc0201902:	8722                	mv	a4,s0
ffffffffc0201904:	47d5                	li	a5,21
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201906:	00074683          	lbu	a3,0(a4)
ffffffffc020190a:	1af69e63          	bne	a3,a5,ffffffffc0201ac6 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc020190e:	27c5                	addiw	a5,a5,17
ffffffffc0201910:	0ff7f793          	zext.b	a5,a5
ffffffffc0201914:	0705                	addi	a4,a4,1
ffffffffc0201916:	ffa798e3          	bne	a5,s10,ffffffffc0201906 <slub_check+0x340>
        slub_free(large);
ffffffffc020191a:	8556                	mv	a0,s5
ffffffffc020191c:	952ff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
        assert(nr_free_pages() == free_before_large);
ffffffffc0201920:	cddfe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201924:	2aac1163          	bne	s8,a0,ffffffffc0201bc6 <slub_check+0x600>
ffffffffc0201928:	8722                	mv	a4,s0
ffffffffc020192a:	47d5                	li	a5,21
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc020192c:	00074683          	lbu	a3,0(a4)
ffffffffc0201930:	18f69b63          	bne	a3,a5,ffffffffc0201ac6 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201934:	27c5                	addiw	a5,a5,17
ffffffffc0201936:	0ff7f793          	zext.b	a5,a5
ffffffffc020193a:	0705                	addi	a4,a4,1
ffffffffc020193c:	ffa798e3          	bne	a5,s10,ffffffffc020192c <slub_check+0x366>
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc0201940:	09a1                	addi	s3,s3,8
ffffffffc0201942:	17791b63          	bne	s2,s7,ffffffffc0201ab8 <slub_check+0x4f2>
    slub_free(small);
ffffffffc0201946:	8522                	mv	a0,s0
ffffffffc0201948:	926ff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    assert(nr_free_pages() == before);
ffffffffc020194c:	cb1fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201950:	2aaa1b63          	bne	s4,a0,ffffffffc0201c06 <slub_check+0x640>
    slub_test_large();
    cprintf("slub test: coexistence with direct PMM allocation\n");
ffffffffc0201954:	00002517          	auipc	a0,0x2
ffffffffc0201958:	10c50513          	addi	a0,a0,268 # ffffffffc0203a60 <etext+0x94c>
ffffffffc020195c:	805fe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0201960:	c9dfe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
    assert(slub_ready);
ffffffffc0201964:	409c                	lw	a5,0(s1)
    size_t before = nr_free_pages();
ffffffffc0201966:	84aa                	mv	s1,a0
    assert(slub_ready);
ffffffffc0201968:	18078f63          	beqz	a5,ffffffffc0201b06 <slub_check+0x540>
    if (size == 0) {
ffffffffc020196c:	04000513          	li	a0,64
ffffffffc0201970:	ea3fe0ef          	jal	ra,ffffffffc0200812 <slub_alloc.part.0>
ffffffffc0201974:	8b2a                	mv	s6,a0
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201976:	16050863          	beqz	a0,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc020197a:	00f57793          	andi	a5,a0,15
ffffffffc020197e:	89aa                	mv	s3,a0
ffffffffc0201980:	16079363          	bnez	a5,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc0201984:	872a                	mv	a4,a0
ffffffffc0201986:	04900793          	li	a5,73
    for (size_t i = 0; i < size; i++) {
ffffffffc020198a:	08900613          	li	a2,137
ffffffffc020198e:	0117869b          	addiw	a3,a5,17
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0201992:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201996:	0ff6f793          	zext.b	a5,a3
ffffffffc020199a:	0705                	addi	a4,a4,1
ffffffffc020199c:	fec799e3          	bne	a5,a2,ffffffffc020198e <slub_check+0x3c8>
    assert(nr_free_pages() == before - 1);
ffffffffc02019a0:	c5dfe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc02019a4:	fff48913          	addi	s2,s1,-1
ffffffffc02019a8:	23251f63          	bne	a0,s2,ffffffffc0201be6 <slub_check+0x620>
    struct Page *page = alloc_pages(1);
ffffffffc02019ac:	4505                	li	a0,1
ffffffffc02019ae:	c37fe0ef          	jal	ra,ffffffffc02005e4 <alloc_pages>
ffffffffc02019b2:	8baa                	mv	s7,a0
    assert(page != NULL);
ffffffffc02019b4:	2a050963          	beqz	a0,ffffffffc0201c66 <slub_check+0x6a0>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02019b8:	00017417          	auipc	s0,0x17
ffffffffc02019bc:	81043403          	ld	s0,-2032(s0) # ffffffffc02181c8 <pages>
ffffffffc02019c0:	40850433          	sub	s0,a0,s0
ffffffffc02019c4:	00003797          	auipc	a5,0x3
ffffffffc02019c8:	cc47b783          	ld	a5,-828(a5) # ffffffffc0204688 <nbase+0x8>
ffffffffc02019cc:	840d                	srai	s0,s0,0x3
ffffffffc02019ce:	02f40433          	mul	s0,s0,a5
ffffffffc02019d2:	00003717          	auipc	a4,0x3
ffffffffc02019d6:	cae73703          	ld	a4,-850(a4) # ffffffffc0204680 <nbase>
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc02019da:	77fd                	lui	a5,0xfffff
ffffffffc02019dc:	00fb77b3          	and	a5,s6,a5
ffffffffc02019e0:	943a                	add	s0,s0,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc02019e2:	0432                	slli	s0,s0,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc02019e4:	00017717          	auipc	a4,0x17
ffffffffc02019e8:	80473703          	ld	a4,-2044(a4) # ffffffffc02181e8 <va_pa_offset>
ffffffffc02019ec:	943a                	add	s0,s0,a4
    assert(slub_test_page(object) != (uintptr_t)page_data);
ffffffffc02019ee:	2cf40c63          	beq	s0,a5,ffffffffc0201cc6 <slub_check+0x700>
    assert(nr_free_pages() == before - 2);
ffffffffc02019f2:	c0bfe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc02019f6:	ffe48793          	addi	a5,s1,-2
ffffffffc02019fa:	2af51663          	bne	a0,a5,ffffffffc0201ca6 <slub_check+0x6e0>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc02019fe:	0e040463          	beqz	s0,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc0201a02:	00f47793          	andi	a5,s0,15
ffffffffc0201a06:	0e079063          	bnez	a5,ffffffffc0201ae6 <slub_check+0x520>
ffffffffc0201a0a:	6a05                	lui	s4,0x1
ffffffffc0201a0c:	9a22                	add	s4,s4,s0
ffffffffc0201a0e:	8722                	mv	a4,s0
ffffffffc0201a10:	04a00793          	li	a5,74
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
ffffffffc0201a14:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201a18:	27c5                	addiw	a5,a5,17
ffffffffc0201a1a:	0705                	addi	a4,a4,1
ffffffffc0201a1c:	0ff7f793          	zext.b	a5,a5
ffffffffc0201a20:	ff471ae3          	bne	a4,s4,ffffffffc0201a14 <slub_check+0x44e>
ffffffffc0201a24:	04900793          	li	a5,73
    for (size_t i = 0; i < size; i++) {
ffffffffc0201a28:	08900693          	li	a3,137
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201a2c:	0009c703          	lbu	a4,0(s3)
ffffffffc0201a30:	08f71b63          	bne	a4,a5,ffffffffc0201ac6 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201a34:	27c5                	addiw	a5,a5,17
ffffffffc0201a36:	0ff7f793          	zext.b	a5,a5
ffffffffc0201a3a:	0985                	addi	s3,s3,1
ffffffffc0201a3c:	fed798e3          	bne	a5,a3,ffffffffc0201a2c <slub_check+0x466>
    slub_free(object);
ffffffffc0201a40:	855a                	mv	a0,s6
ffffffffc0201a42:	82cff0ef          	jal	ra,ffffffffc0200a6e <slub_free>
    assert(nr_free_pages() == before - 1);
ffffffffc0201a46:	bb7fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201a4a:	04a00793          	li	a5,74
ffffffffc0201a4e:	2aa91c63          	bne	s2,a0,ffffffffc0201d06 <slub_check+0x740>
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201a52:	00044703          	lbu	a4,0(s0)
ffffffffc0201a56:	06f71863          	bne	a4,a5,ffffffffc0201ac6 <slub_check+0x500>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201a5a:	27c5                	addiw	a5,a5,17
ffffffffc0201a5c:	0405                	addi	s0,s0,1
ffffffffc0201a5e:	0ff7f793          	zext.b	a5,a5
ffffffffc0201a62:	ff4418e3          	bne	s0,s4,ffffffffc0201a52 <slub_check+0x48c>
    free_pages(page, 1);
ffffffffc0201a66:	4585                	li	a1,1
ffffffffc0201a68:	855e                	mv	a0,s7
ffffffffc0201a6a:	b87fe0ef          	jal	ra,ffffffffc02005f0 <free_pages>
    assert(nr_free_pages() == before);
ffffffffc0201a6e:	b8ffe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201a72:	26a49a63          	bne	s1,a0,ffffffffc0201ce6 <slub_check+0x720>
    slub_test_pmm_interaction();
    cprintf("slub test: mixed allocations and out-of-order release\n");
ffffffffc0201a76:	00002517          	auipc	a0,0x2
ffffffffc0201a7a:	06250513          	addi	a0,a0,98 # ffffffffc0203ad8 <etext+0x9c4>
ffffffffc0201a7e:	ee2fe0ef          	jal	ra,ffffffffc0200160 <cprintf>
    slub_test_mixed();
ffffffffc0201a82:	8bfff0ef          	jal	ra,ffffffffc0201340 <slub_test_mixed>
    assert(nr_free_pages() == free_before);
ffffffffc0201a86:	b77fe0ef          	jal	ra,ffffffffc02005fc <nr_free_pages>
ffffffffc0201a8a:	67a2                	ld	a5,8(sp)
ffffffffc0201a8c:	18f51d63          	bne	a0,a5,ffffffffc0201c26 <slub_check+0x660>
    cprintf("slub extended tests succeeded!\n");
}
ffffffffc0201a90:	640a                	ld	s0,128(sp)
ffffffffc0201a92:	60aa                	ld	ra,136(sp)
ffffffffc0201a94:	74e6                	ld	s1,120(sp)
ffffffffc0201a96:	7946                	ld	s2,112(sp)
ffffffffc0201a98:	79a6                	ld	s3,104(sp)
ffffffffc0201a9a:	7a06                	ld	s4,96(sp)
ffffffffc0201a9c:	6ae6                	ld	s5,88(sp)
ffffffffc0201a9e:	6b46                	ld	s6,80(sp)
ffffffffc0201aa0:	6ba6                	ld	s7,72(sp)
ffffffffc0201aa2:	6c06                	ld	s8,64(sp)
ffffffffc0201aa4:	7ce2                	ld	s9,56(sp)
ffffffffc0201aa6:	7d42                	ld	s10,48(sp)
ffffffffc0201aa8:	7da2                	ld	s11,40(sp)
    cprintf("slub extended tests succeeded!\n");
ffffffffc0201aaa:	00002517          	auipc	a0,0x2
ffffffffc0201aae:	08650513          	addi	a0,a0,134 # ffffffffc0203b30 <etext+0xa1c>
}
ffffffffc0201ab2:	6149                	addi	sp,sp,144
    cprintf("slub extended tests succeeded!\n");
ffffffffc0201ab4:	eacfe06f          	j	ffffffffc0200160 <cprintf>
ffffffffc0201ab8:	02000913          	li	s2,32
ffffffffc0201abc:	b3c5                	j	ffffffffc020189c <slub_check+0x2d6>
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
ffffffffc0201abe:	c7adf9e3          	bgeu	s11,s10,ffffffffc0201730 <slub_check+0x16a>
ffffffffc0201ac2:	d2dfe0ef          	jal	ra,ffffffffc02007ee <slub_test_disjoint.part.0>
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
ffffffffc0201ac6:	00002697          	auipc	a3,0x2
ffffffffc0201aca:	c5a68693          	addi	a3,a3,-934 # ffffffffc0203720 <etext+0x60c>
ffffffffc0201ace:	00002617          	auipc	a2,0x2
ffffffffc0201ad2:	a7a60613          	addi	a2,a2,-1414 # ffffffffc0203548 <etext+0x434>
ffffffffc0201ad6:	0c700593          	li	a1,199
ffffffffc0201ada:	00002517          	auipc	a0,0x2
ffffffffc0201ade:	a8650513          	addi	a0,a0,-1402 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201ae2:	ef4fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
ffffffffc0201ae6:	00002697          	auipc	a3,0x2
ffffffffc0201aea:	c0a68693          	addi	a3,a3,-1014 # ffffffffc02036f0 <etext+0x5dc>
ffffffffc0201aee:	00002617          	auipc	a2,0x2
ffffffffc0201af2:	a5a60613          	addi	a2,a2,-1446 # ffffffffc0203548 <etext+0x434>
ffffffffc0201af6:	0be00593          	li	a1,190
ffffffffc0201afa:	00002517          	auipc	a0,0x2
ffffffffc0201afe:	a6650513          	addi	a0,a0,-1434 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201b02:	ed4fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0201b06:	00002697          	auipc	a3,0x2
ffffffffc0201b0a:	afa68693          	addi	a3,a3,-1286 # ffffffffc0203600 <etext+0x4ec>
ffffffffc0201b0e:	00002617          	auipc	a2,0x2
ffffffffc0201b12:	a3a60613          	addi	a2,a2,-1478 # ffffffffc0203548 <etext+0x434>
ffffffffc0201b16:	06e00593          	li	a1,110
ffffffffc0201b1a:	00002517          	auipc	a0,0x2
ffffffffc0201b1e:	a4650513          	addi	a0,a0,-1466 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201b22:	eb4fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc0201b26:	00002697          	auipc	a3,0x2
ffffffffc0201b2a:	d4a68693          	addi	a3,a3,-694 # ffffffffc0203870 <etext+0x75c>
ffffffffc0201b2e:	00002617          	auipc	a2,0x2
ffffffffc0201b32:	a1a60613          	addi	a2,a2,-1510 # ffffffffc0203548 <etext+0x434>
ffffffffc0201b36:	14d00593          	li	a1,333
ffffffffc0201b3a:	00002517          	auipc	a0,0x2
ffffffffc0201b3e:	a2650513          	addi	a0,a0,-1498 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201b42:	e94fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(with_small == before - 1);
ffffffffc0201b46:	00002697          	auipc	a3,0x2
ffffffffc0201b4a:	eaa68693          	addi	a3,a3,-342 # ffffffffc02039f0 <etext+0x8dc>
ffffffffc0201b4e:	00002617          	auipc	a2,0x2
ffffffffc0201b52:	9fa60613          	addi	a2,a2,-1542 # ffffffffc0203548 <etext+0x434>
ffffffffc0201b56:	16700593          	li	a1,359
ffffffffc0201b5a:	00002517          	auipc	a0,0x2
ffffffffc0201b5e:	a0650513          	addi	a0,a0,-1530 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201b62:	e74fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0201b66:	00002697          	auipc	a3,0x2
ffffffffc0201b6a:	bfa68693          	addi	a3,a3,-1030 # ffffffffc0203760 <etext+0x64c>
ffffffffc0201b6e:	00002617          	auipc	a2,0x2
ffffffffc0201b72:	9da60613          	addi	a2,a2,-1574 # ffffffffc0203548 <etext+0x434>
ffffffffc0201b76:	15d00593          	li	a1,349
ffffffffc0201b7a:	00002517          	auipc	a0,0x2
ffffffffc0201b7e:	9e650513          	addi	a0,a0,-1562 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201b82:	e54fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0201b86:	00002697          	auipc	a3,0x2
ffffffffc0201b8a:	c3268693          	addi	a3,a3,-974 # ffffffffc02037b8 <etext+0x6a4>
ffffffffc0201b8e:	00002617          	auipc	a2,0x2
ffffffffc0201b92:	9ba60613          	addi	a2,a2,-1606 # ffffffffc0203548 <etext+0x434>
ffffffffc0201b96:	15b00593          	li	a1,347
ffffffffc0201b9a:	00002517          	auipc	a0,0x2
ffffffffc0201b9e:	9c650513          	addi	a0,a0,-1594 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201ba2:	e34fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(again == small1);
ffffffffc0201ba6:	00002697          	auipc	a3,0x2
ffffffffc0201baa:	dfa68693          	addi	a3,a3,-518 # ffffffffc02039a0 <etext+0x88c>
ffffffffc0201bae:	00002617          	auipc	a2,0x2
ffffffffc0201bb2:	99a60613          	addi	a2,a2,-1638 # ffffffffc0203548 <etext+0x434>
ffffffffc0201bb6:	14f00593          	li	a1,335
ffffffffc0201bba:	00002517          	auipc	a0,0x2
ffffffffc0201bbe:	9a650513          	addi	a0,a0,-1626 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201bc2:	e14fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nr_free_pages() == free_before_large);
ffffffffc0201bc6:	00002697          	auipc	a3,0x2
ffffffffc0201bca:	e7268693          	addi	a3,a3,-398 # ffffffffc0203a38 <etext+0x924>
ffffffffc0201bce:	00002617          	auipc	a2,0x2
ffffffffc0201bd2:	97a60613          	addi	a2,a2,-1670 # ffffffffc0203548 <etext+0x434>
ffffffffc0201bd6:	17300593          	li	a1,371
ffffffffc0201bda:	00002517          	auipc	a0,0x2
ffffffffc0201bde:	98650513          	addi	a0,a0,-1658 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201be2:	df4fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0201be6:	00002697          	auipc	a3,0x2
ffffffffc0201bea:	bd268693          	addi	a3,a3,-1070 # ffffffffc02037b8 <etext+0x6a4>
ffffffffc0201bee:	00002617          	auipc	a2,0x2
ffffffffc0201bf2:	95a60613          	addi	a2,a2,-1702 # ffffffffc0203548 <etext+0x434>
ffffffffc0201bf6:	17f00593          	li	a1,383
ffffffffc0201bfa:	00002517          	auipc	a0,0x2
ffffffffc0201bfe:	96650513          	addi	a0,a0,-1690 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201c02:	dd4fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0201c06:	00002697          	auipc	a3,0x2
ffffffffc0201c0a:	b5a68693          	addi	a3,a3,-1190 # ffffffffc0203760 <etext+0x64c>
ffffffffc0201c0e:	00002617          	auipc	a2,0x2
ffffffffc0201c12:	93a60613          	addi	a2,a2,-1734 # ffffffffc0203548 <etext+0x434>
ffffffffc0201c16:	17700593          	li	a1,375
ffffffffc0201c1a:	00002517          	auipc	a0,0x2
ffffffffc0201c1e:	94650513          	addi	a0,a0,-1722 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201c22:	db4fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == free_before);
ffffffffc0201c26:	00002697          	auipc	a3,0x2
ffffffffc0201c2a:	eea68693          	addi	a3,a3,-278 # ffffffffc0203b10 <etext+0x9fc>
ffffffffc0201c2e:	00002617          	auipc	a2,0x2
ffffffffc0201c32:	91a60613          	addi	a2,a2,-1766 # ffffffffc0203548 <etext+0x434>
ffffffffc0201c36:	1c300593          	li	a1,451
ffffffffc0201c3a:	00002517          	auipc	a0,0x2
ffffffffc0201c3e:	92650513          	addi	a0,a0,-1754 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201c42:	d94fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nr_free_pages() < free_before_large);
ffffffffc0201c46:	00002697          	auipc	a3,0x2
ffffffffc0201c4a:	dca68693          	addi	a3,a3,-566 # ffffffffc0203a10 <etext+0x8fc>
ffffffffc0201c4e:	00002617          	auipc	a2,0x2
ffffffffc0201c52:	8fa60613          	addi	a2,a2,-1798 # ffffffffc0203548 <etext+0x434>
ffffffffc0201c56:	16f00593          	li	a1,367
ffffffffc0201c5a:	00002517          	auipc	a0,0x2
ffffffffc0201c5e:	90650513          	addi	a0,a0,-1786 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201c62:	d74fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(page != NULL);
ffffffffc0201c66:	00002697          	auipc	a3,0x2
ffffffffc0201c6a:	e3268693          	addi	a3,a3,-462 # ffffffffc0203a98 <etext+0x984>
ffffffffc0201c6e:	00002617          	auipc	a2,0x2
ffffffffc0201c72:	8da60613          	addi	a2,a2,-1830 # ffffffffc0203548 <etext+0x434>
ffffffffc0201c76:	18200593          	li	a1,386
ffffffffc0201c7a:	00002517          	auipc	a0,0x2
ffffffffc0201c7e:	8e650513          	addi	a0,a0,-1818 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201c82:	d54fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0201c86:	00002697          	auipc	a3,0x2
ffffffffc0201c8a:	b3268693          	addi	a3,a3,-1230 # ffffffffc02037b8 <etext+0x6a4>
ffffffffc0201c8e:	00002617          	auipc	a2,0x2
ffffffffc0201c92:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0203548 <etext+0x434>
ffffffffc0201c96:	15700593          	li	a1,343
ffffffffc0201c9a:	00002517          	auipc	a0,0x2
ffffffffc0201c9e:	8c650513          	addi	a0,a0,-1850 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201ca2:	d34fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc0201ca6:	00002697          	auipc	a3,0x2
ffffffffc0201caa:	bca68693          	addi	a3,a3,-1078 # ffffffffc0203870 <etext+0x75c>
ffffffffc0201cae:	00002617          	auipc	a2,0x2
ffffffffc0201cb2:	89a60613          	addi	a2,a2,-1894 # ffffffffc0203548 <etext+0x434>
ffffffffc0201cb6:	18500593          	li	a1,389
ffffffffc0201cba:	00002517          	auipc	a0,0x2
ffffffffc0201cbe:	8a650513          	addi	a0,a0,-1882 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201cc2:	d14fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_test_page(object) != (uintptr_t)page_data);
ffffffffc0201cc6:	00002697          	auipc	a3,0x2
ffffffffc0201cca:	de268693          	addi	a3,a3,-542 # ffffffffc0203aa8 <etext+0x994>
ffffffffc0201cce:	00002617          	auipc	a2,0x2
ffffffffc0201cd2:	87a60613          	addi	a2,a2,-1926 # ffffffffc0203548 <etext+0x434>
ffffffffc0201cd6:	18400593          	li	a1,388
ffffffffc0201cda:	00002517          	auipc	a0,0x2
ffffffffc0201cde:	88650513          	addi	a0,a0,-1914 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201ce2:	cf4fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0201ce6:	00002697          	auipc	a3,0x2
ffffffffc0201cea:	a7a68693          	addi	a3,a3,-1414 # ffffffffc0203760 <etext+0x64c>
ffffffffc0201cee:	00002617          	auipc	a2,0x2
ffffffffc0201cf2:	85a60613          	addi	a2,a2,-1958 # ffffffffc0203548 <etext+0x434>
ffffffffc0201cf6:	18d00593          	li	a1,397
ffffffffc0201cfa:	00002517          	auipc	a0,0x2
ffffffffc0201cfe:	86650513          	addi	a0,a0,-1946 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201d02:	cd4fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0201d06:	00002697          	auipc	a3,0x2
ffffffffc0201d0a:	ab268693          	addi	a3,a3,-1358 # ffffffffc02037b8 <etext+0x6a4>
ffffffffc0201d0e:	00002617          	auipc	a2,0x2
ffffffffc0201d12:	83a60613          	addi	a2,a2,-1990 # ffffffffc0203548 <etext+0x434>
ffffffffc0201d16:	18a00593          	li	a1,394
ffffffffc0201d1a:	00002517          	auipc	a0,0x2
ffffffffc0201d1e:	84650513          	addi	a0,a0,-1978 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201d22:	cb4fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc0201d26:	00002697          	auipc	a3,0x2
ffffffffc0201d2a:	b4a68693          	addi	a3,a3,-1206 # ffffffffc0203870 <etext+0x75c>
ffffffffc0201d2e:	00002617          	auipc	a2,0x2
ffffffffc0201d32:	81a60613          	addi	a2,a2,-2022 # ffffffffc0203548 <etext+0x434>
ffffffffc0201d36:	14700593          	li	a1,327
ffffffffc0201d3a:	00002517          	auipc	a0,0x2
ffffffffc0201d3e:	82650513          	addi	a0,a0,-2010 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201d42:	c94fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc0201d46:	00002697          	auipc	a3,0x2
ffffffffc0201d4a:	b2a68693          	addi	a3,a3,-1238 # ffffffffc0203870 <etext+0x75c>
ffffffffc0201d4e:	00001617          	auipc	a2,0x1
ffffffffc0201d52:	7fa60613          	addi	a2,a2,2042 # ffffffffc0203548 <etext+0x434>
ffffffffc0201d56:	15500593          	li	a1,341
ffffffffc0201d5a:	00002517          	auipc	a0,0x2
ffffffffc0201d5e:	80650513          	addi	a0,a0,-2042 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201d62:	c74fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(slub_ready);
ffffffffc0201d66:	00002697          	auipc	a3,0x2
ffffffffc0201d6a:	89a68693          	addi	a3,a3,-1894 # ffffffffc0203600 <etext+0x4ec>
ffffffffc0201d6e:	00001617          	auipc	a2,0x1
ffffffffc0201d72:	7da60613          	addi	a2,a2,2010 # ffffffffc0203548 <etext+0x434>
ffffffffc0201d76:	1b500593          	li	a1,437
ffffffffc0201d7a:	00001517          	auipc	a0,0x1
ffffffffc0201d7e:	7e650513          	addi	a0,a0,2022 # ffffffffc0203560 <etext+0x44c>
ffffffffc0201d82:	c54fe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0201d86 <tree_buddy_nr_free_pages>:
}

static size_t
tree_buddy_nr_free_pages(void) {
    return tree_free_count;
}
ffffffffc0201d86:	00016517          	auipc	a0,0x16
ffffffffc0201d8a:	47253503          	ld	a0,1138(a0) # ffffffffc02181f8 <tree_free_count>
ffffffffc0201d8e:	8082                	ret

ffffffffc0201d90 <tree_add_free>:
    if (end <= start || start + span <= first) {
ffffffffc0201d90:	0af67b63          	bgeu	a2,a5,ffffffffc0201e46 <tree_add_free+0xb6>
              size_t first, size_t end) {
ffffffffc0201d94:	715d                	addi	sp,sp,-80
ffffffffc0201d96:	e0a2                	sd	s0,64(sp)
ffffffffc0201d98:	f052                	sd	s4,32(sp)
ffffffffc0201d9a:	ec56                	sd	s5,24(sp)
ffffffffc0201d9c:	8a3e                	mv	s4,a5
ffffffffc0201d9e:	e486                	sd	ra,72(sp)
ffffffffc0201da0:	fc26                	sd	s1,56(sp)
ffffffffc0201da2:	f84a                	sd	s2,48(sp)
ffffffffc0201da4:	f44e                	sd	s3,40(sp)
ffffffffc0201da6:	e85a                	sd	s6,16(sp)
ffffffffc0201da8:	e45e                	sd	s7,8(sp)
    if (end <= start || start + span <= first) {
ffffffffc0201daa:	00d607b3          	add	a5,a2,a3
ffffffffc0201dae:	8432                	mv	s0,a2
ffffffffc0201db0:	8aba                	mv	s5,a4
ffffffffc0201db2:	00f77f63          	bgeu	a4,a5,ffffffffc0201dd0 <tree_add_free+0x40>
ffffffffc0201db6:	892a                	mv	s2,a0
ffffffffc0201db8:	852e                	mv	a0,a1
    if (first <= start && start + span <= end) {
ffffffffc0201dba:	02e66663          	bltu	a2,a4,ffffffffc0201de6 <tree_add_free+0x56>
ffffffffc0201dbe:	02fa6463          	bltu	s4,a5,ffffffffc0201de6 <tree_add_free+0x56>
        assert(nodes[node] == TREE_UNAVAILABLE);
ffffffffc0201dc2:	992e                	add	s2,s2,a1
ffffffffc0201dc4:	00094783          	lbu	a5,0(s2)
ffffffffc0201dc8:	e3e5                	bnez	a5,ffffffffc0201ea8 <tree_add_free+0x118>
        nodes[node] = TREE_FREE;
ffffffffc0201dca:	4785                	li	a5,1
ffffffffc0201dcc:	00f90023          	sb	a5,0(s2)
}
ffffffffc0201dd0:	60a6                	ld	ra,72(sp)
ffffffffc0201dd2:	6406                	ld	s0,64(sp)
ffffffffc0201dd4:	74e2                	ld	s1,56(sp)
ffffffffc0201dd6:	7942                	ld	s2,48(sp)
ffffffffc0201dd8:	79a2                	ld	s3,40(sp)
ffffffffc0201dda:	7a02                	ld	s4,32(sp)
ffffffffc0201ddc:	6ae2                	ld	s5,24(sp)
ffffffffc0201dde:	6b42                	ld	s6,16(sp)
ffffffffc0201de0:	6ba2                	ld	s7,8(sp)
ffffffffc0201de2:	6161                	addi	sp,sp,80
ffffffffc0201de4:	8082                	ret
    assert(span > 1);
ffffffffc0201de6:	4785                	li	a5,1
ffffffffc0201de8:	0af68063          	beq	a3,a5,ffffffffc0201e88 <tree_add_free+0xf8>
    if (nodes[node] == TREE_UNAVAILABLE) {
ffffffffc0201dec:	00a90b33          	add	s6,s2,a0
ffffffffc0201df0:	000b4783          	lbu	a5,0(s6)
ffffffffc0201df4:	cbb1                	beqz	a5,ffffffffc0201e48 <tree_add_free+0xb8>
    assert(nodes[node] == TREE_SPLIT);
ffffffffc0201df6:	4709                	li	a4,2
ffffffffc0201df8:	06e79863          	bne	a5,a4,ffffffffc0201e68 <tree_add_free+0xd8>
    return node * 2;
ffffffffc0201dfc:	00151593          	slli	a1,a0,0x1
        nodes[tree_left(node)] = TREE_UNAVAILABLE;
ffffffffc0201e00:	00ab09b3          	add	s3,s6,a0
        nodes[tree_left(node) + 1] = TREE_UNAVAILABLE;
ffffffffc0201e04:	00158b93          	addi	s7,a1,1
    tree_add_free(nodes, tree_left(node), start, span / 2, first, end);
ffffffffc0201e08:	0016d493          	srli	s1,a3,0x1
ffffffffc0201e0c:	8622                	mv	a2,s0
ffffffffc0201e0e:	854a                	mv	a0,s2
ffffffffc0201e10:	87d2                	mv	a5,s4
ffffffffc0201e12:	8756                	mv	a4,s5
ffffffffc0201e14:	86a6                	mv	a3,s1
ffffffffc0201e16:	f7bff0ef          	jal	ra,ffffffffc0201d90 <tree_add_free>
    tree_add_free(nodes, tree_left(node) + 1, start + span / 2,
ffffffffc0201e1a:	87d2                	mv	a5,s4
ffffffffc0201e1c:	8756                	mv	a4,s5
ffffffffc0201e1e:	86a6                	mv	a3,s1
ffffffffc0201e20:	00848633          	add	a2,s1,s0
ffffffffc0201e24:	85de                	mv	a1,s7
ffffffffc0201e26:	854a                	mv	a0,s2
ffffffffc0201e28:	f69ff0ef          	jal	ra,ffffffffc0201d90 <tree_add_free>
    if (nodes[tree_left(node)] == TREE_FREE &&
ffffffffc0201e2c:	0009c783          	lbu	a5,0(s3)
ffffffffc0201e30:	4705                	li	a4,1
ffffffffc0201e32:	f8e79fe3          	bne	a5,a4,ffffffffc0201dd0 <tree_add_free+0x40>
        nodes[tree_left(node) + 1] == TREE_FREE) {
ffffffffc0201e36:	995e                	add	s2,s2,s7
    if (nodes[tree_left(node)] == TREE_FREE &&
ffffffffc0201e38:	00094703          	lbu	a4,0(s2)
ffffffffc0201e3c:	f8f71ae3          	bne	a4,a5,ffffffffc0201dd0 <tree_add_free+0x40>
        nodes[node] = TREE_FREE;
ffffffffc0201e40:	00eb0023          	sb	a4,0(s6)
ffffffffc0201e44:	b771                	j	ffffffffc0201dd0 <tree_add_free+0x40>
ffffffffc0201e46:	8082                	ret
    return node * 2;
ffffffffc0201e48:	00151593          	slli	a1,a0,0x1
        nodes[tree_left(node)] = TREE_UNAVAILABLE;
ffffffffc0201e4c:	00ab09b3          	add	s3,s6,a0
        nodes[tree_left(node) + 1] = TREE_UNAVAILABLE;
ffffffffc0201e50:	00158b93          	addi	s7,a1,1
        nodes[tree_left(node)] = TREE_UNAVAILABLE;
ffffffffc0201e54:	00098023          	sb	zero,0(s3)
        nodes[tree_left(node) + 1] = TREE_UNAVAILABLE;
ffffffffc0201e58:	017907b3          	add	a5,s2,s7
ffffffffc0201e5c:	00078023          	sb	zero,0(a5) # fffffffffffff000 <end+0x3fde6e00>
        nodes[node] = TREE_SPLIT;
ffffffffc0201e60:	4789                	li	a5,2
ffffffffc0201e62:	00fb0023          	sb	a5,0(s6)
    assert(nodes[node] == TREE_SPLIT);
ffffffffc0201e66:	b74d                	j	ffffffffc0201e08 <tree_add_free+0x78>
ffffffffc0201e68:	00002697          	auipc	a3,0x2
ffffffffc0201e6c:	e7068693          	addi	a3,a3,-400 # ffffffffc0203cd8 <slub_sizes+0xa0>
ffffffffc0201e70:	00001617          	auipc	a2,0x1
ffffffffc0201e74:	6d860613          	addi	a2,a2,1752 # ffffffffc0203548 <etext+0x434>
ffffffffc0201e78:	02c00593          	li	a1,44
ffffffffc0201e7c:	00002517          	auipc	a0,0x2
ffffffffc0201e80:	e2c50513          	addi	a0,a0,-468 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0201e84:	b52fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(span > 1);
ffffffffc0201e88:	00002697          	auipc	a3,0x2
ffffffffc0201e8c:	e4068693          	addi	a3,a3,-448 # ffffffffc0203cc8 <slub_sizes+0x90>
ffffffffc0201e90:	00001617          	auipc	a2,0x1
ffffffffc0201e94:	6b860613          	addi	a2,a2,1720 # ffffffffc0203548 <etext+0x434>
ffffffffc0201e98:	02600593          	li	a1,38
ffffffffc0201e9c:	00002517          	auipc	a0,0x2
ffffffffc0201ea0:	e0c50513          	addi	a0,a0,-500 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0201ea4:	b32fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nodes[node] == TREE_UNAVAILABLE);
ffffffffc0201ea8:	00002697          	auipc	a3,0x2
ffffffffc0201eac:	de068693          	addi	a3,a3,-544 # ffffffffc0203c88 <slub_sizes+0x50>
ffffffffc0201eb0:	00001617          	auipc	a2,0x1
ffffffffc0201eb4:	69860613          	addi	a2,a2,1688 # ffffffffc0203548 <etext+0x434>
ffffffffc0201eb8:	02200593          	li	a1,34
ffffffffc0201ebc:	00002517          	auipc	a0,0x2
ffffffffc0201ec0:	dec50513          	addi	a0,a0,-532 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0201ec4:	b12fe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0201ec8 <tree_allocate>:
    if (span < wanted || nodes[node] == TREE_UNAVAILABLE ||
ffffffffc0201ec8:	06e6ee63          	bltu	a3,a4,ffffffffc0201f44 <tree_allocate+0x7c>
              size_t wanted, size_t *result) {
ffffffffc0201ecc:	7139                	addi	sp,sp,-64
ffffffffc0201ece:	f426                	sd	s1,40(sp)
ffffffffc0201ed0:	ec4e                	sd	s3,24(sp)
ffffffffc0201ed2:	fc06                	sd	ra,56(sp)
ffffffffc0201ed4:	f822                	sd	s0,48(sp)
ffffffffc0201ed6:	f04a                	sd	s2,32(sp)
    if (span < wanted || nodes[node] == TREE_UNAVAILABLE ||
ffffffffc0201ed8:	00b50833          	add	a6,a0,a1
ffffffffc0201edc:	84ba                	mv	s1,a4
ffffffffc0201ede:	00084703          	lbu	a4,0(a6)
ffffffffc0201ee2:	89aa                	mv	s3,a0
ffffffffc0201ee4:	cb21                	beqz	a4,ffffffffc0201f34 <tree_allocate+0x6c>
ffffffffc0201ee6:	488d                	li	a7,3
ffffffffc0201ee8:	05170663          	beq	a4,a7,ffffffffc0201f34 <tree_allocate+0x6c>
    if (span == wanted) {
ffffffffc0201eec:	06968d63          	beq	a3,s1,ffffffffc0201f66 <tree_allocate+0x9e>
    if (nodes[node] == TREE_FREE) {
ffffffffc0201ef0:	4505                	li	a0,1
ffffffffc0201ef2:	04a70b63          	beq	a4,a0,ffffffffc0201f48 <tree_allocate+0x80>
    assert(nodes[node] == TREE_SPLIT);
ffffffffc0201ef6:	4509                	li	a0,2
ffffffffc0201ef8:	08a71063          	bne	a4,a0,ffffffffc0201f78 <tree_allocate+0xb0>
    return node * 2;
ffffffffc0201efc:	00159913          	slli	s2,a1,0x1
    return tree_allocate(nodes, tree_left(node), start, span / 2,
ffffffffc0201f00:	0016d413          	srli	s0,a3,0x1
ffffffffc0201f04:	8726                	mv	a4,s1
ffffffffc0201f06:	86a2                	mv	a3,s0
ffffffffc0201f08:	85ca                	mv	a1,s2
ffffffffc0201f0a:	854e                	mv	a0,s3
ffffffffc0201f0c:	e43e                	sd	a5,8(sp)
ffffffffc0201f0e:	e032                	sd	a2,0(sp)
ffffffffc0201f10:	fb9ff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc0201f14:	872a                	mv	a4,a0
                         wanted, result) ||
ffffffffc0201f16:	6602                	ld	a2,0(sp)
ffffffffc0201f18:	67a2                	ld	a5,8(sp)
ffffffffc0201f1a:	4505                	li	a0,1
ffffffffc0201f1c:	ef09                	bnez	a4,ffffffffc0201f36 <tree_allocate+0x6e>
           tree_allocate(nodes, tree_left(node) + 1, start + span / 2,
ffffffffc0201f1e:	8726                	mv	a4,s1
ffffffffc0201f20:	86a2                	mv	a3,s0
ffffffffc0201f22:	9622                	add	a2,a2,s0
ffffffffc0201f24:	00190593          	addi	a1,s2,1
ffffffffc0201f28:	854e                	mv	a0,s3
ffffffffc0201f2a:	f9fff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
        return 0;
ffffffffc0201f2e:	00a03533          	snez	a0,a0
ffffffffc0201f32:	a011                	j	ffffffffc0201f36 <tree_allocate+0x6e>
ffffffffc0201f34:	4501                	li	a0,0
}
ffffffffc0201f36:	70e2                	ld	ra,56(sp)
ffffffffc0201f38:	7442                	ld	s0,48(sp)
ffffffffc0201f3a:	74a2                	ld	s1,40(sp)
ffffffffc0201f3c:	7902                	ld	s2,32(sp)
ffffffffc0201f3e:	69e2                	ld	s3,24(sp)
ffffffffc0201f40:	6121                	addi	sp,sp,64
ffffffffc0201f42:	8082                	ret
        return 0;
ffffffffc0201f44:	4501                	li	a0,0
}
ffffffffc0201f46:	8082                	ret
        nodes[node] = TREE_SPLIT;
ffffffffc0201f48:	4509                	li	a0,2
ffffffffc0201f4a:	00a80023          	sb	a0,0(a6)
        nodes[tree_left(node)] = TREE_FREE;
ffffffffc0201f4e:	00b808b3          	add	a7,a6,a1
        nodes[tree_left(node) + 1] = TREE_FREE;
ffffffffc0201f52:	00159513          	slli	a0,a1,0x1
        nodes[tree_left(node)] = TREE_FREE;
ffffffffc0201f56:	00e88023          	sb	a4,0(a7)
        nodes[tree_left(node) + 1] = TREE_FREE;
ffffffffc0201f5a:	954e                	add	a0,a0,s3
ffffffffc0201f5c:	00e500a3          	sb	a4,1(a0)
    assert(nodes[node] == TREE_SPLIT);
ffffffffc0201f60:	00084703          	lbu	a4,0(a6)
ffffffffc0201f64:	bf49                	j	ffffffffc0201ef6 <tree_allocate+0x2e>
        if (nodes[node] != TREE_FREE) {
ffffffffc0201f66:	4685                	li	a3,1
        return 0;
ffffffffc0201f68:	4501                	li	a0,0
        if (nodes[node] != TREE_FREE) {
ffffffffc0201f6a:	fcd716e3          	bne	a4,a3,ffffffffc0201f36 <tree_allocate+0x6e>
        nodes[node] = TREE_ALLOCATED;
ffffffffc0201f6e:	01180023          	sb	a7,0(a6)
        *result = start;
ffffffffc0201f72:	e390                	sd	a2,0(a5)
        return 1;
ffffffffc0201f74:	4505                	li	a0,1
ffffffffc0201f76:	b7c1                	j	ffffffffc0201f36 <tree_allocate+0x6e>
    assert(nodes[node] == TREE_SPLIT);
ffffffffc0201f78:	00002697          	auipc	a3,0x2
ffffffffc0201f7c:	d6068693          	addi	a3,a3,-672 # ffffffffc0203cd8 <slub_sizes+0xa0>
ffffffffc0201f80:	00001617          	auipc	a2,0x1
ffffffffc0201f84:	5c860613          	addi	a2,a2,1480 # ffffffffc0203548 <etext+0x434>
ffffffffc0201f88:	04b00593          	li	a1,75
ffffffffc0201f8c:	00002517          	auipc	a0,0x2
ffffffffc0201f90:	d1c50513          	addi	a0,a0,-740 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0201f94:	a42fe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0201f98 <tree_release>:
             size_t first, size_t wanted) {
ffffffffc0201f98:	7179                	addi	sp,sp,-48
ffffffffc0201f9a:	f406                	sd	ra,40(sp)
ffffffffc0201f9c:	f022                	sd	s0,32(sp)
ffffffffc0201f9e:	ec26                	sd	s1,24(sp)
ffffffffc0201fa0:	e84a                	sd	s2,16(sp)
ffffffffc0201fa2:	e44e                	sd	s3,8(sp)
    assert(start <= first && wanted <= span &&
ffffffffc0201fa4:	0ac76963          	bltu	a4,a2,ffffffffc0202056 <tree_release+0xbe>
ffffffffc0201fa8:	0af6e763          	bltu	a3,a5,ffffffffc0202056 <tree_release+0xbe>
ffffffffc0201fac:	84aa                	mv	s1,a0
ffffffffc0201fae:	842e                	mv	s0,a1
ffffffffc0201fb0:	40f68533          	sub	a0,a3,a5
ffffffffc0201fb4:	40c705b3          	sub	a1,a4,a2
ffffffffc0201fb8:	08b56f63          	bltu	a0,a1,ffffffffc0202056 <tree_release+0xbe>
        assert(nodes[node] == TREE_ALLOCATED);
ffffffffc0201fbc:	00848933          	add	s2,s1,s0
ffffffffc0201fc0:	00094583          	lbu	a1,0(s2)
    if (start == first && span == wanted) {
ffffffffc0201fc4:	06e60a63          	beq	a2,a4,ffffffffc0202038 <tree_release+0xa0>
    assert(nodes[node] == TREE_SPLIT && span > 1);
ffffffffc0201fc8:	4509                	li	a0,2
ffffffffc0201fca:	0aa59663          	bne	a1,a0,ffffffffc0202076 <tree_release+0xde>
ffffffffc0201fce:	4585                	li	a1,1
ffffffffc0201fd0:	0ad5f363          	bgeu	a1,a3,ffffffffc0202076 <tree_release+0xde>
    size_t half = span / 2;
ffffffffc0201fd4:	8285                	srli	a3,a3,0x1
    if (first < start + half) {
ffffffffc0201fd6:	00d605b3          	add	a1,a2,a3
    return node * 2;
ffffffffc0201fda:	00141993          	slli	s3,s0,0x1
    if (first < start + half) {
ffffffffc0201fde:	02b76563          	bltu	a4,a1,ffffffffc0202008 <tree_release+0x70>
        tree_release(nodes, tree_left(node) + 1, start + half, half,
ffffffffc0201fe2:	862e                	mv	a2,a1
ffffffffc0201fe4:	8526                	mv	a0,s1
ffffffffc0201fe6:	00198593          	addi	a1,s3,1
ffffffffc0201fea:	fafff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    if (nodes[tree_left(node)] == TREE_FREE &&
ffffffffc0201fee:	944a                	add	s0,s0,s2
ffffffffc0201ff0:	00044783          	lbu	a5,0(s0)
ffffffffc0201ff4:	4705                	li	a4,1
ffffffffc0201ff6:	02e78363          	beq	a5,a4,ffffffffc020201c <tree_release+0x84>
}
ffffffffc0201ffa:	70a2                	ld	ra,40(sp)
ffffffffc0201ffc:	7402                	ld	s0,32(sp)
ffffffffc0201ffe:	64e2                	ld	s1,24(sp)
ffffffffc0202000:	6942                	ld	s2,16(sp)
ffffffffc0202002:	69a2                	ld	s3,8(sp)
ffffffffc0202004:	6145                	addi	sp,sp,48
ffffffffc0202006:	8082                	ret
        tree_release(nodes, tree_left(node), start, half, first, wanted);
ffffffffc0202008:	85ce                	mv	a1,s3
ffffffffc020200a:	8526                	mv	a0,s1
ffffffffc020200c:	f8dff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    if (nodes[tree_left(node)] == TREE_FREE &&
ffffffffc0202010:	944a                	add	s0,s0,s2
ffffffffc0202012:	00044783          	lbu	a5,0(s0)
ffffffffc0202016:	4705                	li	a4,1
ffffffffc0202018:	fee791e3          	bne	a5,a4,ffffffffc0201ffa <tree_release+0x62>
        nodes[tree_left(node) + 1] == TREE_FREE) {
ffffffffc020201c:	94ce                	add	s1,s1,s3
    if (nodes[tree_left(node)] == TREE_FREE &&
ffffffffc020201e:	0014c703          	lbu	a4,1(s1)
ffffffffc0202022:	fcf71ce3          	bne	a4,a5,ffffffffc0201ffa <tree_release+0x62>
        nodes[node] = TREE_FREE;
ffffffffc0202026:	00e90023          	sb	a4,0(s2)
}
ffffffffc020202a:	70a2                	ld	ra,40(sp)
ffffffffc020202c:	7402                	ld	s0,32(sp)
ffffffffc020202e:	64e2                	ld	s1,24(sp)
ffffffffc0202030:	6942                	ld	s2,16(sp)
ffffffffc0202032:	69a2                	ld	s3,8(sp)
ffffffffc0202034:	6145                	addi	sp,sp,48
ffffffffc0202036:	8082                	ret
    if (start == first && span == wanted) {
ffffffffc0202038:	f8d798e3          	bne	a5,a3,ffffffffc0201fc8 <tree_release+0x30>
        assert(nodes[node] == TREE_ALLOCATED);
ffffffffc020203c:	478d                	li	a5,3
ffffffffc020203e:	04f59c63          	bne	a1,a5,ffffffffc0202096 <tree_release+0xfe>
        nodes[node] = TREE_FREE;
ffffffffc0202042:	4785                	li	a5,1
ffffffffc0202044:	00f90023          	sb	a5,0(s2)
}
ffffffffc0202048:	70a2                	ld	ra,40(sp)
ffffffffc020204a:	7402                	ld	s0,32(sp)
ffffffffc020204c:	64e2                	ld	s1,24(sp)
ffffffffc020204e:	6942                	ld	s2,16(sp)
ffffffffc0202050:	69a2                	ld	s3,8(sp)
ffffffffc0202052:	6145                	addi	sp,sp,48
ffffffffc0202054:	8082                	ret
    assert(start <= first && wanted <= span &&
ffffffffc0202056:	00002697          	auipc	a3,0x2
ffffffffc020205a:	ca268693          	addi	a3,a3,-862 # ffffffffc0203cf8 <slub_sizes+0xc0>
ffffffffc020205e:	00001617          	auipc	a2,0x1
ffffffffc0202062:	4ea60613          	addi	a2,a2,1258 # ffffffffc0203548 <etext+0x434>
ffffffffc0202066:	05700593          	li	a1,87
ffffffffc020206a:	00002517          	auipc	a0,0x2
ffffffffc020206e:	c3e50513          	addi	a0,a0,-962 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202072:	964fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(nodes[node] == TREE_SPLIT && span > 1);
ffffffffc0202076:	00002697          	auipc	a3,0x2
ffffffffc020207a:	cea68693          	addi	a3,a3,-790 # ffffffffc0203d60 <slub_sizes+0x128>
ffffffffc020207e:	00001617          	auipc	a2,0x1
ffffffffc0202082:	4ca60613          	addi	a2,a2,1226 # ffffffffc0203548 <etext+0x434>
ffffffffc0202086:	05e00593          	li	a1,94
ffffffffc020208a:	00002517          	auipc	a0,0x2
ffffffffc020208e:	c1e50513          	addi	a0,a0,-994 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202092:	944fe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nodes[node] == TREE_ALLOCATED);
ffffffffc0202096:	00002697          	auipc	a3,0x2
ffffffffc020209a:	caa68693          	addi	a3,a3,-854 # ffffffffc0203d40 <slub_sizes+0x108>
ffffffffc020209e:	00001617          	auipc	a2,0x1
ffffffffc02020a2:	4aa60613          	addi	a2,a2,1194 # ffffffffc0203548 <etext+0x434>
ffffffffc02020a6:	05a00593          	li	a1,90
ffffffffc02020aa:	00002517          	auipc	a0,0x2
ffffffffc02020ae:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02020b2:	924fe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc02020b6 <tree_count_free>:
tree_count_free(const uint8_t *nodes, size_t node, size_t span) {
ffffffffc02020b6:	7139                	addi	sp,sp,-64
ffffffffc02020b8:	f426                	sd	s1,40(sp)
ffffffffc02020ba:	f04a                	sd	s2,32(sp)
ffffffffc02020bc:	ec4e                	sd	s3,24(sp)
ffffffffc02020be:	e852                	sd	s4,16(sp)
ffffffffc02020c0:	e456                	sd	s5,8(sp)
ffffffffc02020c2:	e05a                	sd	s6,0(sp)
ffffffffc02020c4:	fc06                	sd	ra,56(sp)
ffffffffc02020c6:	f822                	sd	s0,48(sp)
    switch (nodes[node]) {
ffffffffc02020c8:	00b507b3          	add	a5,a0,a1
ffffffffc02020cc:	0007c403          	lbu	s0,0(a5)
tree_count_free(const uint8_t *nodes, size_t node, size_t span) {
ffffffffc02020d0:	892a                	mv	s2,a0
ffffffffc02020d2:	84ae                	mv	s1,a1
ffffffffc02020d4:	89b2                	mv	s3,a2
    switch (nodes[node]) {
ffffffffc02020d6:	4a81                	li	s5,0
ffffffffc02020d8:	4a09                	li	s4,2
        assert(span > 1);
ffffffffc02020da:	4b05                	li	s6,1
    switch (nodes[node]) {
ffffffffc02020dc:	05440063          	beq	s0,s4,ffffffffc020211c <tree_count_free+0x66>
ffffffffc02020e0:	008a6f63          	bltu	s4,s0,ffffffffc02020fe <tree_count_free+0x48>
ffffffffc02020e4:	c011                	beqz	s0,ffffffffc02020e8 <tree_count_free+0x32>
        return span;
ffffffffc02020e6:	9ace                	add	s5,s5,s3
}
ffffffffc02020e8:	70e2                	ld	ra,56(sp)
ffffffffc02020ea:	7442                	ld	s0,48(sp)
ffffffffc02020ec:	74a2                	ld	s1,40(sp)
ffffffffc02020ee:	7902                	ld	s2,32(sp)
ffffffffc02020f0:	69e2                	ld	s3,24(sp)
ffffffffc02020f2:	6a42                	ld	s4,16(sp)
ffffffffc02020f4:	6b02                	ld	s6,0(sp)
ffffffffc02020f6:	8556                	mv	a0,s5
ffffffffc02020f8:	6aa2                	ld	s5,8(sp)
ffffffffc02020fa:	6121                	addi	sp,sp,64
ffffffffc02020fc:	8082                	ret
    switch (nodes[node]) {
ffffffffc02020fe:	478d                	li	a5,3
ffffffffc0202100:	fef404e3          	beq	s0,a5,ffffffffc02020e8 <tree_count_free+0x32>
        panic("tree buddy: invalid node state");
ffffffffc0202104:	00002617          	auipc	a2,0x2
ffffffffc0202108:	cd460613          	addi	a2,a2,-812 # ffffffffc0203dd8 <slub_sizes+0x1a0>
ffffffffc020210c:	07b00593          	li	a1,123
ffffffffc0202110:	00002517          	auipc	a0,0x2
ffffffffc0202114:	b9850513          	addi	a0,a0,-1128 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202118:	8befe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(span > 1);
ffffffffc020211c:	03698a63          	beq	s3,s6,ffffffffc0202150 <tree_count_free+0x9a>
    return node * 2;
ffffffffc0202120:	00149593          	slli	a1,s1,0x1
        assert(nodes[tree_left(node)] != TREE_FREE ||
ffffffffc0202124:	00b907b3          	add	a5,s2,a1
ffffffffc0202128:	0007c783          	lbu	a5,0(a5)
ffffffffc020212c:	00158493          	addi	s1,a1,1
ffffffffc0202130:	00990733          	add	a4,s2,s1
ffffffffc0202134:	00074403          	lbu	s0,0(a4)
ffffffffc0202138:	01679463          	bne	a5,s6,ffffffffc0202140 <tree_count_free+0x8a>
ffffffffc020213c:	03640a63          	beq	s0,s6,ffffffffc0202170 <tree_count_free+0xba>
        return tree_count_free(nodes, tree_left(node), span / 2) +
ffffffffc0202140:	0019d993          	srli	s3,s3,0x1
ffffffffc0202144:	864e                	mv	a2,s3
ffffffffc0202146:	854a                	mv	a0,s2
ffffffffc0202148:	f6fff0ef          	jal	ra,ffffffffc02020b6 <tree_count_free>
    return node * 2;
ffffffffc020214c:	9aaa                	add	s5,s5,a0
        return tree_count_free(nodes, tree_left(node), span / 2) +
ffffffffc020214e:	b779                	j	ffffffffc02020dc <tree_count_free+0x26>
        assert(span > 1);
ffffffffc0202150:	00002697          	auipc	a3,0x2
ffffffffc0202154:	b7868693          	addi	a3,a3,-1160 # ffffffffc0203cc8 <slub_sizes+0x90>
ffffffffc0202158:	00001617          	auipc	a2,0x1
ffffffffc020215c:	3f060613          	addi	a2,a2,1008 # ffffffffc0203548 <etext+0x434>
ffffffffc0202160:	07500593          	li	a1,117
ffffffffc0202164:	00002517          	auipc	a0,0x2
ffffffffc0202168:	b4450513          	addi	a0,a0,-1212 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc020216c:	86afe0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(nodes[tree_left(node)] != TREE_FREE ||
ffffffffc0202170:	00002697          	auipc	a3,0x2
ffffffffc0202174:	c1868693          	addi	a3,a3,-1000 # ffffffffc0203d88 <slub_sizes+0x150>
ffffffffc0202178:	00001617          	auipc	a2,0x1
ffffffffc020217c:	3d060613          	addi	a2,a2,976 # ffffffffc0203548 <etext+0x434>
ffffffffc0202180:	07600593          	li	a1,118
ffffffffc0202184:	00002517          	auipc	a0,0x2
ffffffffc0202188:	b2450513          	addi	a0,a0,-1244 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc020218c:	84afe0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0202190 <tree_buddy_free_pages>:
tree_buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0202190:	1101                	addi	sp,sp,-32
ffffffffc0202192:	ec06                	sd	ra,24(sp)
ffffffffc0202194:	e822                	sd	s0,16(sp)
ffffffffc0202196:	e426                	sd	s1,8(sp)
ffffffffc0202198:	e04a                	sd	s2,0(sp)
    assert(n > 0 && base >= pages && base < pages + (npage - nbase));
ffffffffc020219a:	12058863          	beqz	a1,ffffffffc02022ca <tree_buddy_free_pages+0x13a>
ffffffffc020219e:	00016717          	auipc	a4,0x16
ffffffffc02021a2:	02a73703          	ld	a4,42(a4) # ffffffffc02181c8 <pages>
ffffffffc02021a6:	842a                	mv	s0,a0
ffffffffc02021a8:	12e56163          	bltu	a0,a4,ffffffffc02022ca <tree_buddy_free_pages+0x13a>
ffffffffc02021ac:	00002797          	auipc	a5,0x2
ffffffffc02021b0:	4d47b783          	ld	a5,1236(a5) # ffffffffc0204680 <nbase>
ffffffffc02021b4:	00016697          	auipc	a3,0x16
ffffffffc02021b8:	00c6b683          	ld	a3,12(a3) # ffffffffc02181c0 <npage>
ffffffffc02021bc:	8e9d                	sub	a3,a3,a5
ffffffffc02021be:	00269793          	slli	a5,a3,0x2
ffffffffc02021c2:	97b6                	add	a5,a5,a3
ffffffffc02021c4:	078e                	slli	a5,a5,0x3
ffffffffc02021c6:	97ba                	add	a5,a5,a4
ffffffffc02021c8:	10f57163          	bgeu	a0,a5,ffffffffc02022ca <tree_buddy_free_pages+0x13a>
    size_t block = 1;
ffffffffc02021cc:	4905                	li	s2,1
    while (block < n && block < TREE_PAGES) {
ffffffffc02021ce:	47bd                	li	a5,15
ffffffffc02021d0:	03258763          	beq	a1,s2,ffffffffc02021fe <tree_buddy_free_pages+0x6e>
        block *= 2;
ffffffffc02021d4:	0906                	slli	s2,s2,0x1
    while (block < n && block < TREE_PAGES) {
ffffffffc02021d6:	02b97463          	bgeu	s2,a1,ffffffffc02021fe <tree_buddy_free_pages+0x6e>
ffffffffc02021da:	37fd                	addiw	a5,a5,-1
ffffffffc02021dc:	ffe5                	bnez	a5,ffffffffc02021d4 <tree_buddy_free_pages+0x44>
    assert(block != 0 && first < TREE_PAGES && block <= TREE_PAGES - first);
ffffffffc02021de:	00002697          	auipc	a3,0x2
ffffffffc02021e2:	c5a68693          	addi	a3,a3,-934 # ffffffffc0203e38 <slub_sizes+0x200>
ffffffffc02021e6:	00001617          	auipc	a2,0x1
ffffffffc02021ea:	36260613          	addi	a2,a2,866 # ffffffffc0203548 <etext+0x434>
ffffffffc02021ee:	0b400593          	li	a1,180
ffffffffc02021f2:	00002517          	auipc	a0,0x2
ffffffffc02021f6:	ab650513          	addi	a0,a0,-1354 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02021fa:	fddfd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    size_t first = base - pages;
ffffffffc02021fe:	40e407b3          	sub	a5,s0,a4
    assert(block != 0 && first < TREE_PAGES && block <= TREE_PAGES - first);
ffffffffc0202202:	00140637          	lui	a2,0x140
    size_t first = base - pages;
ffffffffc0202206:	4037d713          	srai	a4,a5,0x3
ffffffffc020220a:	00002597          	auipc	a1,0x2
ffffffffc020220e:	47e5b583          	ld	a1,1150(a1) # ffffffffc0204688 <nbase+0x8>
    assert(block != 0 && first < TREE_PAGES && block <= TREE_PAGES - first);
ffffffffc0202212:	fd860613          	addi	a2,a2,-40 # 13ffd8 <kern_entry-0xffffffffc00c0028>
    size_t first = base - pages;
ffffffffc0202216:	02b70733          	mul	a4,a4,a1
    assert(block != 0 && first < TREE_PAGES && block <= TREE_PAGES - first);
ffffffffc020221a:	fcf662e3          	bltu	a2,a5,ffffffffc02021de <tree_buddy_free_pages+0x4e>
ffffffffc020221e:	67a1                	lui	a5,0x8
ffffffffc0202220:	8f99                	sub	a5,a5,a4
ffffffffc0202222:	fb27eee3          	bltu	a5,s2,ffffffffc02021de <tree_buddy_free_pages+0x4e>
    assert(block <= npage - nbase - first);
ffffffffc0202226:	8e99                	sub	a3,a3,a4
ffffffffc0202228:	0f26e163          	bltu	a3,s2,ffffffffc020230a <tree_buddy_free_pages+0x17a>
    assert((first & (block - 1)) == 0);
ffffffffc020222c:	fff90793          	addi	a5,s2,-1
ffffffffc0202230:	8ff9                	and	a5,a5,a4
ffffffffc0202232:	efc5                	bnez	a5,ffffffffc02022ea <tree_buddy_free_pages+0x15a>
    for (struct Page *p = base; p < base + block; p++) {
ffffffffc0202234:	00291493          	slli	s1,s2,0x2
ffffffffc0202238:	94ca                	add	s1,s1,s2
ffffffffc020223a:	048e                	slli	s1,s1,0x3
ffffffffc020223c:	94a2                	add	s1,s1,s0
ffffffffc020223e:	86a2                	mv	a3,s0
ffffffffc0202240:	04947a63          	bgeu	s0,s1,ffffffffc0202294 <tree_buddy_free_pages+0x104>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202244:	6690                	ld	a2,8(a3)
ffffffffc0202246:	8a0d                	andi	a2,a2,3
ffffffffc0202248:	e22d                	bnez	a2,ffffffffc02022aa <tree_buddy_free_pages+0x11a>
    for (struct Page *p = base; p < base + block; p++) {
ffffffffc020224a:	02868693          	addi	a3,a3,40
ffffffffc020224e:	fe96ebe3          	bltu	a3,s1,ffffffffc0202244 <tree_buddy_free_pages+0xb4>
    tree_release(tree_nodes, 1, 0, TREE_PAGES, first, block);
ffffffffc0202252:	87ca                	mv	a5,s2
ffffffffc0202254:	66a1                	lui	a3,0x8
ffffffffc0202256:	4601                	li	a2,0
ffffffffc0202258:	4585                	li	a1,1
ffffffffc020225a:	00006517          	auipc	a0,0x6
ffffffffc020225e:	f4e50513          	addi	a0,a0,-178 # ffffffffc02081a8 <tree_nodes>
ffffffffc0202262:	d37ff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
        p->flags = 0;
ffffffffc0202266:	00043423          	sd	zero,8(s0)
        p->property = 0;
ffffffffc020226a:	00042823          	sw	zero,16(s0)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020226e:	00042023          	sw	zero,0(s0)
    for (struct Page *p = base; p < base + block; p++) {
ffffffffc0202272:	02840413          	addi	s0,s0,40
ffffffffc0202276:	fe9468e3          	bltu	s0,s1,ffffffffc0202266 <tree_buddy_free_pages+0xd6>
    tree_free_count += block;
ffffffffc020227a:	00016717          	auipc	a4,0x16
ffffffffc020227e:	f7e70713          	addi	a4,a4,-130 # ffffffffc02181f8 <tree_free_count>
ffffffffc0202282:	631c                	ld	a5,0(a4)
}
ffffffffc0202284:	60e2                	ld	ra,24(sp)
ffffffffc0202286:	6442                	ld	s0,16(sp)
    tree_free_count += block;
ffffffffc0202288:	97ca                	add	a5,a5,s2
ffffffffc020228a:	e31c                	sd	a5,0(a4)
}
ffffffffc020228c:	64a2                	ld	s1,8(sp)
ffffffffc020228e:	6902                	ld	s2,0(sp)
ffffffffc0202290:	6105                	addi	sp,sp,32
ffffffffc0202292:	8082                	ret
    tree_release(tree_nodes, 1, 0, TREE_PAGES, first, block);
ffffffffc0202294:	87ca                	mv	a5,s2
ffffffffc0202296:	66a1                	lui	a3,0x8
ffffffffc0202298:	4601                	li	a2,0
ffffffffc020229a:	4585                	li	a1,1
ffffffffc020229c:	00006517          	auipc	a0,0x6
ffffffffc02022a0:	f0c50513          	addi	a0,a0,-244 # ffffffffc02081a8 <tree_nodes>
ffffffffc02022a4:	cf5ff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    for (struct Page *p = base; p < base + block; p++) {
ffffffffc02022a8:	bfc9                	j	ffffffffc020227a <tree_buddy_free_pages+0xea>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02022aa:	00002697          	auipc	a3,0x2
ffffffffc02022ae:	c0e68693          	addi	a3,a3,-1010 # ffffffffc0203eb8 <slub_sizes+0x280>
ffffffffc02022b2:	00001617          	auipc	a2,0x1
ffffffffc02022b6:	29660613          	addi	a2,a2,662 # ffffffffc0203548 <etext+0x434>
ffffffffc02022ba:	0b900593          	li	a1,185
ffffffffc02022be:	00002517          	auipc	a0,0x2
ffffffffc02022c2:	9ea50513          	addi	a0,a0,-1558 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02022c6:	f11fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(n > 0 && base >= pages && base < pages + (npage - nbase));
ffffffffc02022ca:	00002697          	auipc	a3,0x2
ffffffffc02022ce:	b2e68693          	addi	a3,a3,-1234 # ffffffffc0203df8 <slub_sizes+0x1c0>
ffffffffc02022d2:	00001617          	auipc	a2,0x1
ffffffffc02022d6:	27660613          	addi	a2,a2,630 # ffffffffc0203548 <etext+0x434>
ffffffffc02022da:	0b100593          	li	a1,177
ffffffffc02022de:	00002517          	auipc	a0,0x2
ffffffffc02022e2:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02022e6:	ef1fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((first & (block - 1)) == 0);
ffffffffc02022ea:	00002697          	auipc	a3,0x2
ffffffffc02022ee:	bae68693          	addi	a3,a3,-1106 # ffffffffc0203e98 <slub_sizes+0x260>
ffffffffc02022f2:	00001617          	auipc	a2,0x1
ffffffffc02022f6:	25660613          	addi	a2,a2,598 # ffffffffc0203548 <etext+0x434>
ffffffffc02022fa:	0b600593          	li	a1,182
ffffffffc02022fe:	00002517          	auipc	a0,0x2
ffffffffc0202302:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202306:	ed1fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(block <= npage - nbase - first);
ffffffffc020230a:	00002697          	auipc	a3,0x2
ffffffffc020230e:	b6e68693          	addi	a3,a3,-1170 # ffffffffc0203e78 <slub_sizes+0x240>
ffffffffc0202312:	00001617          	auipc	a2,0x1
ffffffffc0202316:	23660613          	addi	a2,a2,566 # ffffffffc0203548 <etext+0x434>
ffffffffc020231a:	0b500593          	li	a1,181
ffffffffc020231e:	00002517          	auipc	a0,0x2
ffffffffc0202322:	98a50513          	addi	a0,a0,-1654 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202326:	eb1fd0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc020232a <tree_buddy_init_memmap>:
tree_buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc020232a:	1141                	addi	sp,sp,-16
ffffffffc020232c:	e406                	sd	ra,8(sp)
ffffffffc020232e:	e022                	sd	s0,0(sp)
    assert(n > 0 && base >= pages && base < pages + (npage - nbase));
ffffffffc0202330:	c9e9                	beqz	a1,ffffffffc0202402 <tree_buddy_init_memmap+0xd8>
ffffffffc0202332:	00016697          	auipc	a3,0x16
ffffffffc0202336:	e966b683          	ld	a3,-362(a3) # ffffffffc02181c8 <pages>
ffffffffc020233a:	0cd56463          	bltu	a0,a3,ffffffffc0202402 <tree_buddy_init_memmap+0xd8>
ffffffffc020233e:	00002717          	auipc	a4,0x2
ffffffffc0202342:	34273703          	ld	a4,834(a4) # ffffffffc0204680 <nbase>
ffffffffc0202346:	00016797          	auipc	a5,0x16
ffffffffc020234a:	e7a7b783          	ld	a5,-390(a5) # ffffffffc02181c0 <npage>
ffffffffc020234e:	8f99                	sub	a5,a5,a4
ffffffffc0202350:	00279713          	slli	a4,a5,0x2
ffffffffc0202354:	973e                	add	a4,a4,a5
ffffffffc0202356:	070e                	slli	a4,a4,0x3
ffffffffc0202358:	9736                	add	a4,a4,a3
ffffffffc020235a:	0ae57463          	bgeu	a0,a4,ffffffffc0202402 <tree_buddy_init_memmap+0xd8>
    size_t first = base - pages;
ffffffffc020235e:	40d506b3          	sub	a3,a0,a3
    assert(first < TREE_PAGES && n <= TREE_PAGES - first);
ffffffffc0202362:	00140637          	lui	a2,0x140
ffffffffc0202366:	842e                	mv	s0,a1
    size_t first = base - pages;
ffffffffc0202368:	4036d713          	srai	a4,a3,0x3
ffffffffc020236c:	00002597          	auipc	a1,0x2
ffffffffc0202370:	31c5b583          	ld	a1,796(a1) # ffffffffc0204688 <nbase+0x8>
    assert(first < TREE_PAGES && n <= TREE_PAGES - first);
ffffffffc0202374:	fd860613          	addi	a2,a2,-40 # 13ffd8 <kern_entry-0xffffffffc00c0028>
    size_t first = base - pages;
ffffffffc0202378:	02b70733          	mul	a4,a4,a1
    assert(first < TREE_PAGES && n <= TREE_PAGES - first);
ffffffffc020237c:	0cd66363          	bltu	a2,a3,ffffffffc0202442 <tree_buddy_init_memmap+0x118>
ffffffffc0202380:	66a1                	lui	a3,0x8
ffffffffc0202382:	8e99                	sub	a3,a3,a4
ffffffffc0202384:	0a86ef63          	bltu	a3,s0,ffffffffc0202442 <tree_buddy_init_memmap+0x118>
    assert(n <= npage - nbase - first);
ffffffffc0202388:	8f99                	sub	a5,a5,a4
ffffffffc020238a:	0887ec63          	bltu	a5,s0,ffffffffc0202422 <tree_buddy_init_memmap+0xf8>
    for (struct Page *p = base; p < base + n; p++) {
ffffffffc020238e:	00241693          	slli	a3,s0,0x2
ffffffffc0202392:	96a2                	add	a3,a3,s0
ffffffffc0202394:	068e                	slli	a3,a3,0x3
ffffffffc0202396:	96aa                	add	a3,a3,a0
ffffffffc0202398:	00d57f63          	bgeu	a0,a3,ffffffffc02023b6 <tree_buddy_init_memmap+0x8c>
        assert(PageReserved(p));
ffffffffc020239c:	651c                	ld	a5,8(a0)
ffffffffc020239e:	8b85                	andi	a5,a5,1
ffffffffc02023a0:	c3a9                	beqz	a5,ffffffffc02023e2 <tree_buddy_init_memmap+0xb8>
        p->flags = 0;
ffffffffc02023a2:	00053423          	sd	zero,8(a0)
        p->property = 0;
ffffffffc02023a6:	00052823          	sw	zero,16(a0)
ffffffffc02023aa:	00052023          	sw	zero,0(a0)
    for (struct Page *p = base; p < base + n; p++) {
ffffffffc02023ae:	02850513          	addi	a0,a0,40
ffffffffc02023b2:	fed565e3          	bltu	a0,a3,ffffffffc020239c <tree_buddy_init_memmap+0x72>
    tree_add_free(tree_nodes, 1, 0, TREE_PAGES, first, first + n);
ffffffffc02023b6:	00e407b3          	add	a5,s0,a4
ffffffffc02023ba:	66a1                	lui	a3,0x8
ffffffffc02023bc:	4601                	li	a2,0
ffffffffc02023be:	4585                	li	a1,1
ffffffffc02023c0:	00006517          	auipc	a0,0x6
ffffffffc02023c4:	de850513          	addi	a0,a0,-536 # ffffffffc02081a8 <tree_nodes>
ffffffffc02023c8:	9c9ff0ef          	jal	ra,ffffffffc0201d90 <tree_add_free>
    tree_free_count += n;
ffffffffc02023cc:	00016717          	auipc	a4,0x16
ffffffffc02023d0:	e2c70713          	addi	a4,a4,-468 # ffffffffc02181f8 <tree_free_count>
ffffffffc02023d4:	631c                	ld	a5,0(a4)
}
ffffffffc02023d6:	60a2                	ld	ra,8(sp)
    tree_free_count += n;
ffffffffc02023d8:	943e                	add	s0,s0,a5
ffffffffc02023da:	e300                	sd	s0,0(a4)
}
ffffffffc02023dc:	6402                	ld	s0,0(sp)
ffffffffc02023de:	0141                	addi	sp,sp,16
ffffffffc02023e0:	8082                	ret
        assert(PageReserved(p));
ffffffffc02023e2:	00002697          	auipc	a3,0x2
ffffffffc02023e6:	b4e68693          	addi	a3,a3,-1202 # ffffffffc0203f30 <slub_sizes+0x2f8>
ffffffffc02023ea:	00001617          	auipc	a2,0x1
ffffffffc02023ee:	15e60613          	addi	a2,a2,350 # ffffffffc0203548 <etext+0x434>
ffffffffc02023f2:	09700593          	li	a1,151
ffffffffc02023f6:	00002517          	auipc	a0,0x2
ffffffffc02023fa:	8b250513          	addi	a0,a0,-1870 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02023fe:	dd9fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(n > 0 && base >= pages && base < pages + (npage - nbase));
ffffffffc0202402:	00002697          	auipc	a3,0x2
ffffffffc0202406:	9f668693          	addi	a3,a3,-1546 # ffffffffc0203df8 <slub_sizes+0x1c0>
ffffffffc020240a:	00001617          	auipc	a2,0x1
ffffffffc020240e:	13e60613          	addi	a2,a2,318 # ffffffffc0203548 <etext+0x434>
ffffffffc0202412:	09200593          	li	a1,146
ffffffffc0202416:	00002517          	auipc	a0,0x2
ffffffffc020241a:	89250513          	addi	a0,a0,-1902 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc020241e:	db9fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(n <= npage - nbase - first);
ffffffffc0202422:	00002697          	auipc	a3,0x2
ffffffffc0202426:	aee68693          	addi	a3,a3,-1298 # ffffffffc0203f10 <slub_sizes+0x2d8>
ffffffffc020242a:	00001617          	auipc	a2,0x1
ffffffffc020242e:	11e60613          	addi	a2,a2,286 # ffffffffc0203548 <etext+0x434>
ffffffffc0202432:	09500593          	li	a1,149
ffffffffc0202436:	00002517          	auipc	a0,0x2
ffffffffc020243a:	87250513          	addi	a0,a0,-1934 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc020243e:	d99fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(first < TREE_PAGES && n <= TREE_PAGES - first);
ffffffffc0202442:	00002697          	auipc	a3,0x2
ffffffffc0202446:	a9e68693          	addi	a3,a3,-1378 # ffffffffc0203ee0 <slub_sizes+0x2a8>
ffffffffc020244a:	00001617          	auipc	a2,0x1
ffffffffc020244e:	0fe60613          	addi	a2,a2,254 # ffffffffc0203548 <etext+0x434>
ffffffffc0202452:	09400593          	li	a1,148
ffffffffc0202456:	00002517          	auipc	a0,0x2
ffffffffc020245a:	85250513          	addi	a0,a0,-1966 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc020245e:	d79fd0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0202462 <tree_buddy_alloc_pages.part.0>:
tree_buddy_alloc_pages(size_t n) {
ffffffffc0202462:	7179                	addi	sp,sp,-48
ffffffffc0202464:	f406                	sd	ra,40(sp)
ffffffffc0202466:	f022                	sd	s0,32(sp)
ffffffffc0202468:	ec26                	sd	s1,24(sp)
ffffffffc020246a:	e84a                	sd	s2,16(sp)
    while (block < n && block < TREE_PAGES) {
ffffffffc020246c:	4785                	li	a5,1
ffffffffc020246e:	02a7f063          	bgeu	a5,a0,ffffffffc020248e <tree_buddy_alloc_pages.part.0+0x2c>
ffffffffc0202472:	47bd                	li	a5,15
    size_t block = 1;
ffffffffc0202474:	4405                	li	s0,1
        block *= 2;
ffffffffc0202476:	0406                	slli	s0,s0,0x1
    while (block < n && block < TREE_PAGES) {
ffffffffc0202478:	37fd                	addiw	a5,a5,-1
ffffffffc020247a:	00a47b63          	bgeu	s0,a0,ffffffffc0202490 <tree_buddy_alloc_pages.part.0+0x2e>
ffffffffc020247e:	ffe5                	bnez	a5,ffffffffc0202476 <tree_buddy_alloc_pages.part.0+0x14>
}
ffffffffc0202480:	70a2                	ld	ra,40(sp)
ffffffffc0202482:	7402                	ld	s0,32(sp)
ffffffffc0202484:	64e2                	ld	s1,24(sp)
ffffffffc0202486:	6942                	ld	s2,16(sp)
        return NULL;
ffffffffc0202488:	4501                	li	a0,0
}
ffffffffc020248a:	6145                	addi	sp,sp,48
ffffffffc020248c:	8082                	ret
    size_t block = 1;
ffffffffc020248e:	4405                	li	s0,1
    if (block == 0 || block > tree_free_count) {
ffffffffc0202490:	00016917          	auipc	s2,0x16
ffffffffc0202494:	d6890913          	addi	s2,s2,-664 # ffffffffc02181f8 <tree_free_count>
ffffffffc0202498:	00093483          	ld	s1,0(s2)
ffffffffc020249c:	fe84e2e3          	bltu	s1,s0,ffffffffc0202480 <tree_buddy_alloc_pages.part.0+0x1e>
    if (!tree_allocate(tree_nodes, 1, 0, TREE_PAGES, block, &first)) {
ffffffffc02024a0:	003c                	addi	a5,sp,8
ffffffffc02024a2:	8722                	mv	a4,s0
ffffffffc02024a4:	66a1                	lui	a3,0x8
ffffffffc02024a6:	4601                	li	a2,0
ffffffffc02024a8:	4585                	li	a1,1
ffffffffc02024aa:	00006517          	auipc	a0,0x6
ffffffffc02024ae:	cfe50513          	addi	a0,a0,-770 # ffffffffc02081a8 <tree_nodes>
ffffffffc02024b2:	a17ff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc02024b6:	d569                	beqz	a0,ffffffffc0202480 <tree_buddy_alloc_pages.part.0+0x1e>
    return pages + first;
ffffffffc02024b8:	67a2                	ld	a5,8(sp)
    tree_free_count -= block;
ffffffffc02024ba:	40848433          	sub	s0,s1,s0
ffffffffc02024be:	00893023          	sd	s0,0(s2)
}
ffffffffc02024c2:	70a2                	ld	ra,40(sp)
ffffffffc02024c4:	7402                	ld	s0,32(sp)
    return pages + first;
ffffffffc02024c6:	00279513          	slli	a0,a5,0x2
ffffffffc02024ca:	953e                	add	a0,a0,a5
ffffffffc02024cc:	00351793          	slli	a5,a0,0x3
ffffffffc02024d0:	00016517          	auipc	a0,0x16
ffffffffc02024d4:	cf853503          	ld	a0,-776(a0) # ffffffffc02181c8 <pages>
}
ffffffffc02024d8:	64e2                	ld	s1,24(sp)
ffffffffc02024da:	6942                	ld	s2,16(sp)
    return pages + first;
ffffffffc02024dc:	953e                	add	a0,a0,a5
}
ffffffffc02024de:	6145                	addi	sp,sp,48
ffffffffc02024e0:	8082                	ret

ffffffffc02024e2 <tree_buddy_alloc_pages>:
    assert(n > 0);
ffffffffc02024e2:	c111                	beqz	a0,ffffffffc02024e6 <tree_buddy_alloc_pages+0x4>
ffffffffc02024e4:	bfbd                	j	ffffffffc0202462 <tree_buddy_alloc_pages.part.0>
tree_buddy_alloc_pages(size_t n) {
ffffffffc02024e6:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02024e8:	00002697          	auipc	a3,0x2
ffffffffc02024ec:	a5868693          	addi	a3,a3,-1448 # ffffffffc0203f40 <slub_sizes+0x308>
ffffffffc02024f0:	00001617          	auipc	a2,0x1
ffffffffc02024f4:	05860613          	addi	a2,a2,88 # ffffffffc0203548 <etext+0x434>
ffffffffc02024f8:	0a200593          	li	a1,162
ffffffffc02024fc:	00001517          	auipc	a0,0x1
ffffffffc0202500:	7ac50513          	addi	a0,a0,1964 # ffffffffc0203ca8 <slub_sizes+0x70>
tree_buddy_alloc_pages(size_t n) {
ffffffffc0202504:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202506:	cd1fd0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc020250a <tree_buddy_check>:

static void
tree_buddy_check(void) {
ffffffffc020250a:	711d                	addi	sp,sp,-96
    assert(tree_count_free(tree_nodes, 1, TREE_PAGES) == tree_free_count);
ffffffffc020250c:	6621                	lui	a2,0x8
ffffffffc020250e:	4585                	li	a1,1
ffffffffc0202510:	00006517          	auipc	a0,0x6
ffffffffc0202514:	c9850513          	addi	a0,a0,-872 # ffffffffc02081a8 <tree_nodes>
tree_buddy_check(void) {
ffffffffc0202518:	e4a6                	sd	s1,72(sp)
ffffffffc020251a:	ec86                	sd	ra,88(sp)
ffffffffc020251c:	e8a2                	sd	s0,80(sp)
ffffffffc020251e:	e0ca                	sd	s2,64(sp)
ffffffffc0202520:	fc4e                	sd	s3,56(sp)
ffffffffc0202522:	f852                	sd	s4,48(sp)
    assert(tree_count_free(tree_nodes, 1, TREE_PAGES) == tree_free_count);
ffffffffc0202524:	00016497          	auipc	s1,0x16
ffffffffc0202528:	cd448493          	addi	s1,s1,-812 # ffffffffc02181f8 <tree_free_count>
ffffffffc020252c:	b8bff0ef          	jal	ra,ffffffffc02020b6 <tree_count_free>
ffffffffc0202530:	609c                	ld	a5,0(s1)
ffffffffc0202532:	68f51063          	bne	a0,a5,ffffffffc0202bb2 <tree_buddy_check+0x6a8>

    /* The 13-page range keeps its 8-, 4-, and 1-page pieces. */
    uint8_t small[32] = {0};
    size_t first;
    tree_add_free(small, 1, 0, 16, 0, 13);
ffffffffc0202536:	47b5                	li	a5,13
ffffffffc0202538:	4701                	li	a4,0
ffffffffc020253a:	46c1                	li	a3,16
ffffffffc020253c:	4601                	li	a2,0
ffffffffc020253e:	4585                	li	a1,1
ffffffffc0202540:	0808                	addi	a0,sp,16
    uint8_t small[32] = {0};
ffffffffc0202542:	e802                	sd	zero,16(sp)
ffffffffc0202544:	ec02                	sd	zero,24(sp)
ffffffffc0202546:	f002                	sd	zero,32(sp)
ffffffffc0202548:	f402                	sd	zero,40(sp)
    tree_add_free(small, 1, 0, 16, 0, 13);
ffffffffc020254a:	847ff0ef          	jal	ra,ffffffffc0201d90 <tree_add_free>
    assert(tree_count_free(small, 1, 16) == 13);
ffffffffc020254e:	4641                	li	a2,16
ffffffffc0202550:	4585                	li	a1,1
ffffffffc0202552:	0808                	addi	a0,sp,16
ffffffffc0202554:	b63ff0ef          	jal	ra,ffffffffc02020b6 <tree_count_free>
ffffffffc0202558:	47b5                	li	a5,13
ffffffffc020255a:	62f51c63          	bne	a0,a5,ffffffffc0202b92 <tree_buddy_check+0x688>
    assert(!tree_allocate(small, 1, 0, 16, 16, &first));
ffffffffc020255e:	003c                	addi	a5,sp,8
ffffffffc0202560:	4741                	li	a4,16
ffffffffc0202562:	46c1                	li	a3,16
ffffffffc0202564:	4601                	li	a2,0
ffffffffc0202566:	4585                	li	a1,1
ffffffffc0202568:	0808                	addi	a0,sp,16
ffffffffc020256a:	95fff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc020256e:	38051263          	bnez	a0,ffffffffc02028f2 <tree_buddy_check+0x3e8>
    assert(tree_allocate(small, 1, 0, 16, 8, &first) && first == 0);
ffffffffc0202572:	003c                	addi	a5,sp,8
ffffffffc0202574:	4721                	li	a4,8
ffffffffc0202576:	46c1                	li	a3,16
ffffffffc0202578:	4601                	li	a2,0
ffffffffc020257a:	4585                	li	a1,1
ffffffffc020257c:	0808                	addi	a0,sp,16
ffffffffc020257e:	94bff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc0202582:	3a050863          	beqz	a0,ffffffffc0202932 <tree_buddy_check+0x428>
ffffffffc0202586:	67a2                	ld	a5,8(sp)
ffffffffc0202588:	3a079563          	bnez	a5,ffffffffc0202932 <tree_buddy_check+0x428>
    assert(tree_allocate(small, 1, 0, 16, 4, &first) && first == 8);
ffffffffc020258c:	003c                	addi	a5,sp,8
ffffffffc020258e:	4711                	li	a4,4
ffffffffc0202590:	46c1                	li	a3,16
ffffffffc0202592:	4601                	li	a2,0
ffffffffc0202594:	4585                	li	a1,1
ffffffffc0202596:	0808                	addi	a0,sp,16
ffffffffc0202598:	931ff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc020259c:	36050b63          	beqz	a0,ffffffffc0202912 <tree_buddy_check+0x408>
ffffffffc02025a0:	6722                	ld	a4,8(sp)
ffffffffc02025a2:	47a1                	li	a5,8
ffffffffc02025a4:	36f71763          	bne	a4,a5,ffffffffc0202912 <tree_buddy_check+0x408>
    assert(tree_allocate(small, 1, 0, 16, 1, &first) && first == 12);
ffffffffc02025a8:	003c                	addi	a5,sp,8
ffffffffc02025aa:	4705                	li	a4,1
ffffffffc02025ac:	46c1                	li	a3,16
ffffffffc02025ae:	4601                	li	a2,0
ffffffffc02025b0:	4585                	li	a1,1
ffffffffc02025b2:	0808                	addi	a0,sp,16
ffffffffc02025b4:	915ff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc02025b8:	54050d63          	beqz	a0,ffffffffc0202b12 <tree_buddy_check+0x608>
ffffffffc02025bc:	6722                	ld	a4,8(sp)
ffffffffc02025be:	47b1                	li	a5,12
ffffffffc02025c0:	54f71963          	bne	a4,a5,ffffffffc0202b12 <tree_buddy_check+0x608>
    assert(tree_count_free(small, 1, 16) == 0);
ffffffffc02025c4:	4641                	li	a2,16
ffffffffc02025c6:	4585                	li	a1,1
ffffffffc02025c8:	0808                	addi	a0,sp,16
ffffffffc02025ca:	aedff0ef          	jal	ra,ffffffffc02020b6 <tree_count_free>
ffffffffc02025ce:	52051263          	bnez	a0,ffffffffc0202af2 <tree_buddy_check+0x5e8>
    tree_release(small, 1, 0, 16, 8, 4);
ffffffffc02025d2:	4791                	li	a5,4
ffffffffc02025d4:	4721                	li	a4,8
ffffffffc02025d6:	46c1                	li	a3,16
ffffffffc02025d8:	4601                	li	a2,0
ffffffffc02025da:	4585                	li	a1,1
ffffffffc02025dc:	0808                	addi	a0,sp,16
ffffffffc02025de:	9bbff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    tree_release(small, 1, 0, 16, 0, 8);
ffffffffc02025e2:	47a1                	li	a5,8
ffffffffc02025e4:	4701                	li	a4,0
ffffffffc02025e6:	46c1                	li	a3,16
ffffffffc02025e8:	4601                	li	a2,0
ffffffffc02025ea:	4585                	li	a1,1
ffffffffc02025ec:	0808                	addi	a0,sp,16
ffffffffc02025ee:	9abff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    tree_release(small, 1, 0, 16, 12, 1);
ffffffffc02025f2:	4785                	li	a5,1
ffffffffc02025f4:	4731                	li	a4,12
ffffffffc02025f6:	46c1                	li	a3,16
ffffffffc02025f8:	4601                	li	a2,0
ffffffffc02025fa:	4585                	li	a1,1
ffffffffc02025fc:	0808                	addi	a0,sp,16
ffffffffc02025fe:	99bff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    assert(tree_count_free(small, 1, 16) == 13);
ffffffffc0202602:	4641                	li	a2,16
ffffffffc0202604:	4585                	li	a1,1
ffffffffc0202606:	0808                	addi	a0,sp,16
ffffffffc0202608:	aafff0ef          	jal	ra,ffffffffc02020b6 <tree_count_free>
ffffffffc020260c:	47b5                	li	a5,13
ffffffffc020260e:	842a                	mv	s0,a0
ffffffffc0202610:	4cf51163          	bne	a0,a5,ffffffffc0202ad2 <tree_buddy_check+0x5c8>

    /* An unaligned 13-page range must keep its leading three-page tail. */
    memset(small, TREE_UNAVAILABLE, sizeof(small));
ffffffffc0202614:	02000613          	li	a2,32
ffffffffc0202618:	4581                	li	a1,0
ffffffffc020261a:	0808                	addi	a0,sp,16
ffffffffc020261c:	2e7000ef          	jal	ra,ffffffffc0203102 <memset>
    tree_add_free(small, 1, 0, 16, 3, 16);
ffffffffc0202620:	4601                	li	a2,0
ffffffffc0202622:	4585                	li	a1,1
ffffffffc0202624:	0808                	addi	a0,sp,16
ffffffffc0202626:	47c1                	li	a5,16
ffffffffc0202628:	470d                	li	a4,3
ffffffffc020262a:	46c1                	li	a3,16
ffffffffc020262c:	f64ff0ef          	jal	ra,ffffffffc0201d90 <tree_add_free>
    assert(tree_count_free(small, 1, 16) == 13);
ffffffffc0202630:	4641                	li	a2,16
ffffffffc0202632:	4585                	li	a1,1
ffffffffc0202634:	0808                	addi	a0,sp,16
ffffffffc0202636:	a81ff0ef          	jal	ra,ffffffffc02020b6 <tree_count_free>
ffffffffc020263a:	46851c63          	bne	a0,s0,ffffffffc0202ab2 <tree_buddy_check+0x5a8>
    assert(tree_allocate(small, 1, 0, 16, 8, &first) && first == 8);
ffffffffc020263e:	003c                	addi	a5,sp,8
ffffffffc0202640:	4721                	li	a4,8
ffffffffc0202642:	46c1                	li	a3,16
ffffffffc0202644:	4601                	li	a2,0
ffffffffc0202646:	4585                	li	a1,1
ffffffffc0202648:	0808                	addi	a0,sp,16
ffffffffc020264a:	87fff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc020264e:	5c050263          	beqz	a0,ffffffffc0202c12 <tree_buddy_check+0x708>
ffffffffc0202652:	6722                	ld	a4,8(sp)
ffffffffc0202654:	47a1                	li	a5,8
ffffffffc0202656:	5af71e63          	bne	a4,a5,ffffffffc0202c12 <tree_buddy_check+0x708>
    assert(tree_allocate(small, 1, 0, 16, 4, &first) && first == 4);
ffffffffc020265a:	003c                	addi	a5,sp,8
ffffffffc020265c:	4711                	li	a4,4
ffffffffc020265e:	46c1                	li	a3,16
ffffffffc0202660:	4601                	li	a2,0
ffffffffc0202662:	4585                	li	a1,1
ffffffffc0202664:	0808                	addi	a0,sp,16
ffffffffc0202666:	863ff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc020266a:	3a050463          	beqz	a0,ffffffffc0202a12 <tree_buddy_check+0x508>
ffffffffc020266e:	6722                	ld	a4,8(sp)
ffffffffc0202670:	4791                	li	a5,4
ffffffffc0202672:	3af71063          	bne	a4,a5,ffffffffc0202a12 <tree_buddy_check+0x508>
    assert(tree_allocate(small, 1, 0, 16, 1, &first) && first == 3);
ffffffffc0202676:	003c                	addi	a5,sp,8
ffffffffc0202678:	4705                	li	a4,1
ffffffffc020267a:	46c1                	li	a3,16
ffffffffc020267c:	4601                	li	a2,0
ffffffffc020267e:	4585                	li	a1,1
ffffffffc0202680:	0808                	addi	a0,sp,16
ffffffffc0202682:	847ff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc0202686:	36050663          	beqz	a0,ffffffffc02029f2 <tree_buddy_check+0x4e8>
ffffffffc020268a:	6722                	ld	a4,8(sp)
ffffffffc020268c:	478d                	li	a5,3
ffffffffc020268e:	36f71263          	bne	a4,a5,ffffffffc02029f2 <tree_buddy_check+0x4e8>
    assert(tree_count_free(small, 1, 16) == 0);
ffffffffc0202692:	4641                	li	a2,16
ffffffffc0202694:	4585                	li	a1,1
ffffffffc0202696:	0808                	addi	a0,sp,16
ffffffffc0202698:	a1fff0ef          	jal	ra,ffffffffc02020b6 <tree_count_free>
ffffffffc020269c:	842a                	mv	s0,a0
ffffffffc020269e:	54051a63          	bnez	a0,ffffffffc0202bf2 <tree_buddy_check+0x6e8>

    /* Adjacent quarters 4..7 and 8..11 are not buddies. */
    memset(small, TREE_UNAVAILABLE, sizeof(small));
ffffffffc02026a2:	02000613          	li	a2,32
ffffffffc02026a6:	4581                	li	a1,0
ffffffffc02026a8:	0808                	addi	a0,sp,16
ffffffffc02026aa:	259000ef          	jal	ra,ffffffffc0203102 <memset>
    tree_add_free(small, 1, 0, 16, 0, 16);
ffffffffc02026ae:	47c1                	li	a5,16
ffffffffc02026b0:	4701                	li	a4,0
ffffffffc02026b2:	46c1                	li	a3,16
ffffffffc02026b4:	4601                	li	a2,0
ffffffffc02026b6:	4585                	li	a1,1
ffffffffc02026b8:	0808                	addi	a0,sp,16
ffffffffc02026ba:	ed6ff0ef          	jal	ra,ffffffffc0201d90 <tree_add_free>
    for (size_t i = 0; i < 4; i++) {
        assert(tree_allocate(small, 1, 0, 16, 4, &first));
ffffffffc02026be:	003c                	addi	a5,sp,8
ffffffffc02026c0:	4711                	li	a4,4
ffffffffc02026c2:	46c1                	li	a3,16
ffffffffc02026c4:	4601                	li	a2,0
ffffffffc02026c6:	4585                	li	a1,1
ffffffffc02026c8:	0808                	addi	a0,sp,16
ffffffffc02026ca:	ffeff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc02026ce:	1e050263          	beqz	a0,ffffffffc02028b2 <tree_buddy_check+0x3a8>
        assert(first == 4 * i);
ffffffffc02026d2:	67a2                	ld	a5,8(sp)
ffffffffc02026d4:	1e879f63          	bne	a5,s0,ffffffffc02028d2 <tree_buddy_check+0x3c8>
    for (size_t i = 0; i < 4; i++) {
ffffffffc02026d8:	0411                	addi	s0,s0,4
ffffffffc02026da:	47c1                	li	a5,16
ffffffffc02026dc:	fef411e3          	bne	s0,a5,ffffffffc02026be <tree_buddy_check+0x1b4>
    }
    tree_release(small, 1, 0, 16, 4, 4);
ffffffffc02026e0:	4791                	li	a5,4
ffffffffc02026e2:	4711                	li	a4,4
ffffffffc02026e4:	46c1                	li	a3,16
ffffffffc02026e6:	4601                	li	a2,0
ffffffffc02026e8:	4585                	li	a1,1
ffffffffc02026ea:	0808                	addi	a0,sp,16
ffffffffc02026ec:	8adff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    tree_release(small, 1, 0, 16, 8, 4);
ffffffffc02026f0:	4721                	li	a4,8
ffffffffc02026f2:	46c1                	li	a3,16
ffffffffc02026f4:	4601                	li	a2,0
ffffffffc02026f6:	4585                	li	a1,1
ffffffffc02026f8:	0808                	addi	a0,sp,16
ffffffffc02026fa:	4791                	li	a5,4
ffffffffc02026fc:	89dff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    assert(!tree_allocate(small, 1, 0, 16, 8, &first));
ffffffffc0202700:	003c                	addi	a5,sp,8
ffffffffc0202702:	4721                	li	a4,8
ffffffffc0202704:	46c1                	li	a3,16
ffffffffc0202706:	4601                	li	a2,0
ffffffffc0202708:	4585                	li	a1,1
ffffffffc020270a:	0808                	addi	a0,sp,16
ffffffffc020270c:	fbcff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc0202710:	24051163          	bnez	a0,ffffffffc0202952 <tree_buddy_check+0x448>
    assert(tree_count_free(small, 1, 16) == 8);
ffffffffc0202714:	4641                	li	a2,16
ffffffffc0202716:	4585                	li	a1,1
ffffffffc0202718:	0808                	addi	a0,sp,16
ffffffffc020271a:	99dff0ef          	jal	ra,ffffffffc02020b6 <tree_count_free>
ffffffffc020271e:	47a1                	li	a5,8
ffffffffc0202720:	2af51963          	bne	a0,a5,ffffffffc02029d2 <tree_buddy_check+0x4c8>
    tree_release(small, 1, 0, 16, 0, 4);
ffffffffc0202724:	4701                	li	a4,0
ffffffffc0202726:	46c1                	li	a3,16
ffffffffc0202728:	4601                	li	a2,0
ffffffffc020272a:	4585                	li	a1,1
ffffffffc020272c:	0808                	addi	a0,sp,16
ffffffffc020272e:	4791                	li	a5,4
ffffffffc0202730:	869ff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    assert(tree_allocate(small, 1, 0, 16, 8, &first) && first == 0);
ffffffffc0202734:	003c                	addi	a5,sp,8
ffffffffc0202736:	4721                	li	a4,8
ffffffffc0202738:	46c1                	li	a3,16
ffffffffc020273a:	4601                	li	a2,0
ffffffffc020273c:	4585                	li	a1,1
ffffffffc020273e:	0808                	addi	a0,sp,16
ffffffffc0202740:	f88ff0ef          	jal	ra,ffffffffc0201ec8 <tree_allocate>
ffffffffc0202744:	26050763          	beqz	a0,ffffffffc02029b2 <tree_buddy_check+0x4a8>
ffffffffc0202748:	67a2                	ld	a5,8(sp)
ffffffffc020274a:	26079463          	bnez	a5,ffffffffc02029b2 <tree_buddy_check+0x4a8>
    tree_release(small, 1, 0, 16, 0, 8);
ffffffffc020274e:	47a1                	li	a5,8
ffffffffc0202750:	4701                	li	a4,0
ffffffffc0202752:	46c1                	li	a3,16
ffffffffc0202754:	4601                	li	a2,0
ffffffffc0202756:	4585                	li	a1,1
ffffffffc0202758:	0808                	addi	a0,sp,16
ffffffffc020275a:	83fff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    tree_release(small, 1, 0, 16, 12, 4);
ffffffffc020275e:	4791                	li	a5,4
ffffffffc0202760:	4731                	li	a4,12
ffffffffc0202762:	46c1                	li	a3,16
ffffffffc0202764:	4601                	li	a2,0
ffffffffc0202766:	4585                	li	a1,1
ffffffffc0202768:	0808                	addi	a0,sp,16
ffffffffc020276a:	82fff0ef          	jal	ra,ffffffffc0201f98 <tree_release>
    assert(small[1] == TREE_FREE);
ffffffffc020276e:	01114703          	lbu	a4,17(sp)
ffffffffc0202772:	4785                	li	a5,1
ffffffffc0202774:	20f71f63          	bne	a4,a5,ffffffffc0202992 <tree_buddy_check+0x488>
    assert(tree_count_free(small, 1, 16) == 16);
ffffffffc0202778:	4641                	li	a2,16
ffffffffc020277a:	4585                	li	a1,1
ffffffffc020277c:	0808                	addi	a0,sp,16
ffffffffc020277e:	939ff0ef          	jal	ra,ffffffffc02020b6 <tree_count_free>
ffffffffc0202782:	1e851863          	bne	a0,s0,ffffffffc0202972 <tree_buddy_check+0x468>

    size_t before = tree_free_count;
ffffffffc0202786:	6080                	ld	s0,0(s1)
    assert(before >= 13 && tree_round_up(3) == 4 && tree_round_up(5) == 8);
ffffffffc0202788:	47b1                	li	a5,12
ffffffffc020278a:	0e87f063          	bgeu	a5,s0,ffffffffc020286a <tree_buddy_check+0x360>
    assert(n > 0);
ffffffffc020278e:	4515                	li	a0,5
ffffffffc0202790:	cd3ff0ef          	jal	ra,ffffffffc0202462 <tree_buddy_alloc_pages.part.0>
ffffffffc0202794:	8a2a                	mv	s4,a0
ffffffffc0202796:	450d                	li	a0,3
ffffffffc0202798:	ccbff0ef          	jal	ra,ffffffffc0202462 <tree_buddy_alloc_pages.part.0>
ffffffffc020279c:	892a                	mv	s2,a0
ffffffffc020279e:	4505                	li	a0,1
ffffffffc02027a0:	cc3ff0ef          	jal	ra,ffffffffc0202462 <tree_buddy_alloc_pages.part.0>
ffffffffc02027a4:	89aa                	mv	s3,a0
    struct Page *a = tree_buddy_alloc_pages(5);
    struct Page *b = tree_buddy_alloc_pages(3);
    struct Page *c = tree_buddy_alloc_pages(1);
    assert(a != NULL && b != NULL && c != NULL);
ffffffffc02027a6:	2e0a0663          	beqz	s4,ffffffffc0202a92 <tree_buddy_check+0x588>
ffffffffc02027aa:	2e090463          	beqz	s2,ffffffffc0202a92 <tree_buddy_check+0x588>
ffffffffc02027ae:	2e050263          	beqz	a0,ffffffffc0202a92 <tree_buddy_check+0x588>
    assert(a + 8 <= b || b + 4 <= a);
ffffffffc02027b2:	140a0793          	addi	a5,s4,320 # 1140 <kern_entry-0xffffffffc01feec0>
ffffffffc02027b6:	00f97663          	bgeu	s2,a5,ffffffffc02027c2 <tree_buddy_check+0x2b8>
ffffffffc02027ba:	0a090713          	addi	a4,s2,160
ffffffffc02027be:	28ea6a63          	bltu	s4,a4,ffffffffc0202a52 <tree_buddy_check+0x548>
    assert(a + 8 <= c || c + 1 <= a);
ffffffffc02027c2:	00f9f663          	bgeu	s3,a5,ffffffffc02027ce <tree_buddy_check+0x2c4>
ffffffffc02027c6:	02898793          	addi	a5,s3,40
ffffffffc02027ca:	2afa6463          	bltu	s4,a5,ffffffffc0202a72 <tree_buddy_check+0x568>
    assert(b + 4 <= c || c + 1 <= b);
ffffffffc02027ce:	0a090793          	addi	a5,s2,160
ffffffffc02027d2:	0af9ec63          	bltu	s3,a5,ffffffffc020288a <tree_buddy_check+0x380>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02027d6:	00016797          	auipc	a5,0x16
ffffffffc02027da:	9f27b783          	ld	a5,-1550(a5) # ffffffffc02181c8 <pages>
ffffffffc02027de:	40fa0733          	sub	a4,s4,a5
ffffffffc02027e2:	870d                	srai	a4,a4,0x3
ffffffffc02027e4:	00002617          	auipc	a2,0x2
ffffffffc02027e8:	ea463603          	ld	a2,-348(a2) # ffffffffc0204688 <nbase+0x8>
ffffffffc02027ec:	02c70733          	mul	a4,a4,a2
ffffffffc02027f0:	00002697          	auipc	a3,0x2
ffffffffc02027f4:	e906b683          	ld	a3,-368(a3) # ffffffffc0204680 <nbase>
ffffffffc02027f8:	9736                	add	a4,a4,a3
    assert((page2ppn(a) & 7) == 0);
ffffffffc02027fa:	8b1d                	andi	a4,a4,7
ffffffffc02027fc:	22071b63          	bnez	a4,ffffffffc0202a32 <tree_buddy_check+0x528>
ffffffffc0202800:	40f907b3          	sub	a5,s2,a5
ffffffffc0202804:	878d                	srai	a5,a5,0x3
ffffffffc0202806:	02c787b3          	mul	a5,a5,a2
ffffffffc020280a:	97b6                	add	a5,a5,a3
    assert((page2ppn(b) & 3) == 0);
ffffffffc020280c:	8b8d                	andi	a5,a5,3
ffffffffc020280e:	32079263          	bnez	a5,ffffffffc0202b32 <tree_buddy_check+0x628>
    assert(tree_free_count == before - 13);
ffffffffc0202812:	609c                	ld	a5,0(s1)
ffffffffc0202814:	ff340713          	addi	a4,s0,-13
ffffffffc0202818:	32f71d63          	bne	a4,a5,ffffffffc0202b52 <tree_buddy_check+0x648>
    tree_buddy_free_pages(a, 5);
ffffffffc020281c:	4595                	li	a1,5
ffffffffc020281e:	8552                	mv	a0,s4
ffffffffc0202820:	971ff0ef          	jal	ra,ffffffffc0202190 <tree_buddy_free_pages>
    tree_buddy_free_pages(b, 3);
ffffffffc0202824:	458d                	li	a1,3
ffffffffc0202826:	854a                	mv	a0,s2
ffffffffc0202828:	969ff0ef          	jal	ra,ffffffffc0202190 <tree_buddy_free_pages>
    tree_buddy_free_pages(c, 1);
ffffffffc020282c:	4585                	li	a1,1
ffffffffc020282e:	854e                	mv	a0,s3
ffffffffc0202830:	961ff0ef          	jal	ra,ffffffffc0202190 <tree_buddy_free_pages>
    assert(tree_free_count == before);
ffffffffc0202834:	609c                	ld	a5,0(s1)
ffffffffc0202836:	32879e63          	bne	a5,s0,ffffffffc0202b72 <tree_buddy_check+0x668>
    assert(tree_count_free(tree_nodes, 1, TREE_PAGES) == before);
ffffffffc020283a:	6621                	lui	a2,0x8
ffffffffc020283c:	4585                	li	a1,1
ffffffffc020283e:	00006517          	auipc	a0,0x6
ffffffffc0202842:	96a50513          	addi	a0,a0,-1686 # ffffffffc02081a8 <tree_nodes>
ffffffffc0202846:	871ff0ef          	jal	ra,ffffffffc02020b6 <tree_count_free>
ffffffffc020284a:	38851463          	bne	a0,s0,ffffffffc0202bd2 <tree_buddy_check+0x6c8>
    cprintf("tree_buddy_check() succeeded!\n");
ffffffffc020284e:	00002517          	auipc	a0,0x2
ffffffffc0202852:	b5a50513          	addi	a0,a0,-1190 # ffffffffc02043a8 <slub_sizes+0x770>
ffffffffc0202856:	90bfd0ef          	jal	ra,ffffffffc0200160 <cprintf>
}
ffffffffc020285a:	60e6                	ld	ra,88(sp)
ffffffffc020285c:	6446                	ld	s0,80(sp)
ffffffffc020285e:	64a6                	ld	s1,72(sp)
ffffffffc0202860:	6906                	ld	s2,64(sp)
ffffffffc0202862:	79e2                	ld	s3,56(sp)
ffffffffc0202864:	7a42                	ld	s4,48(sp)
ffffffffc0202866:	6125                	addi	sp,sp,96
ffffffffc0202868:	8082                	ret
    assert(before >= 13 && tree_round_up(3) == 4 && tree_round_up(5) == 8);
ffffffffc020286a:	00002697          	auipc	a3,0x2
ffffffffc020286e:	9ce68693          	addi	a3,a3,-1586 # ffffffffc0204238 <slub_sizes+0x600>
ffffffffc0202872:	00001617          	auipc	a2,0x1
ffffffffc0202876:	cd660613          	addi	a2,a2,-810 # ffffffffc0203548 <etext+0x434>
ffffffffc020287a:	0f800593          	li	a1,248
ffffffffc020287e:	00001517          	auipc	a0,0x1
ffffffffc0202882:	42a50513          	addi	a0,a0,1066 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202886:	951fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(b + 4 <= c || c + 1 <= b);
ffffffffc020288a:	02898793          	addi	a5,s3,40
ffffffffc020288e:	f4f974e3          	bgeu	s2,a5,ffffffffc02027d6 <tree_buddy_check+0x2cc>
ffffffffc0202892:	00002697          	auipc	a3,0x2
ffffffffc0202896:	a4e68693          	addi	a3,a3,-1458 # ffffffffc02042e0 <slub_sizes+0x6a8>
ffffffffc020289a:	00001617          	auipc	a2,0x1
ffffffffc020289e:	cae60613          	addi	a2,a2,-850 # ffffffffc0203548 <etext+0x434>
ffffffffc02028a2:	0ff00593          	li	a1,255
ffffffffc02028a6:	00001517          	auipc	a0,0x1
ffffffffc02028aa:	40250513          	addi	a0,a0,1026 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02028ae:	929fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(tree_allocate(small, 1, 0, 16, 4, &first));
ffffffffc02028b2:	00002697          	auipc	a3,0x2
ffffffffc02028b6:	8ae68693          	addi	a3,a3,-1874 # ffffffffc0204160 <slub_sizes+0x528>
ffffffffc02028ba:	00001617          	auipc	a2,0x1
ffffffffc02028be:	c8e60613          	addi	a2,a2,-882 # ffffffffc0203548 <etext+0x434>
ffffffffc02028c2:	0e900593          	li	a1,233
ffffffffc02028c6:	00001517          	auipc	a0,0x1
ffffffffc02028ca:	3e250513          	addi	a0,a0,994 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02028ce:	909fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
        assert(first == 4 * i);
ffffffffc02028d2:	00002697          	auipc	a3,0x2
ffffffffc02028d6:	8be68693          	addi	a3,a3,-1858 # ffffffffc0204190 <slub_sizes+0x558>
ffffffffc02028da:	00001617          	auipc	a2,0x1
ffffffffc02028de:	c6e60613          	addi	a2,a2,-914 # ffffffffc0203548 <etext+0x434>
ffffffffc02028e2:	0ea00593          	li	a1,234
ffffffffc02028e6:	00001517          	auipc	a0,0x1
ffffffffc02028ea:	3c250513          	addi	a0,a0,962 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02028ee:	8e9fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(!tree_allocate(small, 1, 0, 16, 16, &first));
ffffffffc02028f2:	00001697          	auipc	a3,0x1
ffffffffc02028f6:	6be68693          	addi	a3,a3,1726 # ffffffffc0203fb0 <slub_sizes+0x378>
ffffffffc02028fa:	00001617          	auipc	a2,0x1
ffffffffc02028fe:	c4e60613          	addi	a2,a2,-946 # ffffffffc0203548 <etext+0x434>
ffffffffc0202902:	0d200593          	li	a1,210
ffffffffc0202906:	00001517          	auipc	a0,0x1
ffffffffc020290a:	3a250513          	addi	a0,a0,930 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc020290e:	8c9fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_allocate(small, 1, 0, 16, 4, &first) && first == 8);
ffffffffc0202912:	00001697          	auipc	a3,0x1
ffffffffc0202916:	70668693          	addi	a3,a3,1798 # ffffffffc0204018 <slub_sizes+0x3e0>
ffffffffc020291a:	00001617          	auipc	a2,0x1
ffffffffc020291e:	c2e60613          	addi	a2,a2,-978 # ffffffffc0203548 <etext+0x434>
ffffffffc0202922:	0d400593          	li	a1,212
ffffffffc0202926:	00001517          	auipc	a0,0x1
ffffffffc020292a:	38250513          	addi	a0,a0,898 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc020292e:	8a9fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_allocate(small, 1, 0, 16, 8, &first) && first == 0);
ffffffffc0202932:	00001697          	auipc	a3,0x1
ffffffffc0202936:	6ae68693          	addi	a3,a3,1710 # ffffffffc0203fe0 <slub_sizes+0x3a8>
ffffffffc020293a:	00001617          	auipc	a2,0x1
ffffffffc020293e:	c0e60613          	addi	a2,a2,-1010 # ffffffffc0203548 <etext+0x434>
ffffffffc0202942:	0d300593          	li	a1,211
ffffffffc0202946:	00001517          	auipc	a0,0x1
ffffffffc020294a:	36250513          	addi	a0,a0,866 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc020294e:	889fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(!tree_allocate(small, 1, 0, 16, 8, &first));
ffffffffc0202952:	00002697          	auipc	a3,0x2
ffffffffc0202956:	84e68693          	addi	a3,a3,-1970 # ffffffffc02041a0 <slub_sizes+0x568>
ffffffffc020295a:	00001617          	auipc	a2,0x1
ffffffffc020295e:	bee60613          	addi	a2,a2,-1042 # ffffffffc0203548 <etext+0x434>
ffffffffc0202962:	0ee00593          	li	a1,238
ffffffffc0202966:	00001517          	auipc	a0,0x1
ffffffffc020296a:	34250513          	addi	a0,a0,834 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc020296e:	869fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_count_free(small, 1, 16) == 16);
ffffffffc0202972:	00002697          	auipc	a3,0x2
ffffffffc0202976:	89e68693          	addi	a3,a3,-1890 # ffffffffc0204210 <slub_sizes+0x5d8>
ffffffffc020297a:	00001617          	auipc	a2,0x1
ffffffffc020297e:	bce60613          	addi	a2,a2,-1074 # ffffffffc0203548 <etext+0x434>
ffffffffc0202982:	0f500593          	li	a1,245
ffffffffc0202986:	00001517          	auipc	a0,0x1
ffffffffc020298a:	32250513          	addi	a0,a0,802 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc020298e:	849fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(small[1] == TREE_FREE);
ffffffffc0202992:	00002697          	auipc	a3,0x2
ffffffffc0202996:	86668693          	addi	a3,a3,-1946 # ffffffffc02041f8 <slub_sizes+0x5c0>
ffffffffc020299a:	00001617          	auipc	a2,0x1
ffffffffc020299e:	bae60613          	addi	a2,a2,-1106 # ffffffffc0203548 <etext+0x434>
ffffffffc02029a2:	0f400593          	li	a1,244
ffffffffc02029a6:	00001517          	auipc	a0,0x1
ffffffffc02029aa:	30250513          	addi	a0,a0,770 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02029ae:	829fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_allocate(small, 1, 0, 16, 8, &first) && first == 0);
ffffffffc02029b2:	00001697          	auipc	a3,0x1
ffffffffc02029b6:	62e68693          	addi	a3,a3,1582 # ffffffffc0203fe0 <slub_sizes+0x3a8>
ffffffffc02029ba:	00001617          	auipc	a2,0x1
ffffffffc02029be:	b8e60613          	addi	a2,a2,-1138 # ffffffffc0203548 <etext+0x434>
ffffffffc02029c2:	0f100593          	li	a1,241
ffffffffc02029c6:	00001517          	auipc	a0,0x1
ffffffffc02029ca:	2e250513          	addi	a0,a0,738 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02029ce:	809fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_count_free(small, 1, 16) == 8);
ffffffffc02029d2:	00001697          	auipc	a3,0x1
ffffffffc02029d6:	7fe68693          	addi	a3,a3,2046 # ffffffffc02041d0 <slub_sizes+0x598>
ffffffffc02029da:	00001617          	auipc	a2,0x1
ffffffffc02029de:	b6e60613          	addi	a2,a2,-1170 # ffffffffc0203548 <etext+0x434>
ffffffffc02029e2:	0ef00593          	li	a1,239
ffffffffc02029e6:	00001517          	auipc	a0,0x1
ffffffffc02029ea:	2c250513          	addi	a0,a0,706 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc02029ee:	fe8fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_allocate(small, 1, 0, 16, 1, &first) && first == 3);
ffffffffc02029f2:	00001697          	auipc	a3,0x1
ffffffffc02029f6:	73668693          	addi	a3,a3,1846 # ffffffffc0204128 <slub_sizes+0x4f0>
ffffffffc02029fa:	00001617          	auipc	a2,0x1
ffffffffc02029fe:	b4e60613          	addi	a2,a2,-1202 # ffffffffc0203548 <etext+0x434>
ffffffffc0202a02:	0e200593          	li	a1,226
ffffffffc0202a06:	00001517          	auipc	a0,0x1
ffffffffc0202a0a:	2a250513          	addi	a0,a0,674 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202a0e:	fc8fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_allocate(small, 1, 0, 16, 4, &first) && first == 4);
ffffffffc0202a12:	00001697          	auipc	a3,0x1
ffffffffc0202a16:	6de68693          	addi	a3,a3,1758 # ffffffffc02040f0 <slub_sizes+0x4b8>
ffffffffc0202a1a:	00001617          	auipc	a2,0x1
ffffffffc0202a1e:	b2e60613          	addi	a2,a2,-1234 # ffffffffc0203548 <etext+0x434>
ffffffffc0202a22:	0e100593          	li	a1,225
ffffffffc0202a26:	00001517          	auipc	a0,0x1
ffffffffc0202a2a:	28250513          	addi	a0,a0,642 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202a2e:	fa8fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((page2ppn(a) & 7) == 0);
ffffffffc0202a32:	00002697          	auipc	a3,0x2
ffffffffc0202a36:	8ce68693          	addi	a3,a3,-1842 # ffffffffc0204300 <slub_sizes+0x6c8>
ffffffffc0202a3a:	00001617          	auipc	a2,0x1
ffffffffc0202a3e:	b0e60613          	addi	a2,a2,-1266 # ffffffffc0203548 <etext+0x434>
ffffffffc0202a42:	10000593          	li	a1,256
ffffffffc0202a46:	00001517          	auipc	a0,0x1
ffffffffc0202a4a:	26250513          	addi	a0,a0,610 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202a4e:	f88fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(a + 8 <= b || b + 4 <= a);
ffffffffc0202a52:	00002697          	auipc	a3,0x2
ffffffffc0202a56:	84e68693          	addi	a3,a3,-1970 # ffffffffc02042a0 <slub_sizes+0x668>
ffffffffc0202a5a:	00001617          	auipc	a2,0x1
ffffffffc0202a5e:	aee60613          	addi	a2,a2,-1298 # ffffffffc0203548 <etext+0x434>
ffffffffc0202a62:	0fd00593          	li	a1,253
ffffffffc0202a66:	00001517          	auipc	a0,0x1
ffffffffc0202a6a:	24250513          	addi	a0,a0,578 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202a6e:	f68fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(a + 8 <= c || c + 1 <= a);
ffffffffc0202a72:	00002697          	auipc	a3,0x2
ffffffffc0202a76:	84e68693          	addi	a3,a3,-1970 # ffffffffc02042c0 <slub_sizes+0x688>
ffffffffc0202a7a:	00001617          	auipc	a2,0x1
ffffffffc0202a7e:	ace60613          	addi	a2,a2,-1330 # ffffffffc0203548 <etext+0x434>
ffffffffc0202a82:	0fe00593          	li	a1,254
ffffffffc0202a86:	00001517          	auipc	a0,0x1
ffffffffc0202a8a:	22250513          	addi	a0,a0,546 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202a8e:	f48fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(a != NULL && b != NULL && c != NULL);
ffffffffc0202a92:	00001697          	auipc	a3,0x1
ffffffffc0202a96:	7e668693          	addi	a3,a3,2022 # ffffffffc0204278 <slub_sizes+0x640>
ffffffffc0202a9a:	00001617          	auipc	a2,0x1
ffffffffc0202a9e:	aae60613          	addi	a2,a2,-1362 # ffffffffc0203548 <etext+0x434>
ffffffffc0202aa2:	0fc00593          	li	a1,252
ffffffffc0202aa6:	00001517          	auipc	a0,0x1
ffffffffc0202aaa:	20250513          	addi	a0,a0,514 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202aae:	f28fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_count_free(small, 1, 16) == 13);
ffffffffc0202ab2:	00001697          	auipc	a3,0x1
ffffffffc0202ab6:	4d668693          	addi	a3,a3,1238 # ffffffffc0203f88 <slub_sizes+0x350>
ffffffffc0202aba:	00001617          	auipc	a2,0x1
ffffffffc0202abe:	a8e60613          	addi	a2,a2,-1394 # ffffffffc0203548 <etext+0x434>
ffffffffc0202ac2:	0df00593          	li	a1,223
ffffffffc0202ac6:	00001517          	auipc	a0,0x1
ffffffffc0202aca:	1e250513          	addi	a0,a0,482 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202ace:	f08fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_count_free(small, 1, 16) == 13);
ffffffffc0202ad2:	00001697          	auipc	a3,0x1
ffffffffc0202ad6:	4b668693          	addi	a3,a3,1206 # ffffffffc0203f88 <slub_sizes+0x350>
ffffffffc0202ada:	00001617          	auipc	a2,0x1
ffffffffc0202ade:	a6e60613          	addi	a2,a2,-1426 # ffffffffc0203548 <etext+0x434>
ffffffffc0202ae2:	0da00593          	li	a1,218
ffffffffc0202ae6:	00001517          	auipc	a0,0x1
ffffffffc0202aea:	1c250513          	addi	a0,a0,450 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202aee:	ee8fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_count_free(small, 1, 16) == 0);
ffffffffc0202af2:	00001697          	auipc	a3,0x1
ffffffffc0202af6:	59e68693          	addi	a3,a3,1438 # ffffffffc0204090 <slub_sizes+0x458>
ffffffffc0202afa:	00001617          	auipc	a2,0x1
ffffffffc0202afe:	a4e60613          	addi	a2,a2,-1458 # ffffffffc0203548 <etext+0x434>
ffffffffc0202b02:	0d600593          	li	a1,214
ffffffffc0202b06:	00001517          	auipc	a0,0x1
ffffffffc0202b0a:	1a250513          	addi	a0,a0,418 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202b0e:	ec8fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_allocate(small, 1, 0, 16, 1, &first) && first == 12);
ffffffffc0202b12:	00001697          	auipc	a3,0x1
ffffffffc0202b16:	53e68693          	addi	a3,a3,1342 # ffffffffc0204050 <slub_sizes+0x418>
ffffffffc0202b1a:	00001617          	auipc	a2,0x1
ffffffffc0202b1e:	a2e60613          	addi	a2,a2,-1490 # ffffffffc0203548 <etext+0x434>
ffffffffc0202b22:	0d500593          	li	a1,213
ffffffffc0202b26:	00001517          	auipc	a0,0x1
ffffffffc0202b2a:	18250513          	addi	a0,a0,386 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202b2e:	ea8fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert((page2ppn(b) & 3) == 0);
ffffffffc0202b32:	00001697          	auipc	a3,0x1
ffffffffc0202b36:	7e668693          	addi	a3,a3,2022 # ffffffffc0204318 <slub_sizes+0x6e0>
ffffffffc0202b3a:	00001617          	auipc	a2,0x1
ffffffffc0202b3e:	a0e60613          	addi	a2,a2,-1522 # ffffffffc0203548 <etext+0x434>
ffffffffc0202b42:	10100593          	li	a1,257
ffffffffc0202b46:	00001517          	auipc	a0,0x1
ffffffffc0202b4a:	16250513          	addi	a0,a0,354 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202b4e:	e88fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_free_count == before - 13);
ffffffffc0202b52:	00001697          	auipc	a3,0x1
ffffffffc0202b56:	7de68693          	addi	a3,a3,2014 # ffffffffc0204330 <slub_sizes+0x6f8>
ffffffffc0202b5a:	00001617          	auipc	a2,0x1
ffffffffc0202b5e:	9ee60613          	addi	a2,a2,-1554 # ffffffffc0203548 <etext+0x434>
ffffffffc0202b62:	10200593          	li	a1,258
ffffffffc0202b66:	00001517          	auipc	a0,0x1
ffffffffc0202b6a:	14250513          	addi	a0,a0,322 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202b6e:	e68fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_free_count == before);
ffffffffc0202b72:	00001697          	auipc	a3,0x1
ffffffffc0202b76:	7de68693          	addi	a3,a3,2014 # ffffffffc0204350 <slub_sizes+0x718>
ffffffffc0202b7a:	00001617          	auipc	a2,0x1
ffffffffc0202b7e:	9ce60613          	addi	a2,a2,-1586 # ffffffffc0203548 <etext+0x434>
ffffffffc0202b82:	10600593          	li	a1,262
ffffffffc0202b86:	00001517          	auipc	a0,0x1
ffffffffc0202b8a:	12250513          	addi	a0,a0,290 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202b8e:	e48fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_count_free(small, 1, 16) == 13);
ffffffffc0202b92:	00001697          	auipc	a3,0x1
ffffffffc0202b96:	3f668693          	addi	a3,a3,1014 # ffffffffc0203f88 <slub_sizes+0x350>
ffffffffc0202b9a:	00001617          	auipc	a2,0x1
ffffffffc0202b9e:	9ae60613          	addi	a2,a2,-1618 # ffffffffc0203548 <etext+0x434>
ffffffffc0202ba2:	0d100593          	li	a1,209
ffffffffc0202ba6:	00001517          	auipc	a0,0x1
ffffffffc0202baa:	10250513          	addi	a0,a0,258 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202bae:	e28fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_count_free(tree_nodes, 1, TREE_PAGES) == tree_free_count);
ffffffffc0202bb2:	00001697          	auipc	a3,0x1
ffffffffc0202bb6:	39668693          	addi	a3,a3,918 # ffffffffc0203f48 <slub_sizes+0x310>
ffffffffc0202bba:	00001617          	auipc	a2,0x1
ffffffffc0202bbe:	98e60613          	addi	a2,a2,-1650 # ffffffffc0203548 <etext+0x434>
ffffffffc0202bc2:	0cb00593          	li	a1,203
ffffffffc0202bc6:	00001517          	auipc	a0,0x1
ffffffffc0202bca:	0e250513          	addi	a0,a0,226 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202bce:	e08fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_count_free(tree_nodes, 1, TREE_PAGES) == before);
ffffffffc0202bd2:	00001697          	auipc	a3,0x1
ffffffffc0202bd6:	79e68693          	addi	a3,a3,1950 # ffffffffc0204370 <slub_sizes+0x738>
ffffffffc0202bda:	00001617          	auipc	a2,0x1
ffffffffc0202bde:	96e60613          	addi	a2,a2,-1682 # ffffffffc0203548 <etext+0x434>
ffffffffc0202be2:	10700593          	li	a1,263
ffffffffc0202be6:	00001517          	auipc	a0,0x1
ffffffffc0202bea:	0c250513          	addi	a0,a0,194 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202bee:	de8fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_count_free(small, 1, 16) == 0);
ffffffffc0202bf2:	00001697          	auipc	a3,0x1
ffffffffc0202bf6:	49e68693          	addi	a3,a3,1182 # ffffffffc0204090 <slub_sizes+0x458>
ffffffffc0202bfa:	00001617          	auipc	a2,0x1
ffffffffc0202bfe:	94e60613          	addi	a2,a2,-1714 # ffffffffc0203548 <etext+0x434>
ffffffffc0202c02:	0e300593          	li	a1,227
ffffffffc0202c06:	00001517          	auipc	a0,0x1
ffffffffc0202c0a:	0a250513          	addi	a0,a0,162 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202c0e:	dc8fd0ef          	jal	ra,ffffffffc02001d6 <__panic>
    assert(tree_allocate(small, 1, 0, 16, 8, &first) && first == 8);
ffffffffc0202c12:	00001697          	auipc	a3,0x1
ffffffffc0202c16:	4a668693          	addi	a3,a3,1190 # ffffffffc02040b8 <slub_sizes+0x480>
ffffffffc0202c1a:	00001617          	auipc	a2,0x1
ffffffffc0202c1e:	92e60613          	addi	a2,a2,-1746 # ffffffffc0203548 <etext+0x434>
ffffffffc0202c22:	0e000593          	li	a1,224
ffffffffc0202c26:	00001517          	auipc	a0,0x1
ffffffffc0202c2a:	08250513          	addi	a0,a0,130 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202c2e:	da8fd0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0202c32 <tree_buddy_init>:
tree_buddy_init(void) {
ffffffffc0202c32:	1141                	addi	sp,sp,-16
    assert((nbase & (TREE_PAGES - 1)) == 0);
ffffffffc0202c34:	00002797          	auipc	a5,0x2
ffffffffc0202c38:	a4c7b783          	ld	a5,-1460(a5) # ffffffffc0204680 <nbase>
tree_buddy_init(void) {
ffffffffc0202c3c:	e406                	sd	ra,8(sp)
    assert((nbase & (TREE_PAGES - 1)) == 0);
ffffffffc0202c3e:	17c6                	slli	a5,a5,0x31
ffffffffc0202c40:	e385                	bnez	a5,ffffffffc0202c60 <tree_buddy_init+0x2e>
    memset(tree_nodes, TREE_UNAVAILABLE, sizeof(tree_nodes));
ffffffffc0202c42:	6641                	lui	a2,0x10
ffffffffc0202c44:	4581                	li	a1,0
ffffffffc0202c46:	00005517          	auipc	a0,0x5
ffffffffc0202c4a:	56250513          	addi	a0,a0,1378 # ffffffffc02081a8 <tree_nodes>
ffffffffc0202c4e:	4b4000ef          	jal	ra,ffffffffc0203102 <memset>
}
ffffffffc0202c52:	60a2                	ld	ra,8(sp)
    tree_free_count = 0;
ffffffffc0202c54:	00015797          	auipc	a5,0x15
ffffffffc0202c58:	5a07b223          	sd	zero,1444(a5) # ffffffffc02181f8 <tree_free_count>
}
ffffffffc0202c5c:	0141                	addi	sp,sp,16
ffffffffc0202c5e:	8082                	ret
    assert((nbase & (TREE_PAGES - 1)) == 0);
ffffffffc0202c60:	00001697          	auipc	a3,0x1
ffffffffc0202c64:	76868693          	addi	a3,a3,1896 # ffffffffc02043c8 <slub_sizes+0x790>
ffffffffc0202c68:	00001617          	auipc	a2,0x1
ffffffffc0202c6c:	8e060613          	addi	a2,a2,-1824 # ffffffffc0203548 <etext+0x434>
ffffffffc0202c70:	08b00593          	li	a1,139
ffffffffc0202c74:	00001517          	auipc	a0,0x1
ffffffffc0202c78:	03450513          	addi	a0,a0,52 # ffffffffc0203ca8 <slub_sizes+0x70>
ffffffffc0202c7c:	d5afd0ef          	jal	ra,ffffffffc02001d6 <__panic>

ffffffffc0202c80 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0202c80:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202c84:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0202c86:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202c8a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0202c8c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202c90:	f022                	sd	s0,32(sp)
ffffffffc0202c92:	ec26                	sd	s1,24(sp)
ffffffffc0202c94:	e84a                	sd	s2,16(sp)
ffffffffc0202c96:	f406                	sd	ra,40(sp)
ffffffffc0202c98:	e44e                	sd	s3,8(sp)
ffffffffc0202c9a:	84aa                	mv	s1,a0
ffffffffc0202c9c:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0202c9e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0202ca2:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0202ca4:	03067e63          	bgeu	a2,a6,ffffffffc0202ce0 <printnum+0x60>
ffffffffc0202ca8:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0202caa:	00805763          	blez	s0,ffffffffc0202cb8 <printnum+0x38>
ffffffffc0202cae:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0202cb0:	85ca                	mv	a1,s2
ffffffffc0202cb2:	854e                	mv	a0,s3
ffffffffc0202cb4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0202cb6:	fc65                	bnez	s0,ffffffffc0202cae <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202cb8:	1a02                	slli	s4,s4,0x20
ffffffffc0202cba:	00001797          	auipc	a5,0x1
ffffffffc0202cbe:	77e78793          	addi	a5,a5,1918 # ffffffffc0204438 <tree_buddy_pmm_manager+0x38>
ffffffffc0202cc2:	020a5a13          	srli	s4,s4,0x20
ffffffffc0202cc6:	9a3e                	add	s4,s4,a5
}
ffffffffc0202cc8:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202cca:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0202cce:	70a2                	ld	ra,40(sp)
ffffffffc0202cd0:	69a2                	ld	s3,8(sp)
ffffffffc0202cd2:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202cd4:	85ca                	mv	a1,s2
ffffffffc0202cd6:	87a6                	mv	a5,s1
}
ffffffffc0202cd8:	6942                	ld	s2,16(sp)
ffffffffc0202cda:	64e2                	ld	s1,24(sp)
ffffffffc0202cdc:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202cde:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0202ce0:	03065633          	divu	a2,a2,a6
ffffffffc0202ce4:	8722                	mv	a4,s0
ffffffffc0202ce6:	f9bff0ef          	jal	ra,ffffffffc0202c80 <printnum>
ffffffffc0202cea:	b7f9                	j	ffffffffc0202cb8 <printnum+0x38>

ffffffffc0202cec <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0202cec:	7119                	addi	sp,sp,-128
ffffffffc0202cee:	f4a6                	sd	s1,104(sp)
ffffffffc0202cf0:	f0ca                	sd	s2,96(sp)
ffffffffc0202cf2:	ecce                	sd	s3,88(sp)
ffffffffc0202cf4:	e8d2                	sd	s4,80(sp)
ffffffffc0202cf6:	e4d6                	sd	s5,72(sp)
ffffffffc0202cf8:	e0da                	sd	s6,64(sp)
ffffffffc0202cfa:	fc5e                	sd	s7,56(sp)
ffffffffc0202cfc:	f06a                	sd	s10,32(sp)
ffffffffc0202cfe:	fc86                	sd	ra,120(sp)
ffffffffc0202d00:	f8a2                	sd	s0,112(sp)
ffffffffc0202d02:	f862                	sd	s8,48(sp)
ffffffffc0202d04:	f466                	sd	s9,40(sp)
ffffffffc0202d06:	ec6e                	sd	s11,24(sp)
ffffffffc0202d08:	892a                	mv	s2,a0
ffffffffc0202d0a:	84ae                	mv	s1,a1
ffffffffc0202d0c:	8d32                	mv	s10,a2
ffffffffc0202d0e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202d10:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0202d14:	5b7d                	li	s6,-1
ffffffffc0202d16:	00001a97          	auipc	s5,0x1
ffffffffc0202d1a:	756a8a93          	addi	s5,s5,1878 # ffffffffc020446c <tree_buddy_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202d1e:	00002b97          	auipc	s7,0x2
ffffffffc0202d22:	92ab8b93          	addi	s7,s7,-1750 # ffffffffc0204648 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202d26:	000d4503          	lbu	a0,0(s10)
ffffffffc0202d2a:	001d0413          	addi	s0,s10,1
ffffffffc0202d2e:	01350a63          	beq	a0,s3,ffffffffc0202d42 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0202d32:	c121                	beqz	a0,ffffffffc0202d72 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0202d34:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202d36:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0202d38:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202d3a:	fff44503          	lbu	a0,-1(s0)
ffffffffc0202d3e:	ff351ae3          	bne	a0,s3,ffffffffc0202d32 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202d42:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0202d46:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0202d4a:	4c81                	li	s9,0
ffffffffc0202d4c:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0202d4e:	5c7d                	li	s8,-1
ffffffffc0202d50:	5dfd                	li	s11,-1
ffffffffc0202d52:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0202d56:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202d58:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0202d5c:	0ff5f593          	zext.b	a1,a1
ffffffffc0202d60:	00140d13          	addi	s10,s0,1
ffffffffc0202d64:	04b56263          	bltu	a0,a1,ffffffffc0202da8 <vprintfmt+0xbc>
ffffffffc0202d68:	058a                	slli	a1,a1,0x2
ffffffffc0202d6a:	95d6                	add	a1,a1,s5
ffffffffc0202d6c:	4194                	lw	a3,0(a1)
ffffffffc0202d6e:	96d6                	add	a3,a3,s5
ffffffffc0202d70:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0202d72:	70e6                	ld	ra,120(sp)
ffffffffc0202d74:	7446                	ld	s0,112(sp)
ffffffffc0202d76:	74a6                	ld	s1,104(sp)
ffffffffc0202d78:	7906                	ld	s2,96(sp)
ffffffffc0202d7a:	69e6                	ld	s3,88(sp)
ffffffffc0202d7c:	6a46                	ld	s4,80(sp)
ffffffffc0202d7e:	6aa6                	ld	s5,72(sp)
ffffffffc0202d80:	6b06                	ld	s6,64(sp)
ffffffffc0202d82:	7be2                	ld	s7,56(sp)
ffffffffc0202d84:	7c42                	ld	s8,48(sp)
ffffffffc0202d86:	7ca2                	ld	s9,40(sp)
ffffffffc0202d88:	7d02                	ld	s10,32(sp)
ffffffffc0202d8a:	6de2                	ld	s11,24(sp)
ffffffffc0202d8c:	6109                	addi	sp,sp,128
ffffffffc0202d8e:	8082                	ret
            padc = '0';
ffffffffc0202d90:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0202d92:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202d96:	846a                	mv	s0,s10
ffffffffc0202d98:	00140d13          	addi	s10,s0,1
ffffffffc0202d9c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0202da0:	0ff5f593          	zext.b	a1,a1
ffffffffc0202da4:	fcb572e3          	bgeu	a0,a1,ffffffffc0202d68 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0202da8:	85a6                	mv	a1,s1
ffffffffc0202daa:	02500513          	li	a0,37
ffffffffc0202dae:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0202db0:	fff44783          	lbu	a5,-1(s0)
ffffffffc0202db4:	8d22                	mv	s10,s0
ffffffffc0202db6:	f73788e3          	beq	a5,s3,ffffffffc0202d26 <vprintfmt+0x3a>
ffffffffc0202dba:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0202dbe:	1d7d                	addi	s10,s10,-1
ffffffffc0202dc0:	ff379de3          	bne	a5,s3,ffffffffc0202dba <vprintfmt+0xce>
ffffffffc0202dc4:	b78d                	j	ffffffffc0202d26 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0202dc6:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0202dca:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202dce:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0202dd0:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0202dd4:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0202dd8:	02d86463          	bltu	a6,a3,ffffffffc0202e00 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0202ddc:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0202de0:	002c169b          	slliw	a3,s8,0x2
ffffffffc0202de4:	0186873b          	addw	a4,a3,s8
ffffffffc0202de8:	0017171b          	slliw	a4,a4,0x1
ffffffffc0202dec:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0202dee:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0202df2:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0202df4:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0202df8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0202dfc:	fed870e3          	bgeu	a6,a3,ffffffffc0202ddc <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0202e00:	f40ddce3          	bgez	s11,ffffffffc0202d58 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0202e04:	8de2                	mv	s11,s8
ffffffffc0202e06:	5c7d                	li	s8,-1
ffffffffc0202e08:	bf81                	j	ffffffffc0202d58 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0202e0a:	fffdc693          	not	a3,s11
ffffffffc0202e0e:	96fd                	srai	a3,a3,0x3f
ffffffffc0202e10:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202e14:	00144603          	lbu	a2,1(s0)
ffffffffc0202e18:	2d81                	sext.w	s11,s11
ffffffffc0202e1a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202e1c:	bf35                	j	ffffffffc0202d58 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0202e1e:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202e22:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0202e26:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202e28:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0202e2a:	bfd9                	j	ffffffffc0202e00 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0202e2c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202e2e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202e32:	01174463          	blt	a4,a7,ffffffffc0202e3a <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0202e36:	1a088e63          	beqz	a7,ffffffffc0202ff2 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0202e3a:	000a3603          	ld	a2,0(s4)
ffffffffc0202e3e:	46c1                	li	a3,16
ffffffffc0202e40:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0202e42:	2781                	sext.w	a5,a5
ffffffffc0202e44:	876e                	mv	a4,s11
ffffffffc0202e46:	85a6                	mv	a1,s1
ffffffffc0202e48:	854a                	mv	a0,s2
ffffffffc0202e4a:	e37ff0ef          	jal	ra,ffffffffc0202c80 <printnum>
            break;
ffffffffc0202e4e:	bde1                	j	ffffffffc0202d26 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0202e50:	000a2503          	lw	a0,0(s4)
ffffffffc0202e54:	85a6                	mv	a1,s1
ffffffffc0202e56:	0a21                	addi	s4,s4,8
ffffffffc0202e58:	9902                	jalr	s2
            break;
ffffffffc0202e5a:	b5f1                	j	ffffffffc0202d26 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0202e5c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202e5e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202e62:	01174463          	blt	a4,a7,ffffffffc0202e6a <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0202e66:	18088163          	beqz	a7,ffffffffc0202fe8 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0202e6a:	000a3603          	ld	a2,0(s4)
ffffffffc0202e6e:	46a9                	li	a3,10
ffffffffc0202e70:	8a2e                	mv	s4,a1
ffffffffc0202e72:	bfc1                	j	ffffffffc0202e42 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202e74:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0202e78:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202e7a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202e7c:	bdf1                	j	ffffffffc0202d58 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0202e7e:	85a6                	mv	a1,s1
ffffffffc0202e80:	02500513          	li	a0,37
ffffffffc0202e84:	9902                	jalr	s2
            break;
ffffffffc0202e86:	b545                	j	ffffffffc0202d26 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202e88:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0202e8c:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202e8e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202e90:	b5e1                	j	ffffffffc0202d58 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0202e92:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202e94:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202e98:	01174463          	blt	a4,a7,ffffffffc0202ea0 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0202e9c:	14088163          	beqz	a7,ffffffffc0202fde <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0202ea0:	000a3603          	ld	a2,0(s4)
ffffffffc0202ea4:	46a1                	li	a3,8
ffffffffc0202ea6:	8a2e                	mv	s4,a1
ffffffffc0202ea8:	bf69                	j	ffffffffc0202e42 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0202eaa:	03000513          	li	a0,48
ffffffffc0202eae:	85a6                	mv	a1,s1
ffffffffc0202eb0:	e03e                	sd	a5,0(sp)
ffffffffc0202eb2:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0202eb4:	85a6                	mv	a1,s1
ffffffffc0202eb6:	07800513          	li	a0,120
ffffffffc0202eba:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202ebc:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0202ebe:	6782                	ld	a5,0(sp)
ffffffffc0202ec0:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202ec2:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0202ec6:	bfb5                	j	ffffffffc0202e42 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202ec8:	000a3403          	ld	s0,0(s4)
ffffffffc0202ecc:	008a0713          	addi	a4,s4,8
ffffffffc0202ed0:	e03a                	sd	a4,0(sp)
ffffffffc0202ed2:	14040263          	beqz	s0,ffffffffc0203016 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0202ed6:	0fb05763          	blez	s11,ffffffffc0202fc4 <vprintfmt+0x2d8>
ffffffffc0202eda:	02d00693          	li	a3,45
ffffffffc0202ede:	0cd79163          	bne	a5,a3,ffffffffc0202fa0 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202ee2:	00044783          	lbu	a5,0(s0)
ffffffffc0202ee6:	0007851b          	sext.w	a0,a5
ffffffffc0202eea:	cf85                	beqz	a5,ffffffffc0202f22 <vprintfmt+0x236>
ffffffffc0202eec:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202ef0:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202ef4:	000c4563          	bltz	s8,ffffffffc0202efe <vprintfmt+0x212>
ffffffffc0202ef8:	3c7d                	addiw	s8,s8,-1
ffffffffc0202efa:	036c0263          	beq	s8,s6,ffffffffc0202f1e <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0202efe:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202f00:	0e0c8e63          	beqz	s9,ffffffffc0202ffc <vprintfmt+0x310>
ffffffffc0202f04:	3781                	addiw	a5,a5,-32
ffffffffc0202f06:	0ef47b63          	bgeu	s0,a5,ffffffffc0202ffc <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0202f0a:	03f00513          	li	a0,63
ffffffffc0202f0e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202f10:	000a4783          	lbu	a5,0(s4)
ffffffffc0202f14:	3dfd                	addiw	s11,s11,-1
ffffffffc0202f16:	0a05                	addi	s4,s4,1
ffffffffc0202f18:	0007851b          	sext.w	a0,a5
ffffffffc0202f1c:	ffe1                	bnez	a5,ffffffffc0202ef4 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0202f1e:	01b05963          	blez	s11,ffffffffc0202f30 <vprintfmt+0x244>
ffffffffc0202f22:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0202f24:	85a6                	mv	a1,s1
ffffffffc0202f26:	02000513          	li	a0,32
ffffffffc0202f2a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0202f2c:	fe0d9be3          	bnez	s11,ffffffffc0202f22 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202f30:	6a02                	ld	s4,0(sp)
ffffffffc0202f32:	bbd5                	j	ffffffffc0202d26 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0202f34:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202f36:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0202f3a:	01174463          	blt	a4,a7,ffffffffc0202f42 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0202f3e:	08088d63          	beqz	a7,ffffffffc0202fd8 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0202f42:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0202f46:	0a044d63          	bltz	s0,ffffffffc0203000 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0202f4a:	8622                	mv	a2,s0
ffffffffc0202f4c:	8a66                	mv	s4,s9
ffffffffc0202f4e:	46a9                	li	a3,10
ffffffffc0202f50:	bdcd                	j	ffffffffc0202e42 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0202f52:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202f56:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0202f58:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0202f5a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0202f5e:	8fb5                	xor	a5,a5,a3
ffffffffc0202f60:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202f64:	02d74163          	blt	a4,a3,ffffffffc0202f86 <vprintfmt+0x29a>
ffffffffc0202f68:	00369793          	slli	a5,a3,0x3
ffffffffc0202f6c:	97de                	add	a5,a5,s7
ffffffffc0202f6e:	639c                	ld	a5,0(a5)
ffffffffc0202f70:	cb99                	beqz	a5,ffffffffc0202f86 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0202f72:	86be                	mv	a3,a5
ffffffffc0202f74:	00001617          	auipc	a2,0x1
ffffffffc0202f78:	4f460613          	addi	a2,a2,1268 # ffffffffc0204468 <tree_buddy_pmm_manager+0x68>
ffffffffc0202f7c:	85a6                	mv	a1,s1
ffffffffc0202f7e:	854a                	mv	a0,s2
ffffffffc0202f80:	0ce000ef          	jal	ra,ffffffffc020304e <printfmt>
ffffffffc0202f84:	b34d                	j	ffffffffc0202d26 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0202f86:	00001617          	auipc	a2,0x1
ffffffffc0202f8a:	4d260613          	addi	a2,a2,1234 # ffffffffc0204458 <tree_buddy_pmm_manager+0x58>
ffffffffc0202f8e:	85a6                	mv	a1,s1
ffffffffc0202f90:	854a                	mv	a0,s2
ffffffffc0202f92:	0bc000ef          	jal	ra,ffffffffc020304e <printfmt>
ffffffffc0202f96:	bb41                	j	ffffffffc0202d26 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0202f98:	00001417          	auipc	s0,0x1
ffffffffc0202f9c:	4b840413          	addi	s0,s0,1208 # ffffffffc0204450 <tree_buddy_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202fa0:	85e2                	mv	a1,s8
ffffffffc0202fa2:	8522                	mv	a0,s0
ffffffffc0202fa4:	e43e                	sd	a5,8(sp)
ffffffffc0202fa6:	0fc000ef          	jal	ra,ffffffffc02030a2 <strnlen>
ffffffffc0202faa:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0202fae:	01b05b63          	blez	s11,ffffffffc0202fc4 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0202fb2:	67a2                	ld	a5,8(sp)
ffffffffc0202fb4:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202fb8:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0202fba:	85a6                	mv	a1,s1
ffffffffc0202fbc:	8552                	mv	a0,s4
ffffffffc0202fbe:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202fc0:	fe0d9ce3          	bnez	s11,ffffffffc0202fb8 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202fc4:	00044783          	lbu	a5,0(s0)
ffffffffc0202fc8:	00140a13          	addi	s4,s0,1
ffffffffc0202fcc:	0007851b          	sext.w	a0,a5
ffffffffc0202fd0:	d3a5                	beqz	a5,ffffffffc0202f30 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202fd2:	05e00413          	li	s0,94
ffffffffc0202fd6:	bf39                	j	ffffffffc0202ef4 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0202fd8:	000a2403          	lw	s0,0(s4)
ffffffffc0202fdc:	b7ad                	j	ffffffffc0202f46 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0202fde:	000a6603          	lwu	a2,0(s4)
ffffffffc0202fe2:	46a1                	li	a3,8
ffffffffc0202fe4:	8a2e                	mv	s4,a1
ffffffffc0202fe6:	bdb1                	j	ffffffffc0202e42 <vprintfmt+0x156>
ffffffffc0202fe8:	000a6603          	lwu	a2,0(s4)
ffffffffc0202fec:	46a9                	li	a3,10
ffffffffc0202fee:	8a2e                	mv	s4,a1
ffffffffc0202ff0:	bd89                	j	ffffffffc0202e42 <vprintfmt+0x156>
ffffffffc0202ff2:	000a6603          	lwu	a2,0(s4)
ffffffffc0202ff6:	46c1                	li	a3,16
ffffffffc0202ff8:	8a2e                	mv	s4,a1
ffffffffc0202ffa:	b5a1                	j	ffffffffc0202e42 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0202ffc:	9902                	jalr	s2
ffffffffc0202ffe:	bf09                	j	ffffffffc0202f10 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203000:	85a6                	mv	a1,s1
ffffffffc0203002:	02d00513          	li	a0,45
ffffffffc0203006:	e03e                	sd	a5,0(sp)
ffffffffc0203008:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020300a:	6782                	ld	a5,0(sp)
ffffffffc020300c:	8a66                	mv	s4,s9
ffffffffc020300e:	40800633          	neg	a2,s0
ffffffffc0203012:	46a9                	li	a3,10
ffffffffc0203014:	b53d                	j	ffffffffc0202e42 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203016:	03b05163          	blez	s11,ffffffffc0203038 <vprintfmt+0x34c>
ffffffffc020301a:	02d00693          	li	a3,45
ffffffffc020301e:	f6d79de3          	bne	a5,a3,ffffffffc0202f98 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203022:	00001417          	auipc	s0,0x1
ffffffffc0203026:	42e40413          	addi	s0,s0,1070 # ffffffffc0204450 <tree_buddy_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020302a:	02800793          	li	a5,40
ffffffffc020302e:	02800513          	li	a0,40
ffffffffc0203032:	00140a13          	addi	s4,s0,1
ffffffffc0203036:	bd6d                	j	ffffffffc0202ef0 <vprintfmt+0x204>
ffffffffc0203038:	00001a17          	auipc	s4,0x1
ffffffffc020303c:	419a0a13          	addi	s4,s4,1049 # ffffffffc0204451 <tree_buddy_pmm_manager+0x51>
ffffffffc0203040:	02800513          	li	a0,40
ffffffffc0203044:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203048:	05e00413          	li	s0,94
ffffffffc020304c:	b565                	j	ffffffffc0202ef4 <vprintfmt+0x208>

ffffffffc020304e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020304e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203050:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203054:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203056:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203058:	ec06                	sd	ra,24(sp)
ffffffffc020305a:	f83a                	sd	a4,48(sp)
ffffffffc020305c:	fc3e                	sd	a5,56(sp)
ffffffffc020305e:	e0c2                	sd	a6,64(sp)
ffffffffc0203060:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203062:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203064:	c89ff0ef          	jal	ra,ffffffffc0202cec <vprintfmt>
}
ffffffffc0203068:	60e2                	ld	ra,24(sp)
ffffffffc020306a:	6161                	addi	sp,sp,80
ffffffffc020306c:	8082                	ret

ffffffffc020306e <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020306e:	4781                	li	a5,0
ffffffffc0203070:	00005717          	auipc	a4,0x5
ffffffffc0203074:	fa073703          	ld	a4,-96(a4) # ffffffffc0208010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0203078:	88ba                	mv	a7,a4
ffffffffc020307a:	852a                	mv	a0,a0
ffffffffc020307c:	85be                	mv	a1,a5
ffffffffc020307e:	863e                	mv	a2,a5
ffffffffc0203080:	00000073          	ecall
ffffffffc0203084:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0203086:	8082                	ret

ffffffffc0203088 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203088:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020308c:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020308e:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203090:	cb81                	beqz	a5,ffffffffc02030a0 <strlen+0x18>
        cnt ++;
ffffffffc0203092:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203094:	00a707b3          	add	a5,a4,a0
ffffffffc0203098:	0007c783          	lbu	a5,0(a5)
ffffffffc020309c:	fbfd                	bnez	a5,ffffffffc0203092 <strlen+0xa>
ffffffffc020309e:	8082                	ret
    }
    return cnt;
}
ffffffffc02030a0:	8082                	ret

ffffffffc02030a2 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02030a2:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02030a4:	e589                	bnez	a1,ffffffffc02030ae <strnlen+0xc>
ffffffffc02030a6:	a811                	j	ffffffffc02030ba <strnlen+0x18>
        cnt ++;
ffffffffc02030a8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02030aa:	00f58863          	beq	a1,a5,ffffffffc02030ba <strnlen+0x18>
ffffffffc02030ae:	00f50733          	add	a4,a0,a5
ffffffffc02030b2:	00074703          	lbu	a4,0(a4)
ffffffffc02030b6:	fb6d                	bnez	a4,ffffffffc02030a8 <strnlen+0x6>
ffffffffc02030b8:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02030ba:	852e                	mv	a0,a1
ffffffffc02030bc:	8082                	ret

ffffffffc02030be <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02030be:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02030c2:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02030c6:	cb89                	beqz	a5,ffffffffc02030d8 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02030c8:	0505                	addi	a0,a0,1
ffffffffc02030ca:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02030cc:	fee789e3          	beq	a5,a4,ffffffffc02030be <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02030d0:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02030d4:	9d19                	subw	a0,a0,a4
ffffffffc02030d6:	8082                	ret
ffffffffc02030d8:	4501                	li	a0,0
ffffffffc02030da:	bfed                	j	ffffffffc02030d4 <strcmp+0x16>

ffffffffc02030dc <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02030dc:	c20d                	beqz	a2,ffffffffc02030fe <strncmp+0x22>
ffffffffc02030de:	962e                	add	a2,a2,a1
ffffffffc02030e0:	a031                	j	ffffffffc02030ec <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02030e2:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02030e4:	00e79a63          	bne	a5,a4,ffffffffc02030f8 <strncmp+0x1c>
ffffffffc02030e8:	00b60b63          	beq	a2,a1,ffffffffc02030fe <strncmp+0x22>
ffffffffc02030ec:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02030f0:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02030f2:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02030f6:	f7f5                	bnez	a5,ffffffffc02030e2 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02030f8:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02030fc:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02030fe:	4501                	li	a0,0
ffffffffc0203100:	8082                	ret

ffffffffc0203102 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203102:	ca01                	beqz	a2,ffffffffc0203112 <memset+0x10>
ffffffffc0203104:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203106:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203108:	0785                	addi	a5,a5,1
ffffffffc020310a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020310e:	fec79de3          	bne	a5,a2,ffffffffc0203108 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203112:	8082                	ret
