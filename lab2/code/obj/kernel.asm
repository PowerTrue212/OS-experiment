
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

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
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	c2450513          	addi	a0,a0,-988 # ffffffffc0201c70 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	c2e50513          	addi	a0,a0,-978 # ffffffffc0201c90 <etext+0x24>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	bfe58593          	addi	a1,a1,-1026 # ffffffffc0201c6c <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	c3a50513          	addi	a0,a0,-966 # ffffffffc0201cb0 <etext+0x44>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <buddy_free_lists>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	c4650513          	addi	a0,a0,-954 # ffffffffc0201cd0 <etext+0x64>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	1d258593          	addi	a1,a1,466 # ffffffffc0206268 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	c5250513          	addi	a0,a0,-942 # ffffffffc0201cf0 <etext+0x84>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	5bd58593          	addi	a1,a1,1469 # ffffffffc0206667 <end+0x3ff>
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
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	c4450513          	addi	a0,a0,-956 # ffffffffc0201d10 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <buddy_free_lists>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	18860613          	addi	a2,a2,392 # ffffffffc0206268 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	36b010ef          	jal	ra,ffffffffc0201c5a <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	c4450513          	addi	a0,a0,-956 # ffffffffc0201d40 <etext+0xd4>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	4e4010ef          	jal	ra,ffffffffc02015f0 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	704010ef          	jal	ra,ffffffffc0201844 <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	6ce010ef          	jal	ra,ffffffffc0201844 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	05630313          	addi	t1,t1,86 # ffffffffc0206218 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0201d60 <etext+0xf4>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	4e850513          	addi	a0,a0,1256 # ffffffffc02026f0 <etext+0xa84>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	1ab0106f          	j	ffffffffc0201bc6 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	b5e50513          	addi	a0,a0,-1186 # ffffffffc0201d80 <etext+0x114>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	b4050513          	addi	a0,a0,-1216 # ffffffffc0201d90 <etext+0x124>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0201da0 <etext+0x134>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00002517          	auipc	a0,0x2
ffffffffc020027a:	b4250513          	addi	a0,a0,-1214 # ffffffffc0201db8 <etext+0x14c>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9c85>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00002917          	auipc	s2,0x2
ffffffffc0200334:	ad890913          	addi	s2,s2,-1320 # ffffffffc0201e08 <etext+0x19c>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00002497          	auipc	s1,0x2
ffffffffc0200342:	ac248493          	addi	s1,s1,-1342 # ffffffffc0201e00 <etext+0x194>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00002517          	auipc	a0,0x2
ffffffffc0200396:	aee50513          	addi	a0,a0,-1298 # ffffffffc0201e80 <etext+0x214>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	b1a50513          	addi	a0,a0,-1254 # ffffffffc0201eb8 <etext+0x24c>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00002517          	auipc	a0,0x2
ffffffffc02003e2:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0201dd8 <etext+0x16c>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	7f4010ef          	jal	ra,ffffffffc0201be0 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	03b010ef          	jal	ra,ffffffffc0201c34 <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	786010ef          	jal	ra,ffffffffc0201c16 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	96c50513          	addi	a0,a0,-1684 # ffffffffc0201e10 <etext+0x1a4>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00002517          	auipc	a0,0x2
ffffffffc0200576:	8be50513          	addi	a0,a0,-1858 # ffffffffc0201e30 <etext+0x1c4>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00002517          	auipc	a0,0x2
ffffffffc0200588:	8c450513          	addi	a0,a0,-1852 # ffffffffc0201e48 <etext+0x1dc>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00002517          	auipc	a0,0x2
ffffffffc020059a:	8d250513          	addi	a0,a0,-1838 # ffffffffc0201e68 <etext+0x1fc>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	91650513          	addi	a0,a0,-1770 # ffffffffc0201eb8 <etext+0x24c>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	c687bb23          	sd	s0,-906(a5) # ffffffffc0206220 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	c767bb23          	sd	s6,-906(a5) # ffffffffc0206228 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	c6453503          	ld	a0,-924(a0) # ffffffffc0206220 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	c6253503          	ld	a0,-926(a0) # ffffffffc0206228 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_insert>:
}

/* Merge only with the same-size block at the PPN selected by XOR. */
static void
buddy_insert(struct Page *base, size_t order) {
    while (order < BUDDY_MAX_ORDER) {
ffffffffc02005d0:	47f9                	li	a5,30
ffffffffc02005d2:	0cb7e063          	bltu	a5,a1,ffffffffc0200692 <buddy_insert+0xc2>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02005d6:	00006897          	auipc	a7,0x6
ffffffffc02005da:	c6a8b883          	ld	a7,-918(a7) # ffffffffc0206240 <pages>
ffffffffc02005de:	00002617          	auipc	a2,0x2
ffffffffc02005e2:	57a63603          	ld	a2,1402(a2) # ffffffffc0202b58 <nbase>
        size_t size = buddy_block_size(order);
        size_t peer_ppn = page2ppn(base) ^ size;
        if (peer_ppn < nbase || peer_ppn >= npage ||
ffffffffc02005e6:	00006317          	auipc	t1,0x6
ffffffffc02005ea:	c5233303          	ld	t1,-942(t1) # ffffffffc0206238 <npage>
ffffffffc02005ee:	00002f17          	auipc	t5,0x2
ffffffffc02005f2:	562f3f03          	ld	t5,1378(t5) # ffffffffc0202b50 <error_string+0x38>
    return (size_t)1 << order;
ffffffffc02005f6:	4e85                	li	t4,1
            size > npage - peer_ppn) {
            break;
        }

        struct Page *peer = pages + (peer_ppn - nbase);
        if (PageReserved(peer) || !PageProperty(peer) ||
ffffffffc02005f8:	4f89                	li	t6,2
    while (order < BUDDY_MAX_ORDER) {
ffffffffc02005fa:	42fd                	li	t0,31
ffffffffc02005fc:	41150733          	sub	a4,a0,a7
ffffffffc0200600:	870d                	srai	a4,a4,0x3
ffffffffc0200602:	03e70733          	mul	a4,a4,t5
    return (size_t)1 << order;
ffffffffc0200606:	00be96b3          	sll	a3,t4,a1
ffffffffc020060a:	9732                	add	a4,a4,a2
        size_t peer_ppn = page2ppn(base) ^ size;
ffffffffc020060c:	8f35                	xor	a4,a4,a3
        struct Page *peer = pages + (peer_ppn - nbase);
ffffffffc020060e:	40c70833          	sub	a6,a4,a2
ffffffffc0200612:	00281793          	slli	a5,a6,0x2
ffffffffc0200616:	97c2                	add	a5,a5,a6
ffffffffc0200618:	078e                	slli	a5,a5,0x3
ffffffffc020061a:	97c6                	add	a5,a5,a7
            peer->property != size) {
            break;
        }

        list_del_init(&peer->page_link);
ffffffffc020061c:	01878813          	addi	a6,a5,24
            size > npage - peer_ppn) {
ffffffffc0200620:	40e30e33          	sub	t3,t1,a4
        if (peer_ppn < nbase || peer_ppn >= npage ||
ffffffffc0200624:	04c76463          	bltu	a4,a2,ffffffffc020066c <buddy_insert+0x9c>
ffffffffc0200628:	04677263          	bgeu	a4,t1,ffffffffc020066c <buddy_insert+0x9c>
ffffffffc020062c:	04de6063          	bltu	t3,a3,ffffffffc020066c <buddy_insert+0x9c>
        if (PageReserved(peer) || !PageProperty(peer) ||
ffffffffc0200630:	6798                	ld	a4,8(a5)
        ClearPageProperty(peer);
ffffffffc0200632:	ffd77e13          	andi	t3,a4,-3
        if (PageReserved(peer) || !PageProperty(peer) ||
ffffffffc0200636:	8b0d                	andi	a4,a4,3
ffffffffc0200638:	03f71a63          	bne	a4,t6,ffffffffc020066c <buddy_insert+0x9c>
            peer->property != size) {
ffffffffc020063c:	0107e703          	lwu	a4,16(a5)
        if (PageReserved(peer) || !PageProperty(peer) ||
ffffffffc0200640:	02d71663          	bne	a4,a3,ffffffffc020066c <buddy_insert+0x9c>
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
ffffffffc0200644:	6f94                	ld	a3,24(a5)
ffffffffc0200646:	7398                	ld	a4,32(a5)
        peer->property = 0;
        if (peer < base) {
            base = peer;
        }
        order++;
ffffffffc0200648:	0585                	addi	a1,a1,1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020064a:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020064c:	e314                	sd	a3,0(a4)
    elm->prev = elm->next = elm;
ffffffffc020064e:	0307b023          	sd	a6,32(a5)
ffffffffc0200652:	0107bc23          	sd	a6,24(a5)
        ClearPageProperty(peer);
ffffffffc0200656:	01c7b423          	sd	t3,8(a5)
        peer->property = 0;
ffffffffc020065a:	0007a823          	sw	zero,16(a5)
        if (peer < base) {
ffffffffc020065e:	00a7f363          	bgeu	a5,a0,ffffffffc0200664 <buddy_insert+0x94>
ffffffffc0200662:	853e                	mv	a0,a5
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0200664:	f8559ce3          	bne	a1,t0,ffffffffc02005fc <buddy_insert+0x2c>
ffffffffc0200668:	4685                	li	a3,1
ffffffffc020066a:	06fe                	slli	a3,a3,0x1f
    SetPageProperty(base);
ffffffffc020066c:	6518                	ld	a4,8(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc020066e:	00006797          	auipc	a5,0x6
ffffffffc0200672:	9aa78793          	addi	a5,a5,-1622 # ffffffffc0206018 <buddy_free_lists>
ffffffffc0200676:	0592                	slli	a1,a1,0x4
ffffffffc0200678:	95be                	add	a1,a1,a5
ffffffffc020067a:	6590                	ld	a2,8(a1)
ffffffffc020067c:	00276793          	ori	a5,a4,2
ffffffffc0200680:	e51c                	sd	a5,8(a0)
    base->property = buddy_block_size(order);
ffffffffc0200682:	c914                	sw	a3,16(a0)
    list_add(&buddy_free_lists[order], &base->page_link);
ffffffffc0200684:	01850793          	addi	a5,a0,24
    prev->next = next->prev = elm;
ffffffffc0200688:	e21c                	sd	a5,0(a2)
ffffffffc020068a:	e59c                	sd	a5,8(a1)
    elm->next = next;
ffffffffc020068c:	f110                	sd	a2,32(a0)
    elm->prev = prev;
ffffffffc020068e:	ed0c                	sd	a1,24(a0)
    }
    buddy_link(base, order);
}
ffffffffc0200690:	8082                	ret
    return (size_t)1 << order;
ffffffffc0200692:	4685                	li	a3,1
ffffffffc0200694:	00b696b3          	sll	a3,a3,a1
ffffffffc0200698:	bfd1                	j	ffffffffc020066c <buddy_insert+0x9c>

ffffffffc020069a <buddy_init>:

static void
buddy_init(void) {
    for (size_t order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc020069a:	00006797          	auipc	a5,0x6
ffffffffc020069e:	97e78793          	addi	a5,a5,-1666 # ffffffffc0206018 <buddy_free_lists>
ffffffffc02006a2:	00006717          	auipc	a4,0x6
ffffffffc02006a6:	b7670713          	addi	a4,a4,-1162 # ffffffffc0206218 <is_panic>
    elm->prev = elm->next = elm;
ffffffffc02006aa:	e79c                	sd	a5,8(a5)
ffffffffc02006ac:	e39c                	sd	a5,0(a5)
ffffffffc02006ae:	07c1                	addi	a5,a5,16
ffffffffc02006b0:	fee79de3          	bne	a5,a4,ffffffffc02006aa <buddy_init+0x10>
        list_init(&buddy_free_lists[order]);
    }
    buddy_free_count = 0;
ffffffffc02006b4:	00006797          	auipc	a5,0x6
ffffffffc02006b8:	b607be23          	sd	zero,-1156(a5) # ffffffffc0206230 <buddy_free_count>
}
ffffffffc02006bc:	8082                	ret

ffffffffc02006be <buddy_nr_free_pages>:
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_free_count;
}
ffffffffc02006be:	00006517          	auipc	a0,0x6
ffffffffc02006c2:	b7253503          	ld	a0,-1166(a0) # ffffffffc0206230 <buddy_free_count>
ffffffffc02006c6:	8082                	ret

ffffffffc02006c8 <buddy_check_free_lists>:

static void
buddy_check_free_lists(void) {
ffffffffc02006c8:	1141                	addi	sp,sp,-16
ffffffffc02006ca:	e406                	sd	ra,8(sp)
ffffffffc02006cc:	00006e97          	auipc	t4,0x6
ffffffffc02006d0:	b74ebe83          	ld	t4,-1164(t4) # ffffffffc0206240 <pages>
ffffffffc02006d4:	00002e17          	auipc	t3,0x2
ffffffffc02006d8:	484e3e03          	ld	t3,1156(t3) # ffffffffc0202b58 <nbase>
        list_entry_t *head = &buddy_free_lists[order];
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p) && p->property == size);
            assert((page2ppn(p) & (size - 1)) == 0);
            assert(page2ppn(p) < npage && size <= npage - page2ppn(p));
ffffffffc02006dc:	00006517          	auipc	a0,0x6
ffffffffc02006e0:	b5c53503          	ld	a0,-1188(a0) # ffffffffc0206238 <npage>
ffffffffc02006e4:	00006817          	auipc	a6,0x6
ffffffffc02006e8:	93480813          	addi	a6,a6,-1740 # ffffffffc0206018 <buddy_free_lists>
ffffffffc02006ec:	00006297          	auipc	t0,0x6
ffffffffc02006f0:	b2c28293          	addi	t0,t0,-1236 # ffffffffc0206218 <is_panic>
    for (size_t order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc02006f4:	4f01                	li	t5,0
    size_t total = 0;
ffffffffc02006f6:	4581                	li	a1,0
    return (size_t)1 << order;
ffffffffc02006f8:	4f85                	li	t6,1
ffffffffc02006fa:	00002317          	auipc	t1,0x2
ffffffffc02006fe:	45633303          	ld	t1,1110(t1) # ffffffffc0202b50 <error_string+0x38>
    return listelm->next;
ffffffffc0200702:	00883703          	ld	a4,8(a6)
ffffffffc0200706:	01ef9633          	sll	a2,t6,t5
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc020070a:	05070163          	beq	a4,a6,ffffffffc020074c <buddy_check_free_lists+0x84>
            assert((page2ppn(p) & (size - 1)) == 0);
ffffffffc020070e:	fff60893          	addi	a7,a2,-1
            assert(PageProperty(p) && p->property == size);
ffffffffc0200712:	ff073683          	ld	a3,-16(a4)
            struct Page *p = le2page(le, page_link);
ffffffffc0200716:	fe870793          	addi	a5,a4,-24
            assert(PageProperty(p) && p->property == size);
ffffffffc020071a:	8a89                	andi	a3,a3,2
ffffffffc020071c:	c6ad                	beqz	a3,ffffffffc0200786 <buddy_check_free_lists+0xbe>
ffffffffc020071e:	ff876683          	lwu	a3,-8(a4)
ffffffffc0200722:	06c69263          	bne	a3,a2,ffffffffc0200786 <buddy_check_free_lists+0xbe>
ffffffffc0200726:	41d787b3          	sub	a5,a5,t4
ffffffffc020072a:	878d                	srai	a5,a5,0x3
ffffffffc020072c:	026787b3          	mul	a5,a5,t1
ffffffffc0200730:	97f2                	add	a5,a5,t3
            assert((page2ppn(p) & (size - 1)) == 0);
ffffffffc0200732:	00f8f6b3          	and	a3,a7,a5
ffffffffc0200736:	eaa5                	bnez	a3,ffffffffc02007a6 <buddy_check_free_lists+0xde>
            assert(page2ppn(p) < npage && size <= npage - page2ppn(p));
ffffffffc0200738:	02a7f763          	bgeu	a5,a0,ffffffffc0200766 <buddy_check_free_lists+0x9e>
ffffffffc020073c:	40f507b3          	sub	a5,a0,a5
ffffffffc0200740:	02c7e363          	bltu	a5,a2,ffffffffc0200766 <buddy_check_free_lists+0x9e>
ffffffffc0200744:	6718                	ld	a4,8(a4)
            total += size;
ffffffffc0200746:	95b2                	add	a1,a1,a2
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc0200748:	fd0715e3          	bne	a4,a6,ffffffffc0200712 <buddy_check_free_lists+0x4a>
    for (size_t order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc020074c:	0841                	addi	a6,a6,16
ffffffffc020074e:	0f05                	addi	t5,t5,1
ffffffffc0200750:	fb0299e3          	bne	t0,a6,ffffffffc0200702 <buddy_check_free_lists+0x3a>
        }
    }
    assert(total == buddy_free_count);
ffffffffc0200754:	00006797          	auipc	a5,0x6
ffffffffc0200758:	adc7b783          	ld	a5,-1316(a5) # ffffffffc0206230 <buddy_free_count>
ffffffffc020075c:	06b79563          	bne	a5,a1,ffffffffc02007c6 <buddy_check_free_lists+0xfe>
}
ffffffffc0200760:	60a2                	ld	ra,8(sp)
ffffffffc0200762:	0141                	addi	sp,sp,16
ffffffffc0200764:	8082                	ret
            assert(page2ppn(p) < npage && size <= npage - page2ppn(p));
ffffffffc0200766:	00001697          	auipc	a3,0x1
ffffffffc020076a:	7e268693          	addi	a3,a3,2018 # ffffffffc0201f48 <etext+0x2dc>
ffffffffc020076e:	00001617          	auipc	a2,0x1
ffffffffc0200772:	78a60613          	addi	a2,a2,1930 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0200776:	09700593          	li	a1,151
ffffffffc020077a:	00001517          	auipc	a0,0x1
ffffffffc020077e:	79650513          	addi	a0,a0,1942 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc0200782:	a41ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(PageProperty(p) && p->property == size);
ffffffffc0200786:	00001697          	auipc	a3,0x1
ffffffffc020078a:	74a68693          	addi	a3,a3,1866 # ffffffffc0201ed0 <etext+0x264>
ffffffffc020078e:	00001617          	auipc	a2,0x1
ffffffffc0200792:	76a60613          	addi	a2,a2,1898 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0200796:	09500593          	li	a1,149
ffffffffc020079a:	00001517          	auipc	a0,0x1
ffffffffc020079e:	77650513          	addi	a0,a0,1910 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02007a2:	a21ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert((page2ppn(p) & (size - 1)) == 0);
ffffffffc02007a6:	00001697          	auipc	a3,0x1
ffffffffc02007aa:	78268693          	addi	a3,a3,1922 # ffffffffc0201f28 <etext+0x2bc>
ffffffffc02007ae:	00001617          	auipc	a2,0x1
ffffffffc02007b2:	74a60613          	addi	a2,a2,1866 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02007b6:	09600593          	li	a1,150
ffffffffc02007ba:	00001517          	auipc	a0,0x1
ffffffffc02007be:	75650513          	addi	a0,a0,1878 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02007c2:	a01ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == buddy_free_count);
ffffffffc02007c6:	00001697          	auipc	a3,0x1
ffffffffc02007ca:	7ba68693          	addi	a3,a3,1978 # ffffffffc0201f80 <etext+0x314>
ffffffffc02007ce:	00001617          	auipc	a2,0x1
ffffffffc02007d2:	72a60613          	addi	a2,a2,1834 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02007d6:	09b00593          	li	a1,155
ffffffffc02007da:	00001517          	auipc	a0,0x1
ffffffffc02007de:	73650513          	addi	a0,a0,1846 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02007e2:	9e1ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02007e6 <buddy_free_pages.part.0>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc02007e6:	1141                	addi	sp,sp,-16
ffffffffc02007e8:	87ae                	mv	a5,a1
ffffffffc02007ea:	e406                	sd	ra,8(sp)
    size_t order = 0;
ffffffffc02007ec:	4581                	li	a1,0
    return (size_t)1 << order;
ffffffffc02007ee:	4605                	li	a2,1
    while (order < BUDDY_MAX_ORDER && buddy_block_size(order) < n) {
ffffffffc02007f0:	487d                	li	a6,31
ffffffffc02007f2:	a021                	j	ffffffffc02007fa <buddy_free_pages.part.0+0x14>
        order++;
ffffffffc02007f4:	0585                	addi	a1,a1,1
    while (order < BUDDY_MAX_ORDER && buddy_block_size(order) < n) {
ffffffffc02007f6:	07058d63          	beq	a1,a6,ffffffffc0200870 <buddy_free_pages.part.0+0x8a>
    return (size_t)1 << order;
ffffffffc02007fa:	00b616b3          	sll	a3,a2,a1
ffffffffc02007fe:	0005871b          	sext.w	a4,a1
    while (order < BUDDY_MAX_ORDER && buddy_block_size(order) < n) {
ffffffffc0200802:	fef6e9e3          	bltu	a3,a5,ffffffffc02007f4 <buddy_free_pages.part.0+0xe>
    assert(size >= n && (page2ppn(base) & (size - 1)) == 0);
ffffffffc0200806:	fff68613          	addi	a2,a3,-1
ffffffffc020080a:	00006797          	auipc	a5,0x6
ffffffffc020080e:	a367b783          	ld	a5,-1482(a5) # ffffffffc0206240 <pages>
ffffffffc0200812:	40f507b3          	sub	a5,a0,a5
ffffffffc0200816:	00002817          	auipc	a6,0x2
ffffffffc020081a:	33a83803          	ld	a6,826(a6) # ffffffffc0202b50 <error_string+0x38>
ffffffffc020081e:	878d                	srai	a5,a5,0x3
ffffffffc0200820:	030787b3          	mul	a5,a5,a6
ffffffffc0200824:	00002817          	auipc	a6,0x2
ffffffffc0200828:	33483803          	ld	a6,820(a6) # ffffffffc0202b58 <nbase>
ffffffffc020082c:	97c2                	add	a5,a5,a6
ffffffffc020082e:	8ff1                	and	a5,a5,a2
ffffffffc0200830:	ebb5                	bnez	a5,ffffffffc02008a4 <buddy_free_pages.part.0+0xbe>
    for (struct Page *p = base; p < base + size; p++) {
ffffffffc0200832:	02800613          	li	a2,40
ffffffffc0200836:	00e61633          	sll	a2,a2,a4
ffffffffc020083a:	962a                	add	a2,a2,a0
ffffffffc020083c:	87aa                	mv	a5,a0
ffffffffc020083e:	00c57f63          	bgeu	a0,a2,ffffffffc020085c <buddy_free_pages.part.0+0x76>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200842:	6798                	ld	a4,8(a5)
ffffffffc0200844:	8b0d                	andi	a4,a4,3
ffffffffc0200846:	ef1d                	bnez	a4,ffffffffc0200884 <buddy_free_pages.part.0+0x9e>
        p->flags = 0;
ffffffffc0200848:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc020084c:	0007a823          	sw	zero,16(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200850:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p < base + size; p++) {
ffffffffc0200854:	02878793          	addi	a5,a5,40
ffffffffc0200858:	fec7e5e3          	bltu	a5,a2,ffffffffc0200842 <buddy_free_pages.part.0+0x5c>
    buddy_free_count += size;
ffffffffc020085c:	00006717          	auipc	a4,0x6
ffffffffc0200860:	9d470713          	addi	a4,a4,-1580 # ffffffffc0206230 <buddy_free_count>
ffffffffc0200864:	631c                	ld	a5,0(a4)
}
ffffffffc0200866:	60a2                	ld	ra,8(sp)
    buddy_free_count += size;
ffffffffc0200868:	97b6                	add	a5,a5,a3
ffffffffc020086a:	e31c                	sd	a5,0(a4)
}
ffffffffc020086c:	0141                	addi	sp,sp,16
    buddy_insert(base, order);
ffffffffc020086e:	b38d                	j	ffffffffc02005d0 <buddy_insert>
    assert(size >= n && (page2ppn(base) & (size - 1)) == 0);
ffffffffc0200870:	01f61693          	slli	a3,a2,0x1f
ffffffffc0200874:	02f6e863          	bltu	a3,a5,ffffffffc02008a4 <buddy_free_pages.part.0+0xbe>
ffffffffc0200878:	800007b7          	lui	a5,0x80000
ffffffffc020087c:	fff7c613          	not	a2,a5
    return (size_t)1 << order;
ffffffffc0200880:	477d                	li	a4,31
ffffffffc0200882:	b761                	j	ffffffffc020080a <buddy_free_pages.part.0+0x24>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200884:	00001697          	auipc	a3,0x1
ffffffffc0200888:	74c68693          	addi	a3,a3,1868 # ffffffffc0201fd0 <etext+0x364>
ffffffffc020088c:	00001617          	auipc	a2,0x1
ffffffffc0200890:	66c60613          	addi	a2,a2,1644 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0200894:	07f00593          	li	a1,127
ffffffffc0200898:	00001517          	auipc	a0,0x1
ffffffffc020089c:	67850513          	addi	a0,a0,1656 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02008a0:	923ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(size >= n && (page2ppn(base) & (size - 1)) == 0);
ffffffffc02008a4:	00001697          	auipc	a3,0x1
ffffffffc02008a8:	6fc68693          	addi	a3,a3,1788 # ffffffffc0201fa0 <etext+0x334>
ffffffffc02008ac:	00001617          	auipc	a2,0x1
ffffffffc02008b0:	64c60613          	addi	a2,a2,1612 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02008b4:	07d00593          	li	a1,125
ffffffffc02008b8:	00001517          	auipc	a0,0x1
ffffffffc02008bc:	65850513          	addi	a0,a0,1624 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02008c0:	903ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02008c4 <buddy_free_pages>:
    assert(n > 0);
ffffffffc02008c4:	c191                	beqz	a1,ffffffffc02008c8 <buddy_free_pages+0x4>
ffffffffc02008c6:	b705                	j	ffffffffc02007e6 <buddy_free_pages.part.0>
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc02008c8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02008ca:	00001697          	auipc	a3,0x1
ffffffffc02008ce:	72e68693          	addi	a3,a3,1838 # ffffffffc0201ff8 <etext+0x38c>
ffffffffc02008d2:	00001617          	auipc	a2,0x1
ffffffffc02008d6:	62660613          	addi	a2,a2,1574 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02008da:	07700593          	li	a1,119
ffffffffc02008de:	00001517          	auipc	a0,0x1
ffffffffc02008e2:	63250513          	addi	a0,a0,1586 # ffffffffc0201f10 <etext+0x2a4>
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc02008e6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02008e8:	8dbff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02008ec <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc02008ec:	711d                	addi	sp,sp,-96
ffffffffc02008ee:	ec86                	sd	ra,88(sp)
ffffffffc02008f0:	e8a2                	sd	s0,80(sp)
ffffffffc02008f2:	e4a6                	sd	s1,72(sp)
ffffffffc02008f4:	e0ca                	sd	s2,64(sp)
ffffffffc02008f6:	fc4e                	sd	s3,56(sp)
ffffffffc02008f8:	f852                	sd	s4,48(sp)
ffffffffc02008fa:	f456                	sd	s5,40(sp)
ffffffffc02008fc:	f05a                	sd	s6,32(sp)
ffffffffc02008fe:	ec5e                	sd	s7,24(sp)
    assert(n > 0);
ffffffffc0200900:	c9d5                	beqz	a1,ffffffffc02009b4 <buddy_init_memmap+0xc8>
    for (struct Page *p = base; p < base + n; p++) {
ffffffffc0200902:	00259693          	slli	a3,a1,0x2
ffffffffc0200906:	96ae                	add	a3,a3,a1
ffffffffc0200908:	068e                	slli	a3,a3,0x3
ffffffffc020090a:	96aa                	add	a3,a3,a0
ffffffffc020090c:	84ae                	mv	s1,a1
ffffffffc020090e:	8b2a                	mv	s6,a0
ffffffffc0200910:	87aa                	mv	a5,a0
ffffffffc0200912:	00d57f63          	bgeu	a0,a3,ffffffffc0200930 <buddy_init_memmap+0x44>
        assert(PageReserved(p));
ffffffffc0200916:	6798                	ld	a4,8(a5)
ffffffffc0200918:	8b05                	andi	a4,a4,1
ffffffffc020091a:	cf4d                	beqz	a4,ffffffffc02009d4 <buddy_init_memmap+0xe8>
        p->flags = 0;
ffffffffc020091c:	0007b423          	sd	zero,8(a5) # ffffffff80000008 <kern_entry-0x401ffff8>
        p->property = 0;
ffffffffc0200920:	0007a823          	sw	zero,16(a5)
ffffffffc0200924:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p < base + n; p++) {
ffffffffc0200928:	02878793          	addi	a5,a5,40
ffffffffc020092c:	fed7e5e3          	bltu	a5,a3,ffffffffc0200916 <buddy_init_memmap+0x2a>
    buddy_free_count += n;
ffffffffc0200930:	00006717          	auipc	a4,0x6
ffffffffc0200934:	90070713          	addi	a4,a4,-1792 # ffffffffc0206230 <buddy_free_count>
ffffffffc0200938:	631c                	ld	a5,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020093a:	00002a97          	auipc	s5,0x2
ffffffffc020093e:	21eaba83          	ld	s5,542(s5) # ffffffffc0202b58 <nbase>
ffffffffc0200942:	00006b97          	auipc	s7,0x6
ffffffffc0200946:	8feb8b93          	addi	s7,s7,-1794 # ffffffffc0206240 <pages>
ffffffffc020094a:	97a6                	add	a5,a5,s1
ffffffffc020094c:	e31c                	sd	a5,0(a4)
    while (n != 0) {
ffffffffc020094e:	00002a17          	auipc	s4,0x2
ffffffffc0200952:	202a3a03          	ld	s4,514(s4) # ffffffffc0202b50 <error_string+0x38>
    return (size_t)1 << order;
ffffffffc0200956:	4905                	li	s2,1
        base += size;
ffffffffc0200958:	02800993          	li	s3,40
ffffffffc020095c:	000bb683          	ld	a3,0(s7)
        size_t order = BUDDY_MAX_ORDER;
ffffffffc0200960:	45fd                	li	a1,31
ffffffffc0200962:	40db06b3          	sub	a3,s6,a3
ffffffffc0200966:	868d                	srai	a3,a3,0x3
ffffffffc0200968:	034686b3          	mul	a3,a3,s4
ffffffffc020096c:	96d6                	add	a3,a3,s5
    return (size_t)1 << order;
ffffffffc020096e:	0005879b          	sext.w	a5,a1
ffffffffc0200972:	00f91433          	sll	s0,s2,a5
        while (buddy_block_size(order) > n ||
ffffffffc0200976:	0084e663          	bltu	s1,s0,ffffffffc0200982 <buddy_init_memmap+0x96>
               (page2ppn(base) & (buddy_block_size(order) - 1)) != 0) {
ffffffffc020097a:	fff40713          	addi	a4,s0,-1
ffffffffc020097e:	8f75                	and	a4,a4,a3
        while (buddy_block_size(order) > n ||
ffffffffc0200980:	c319                	beqz	a4,ffffffffc0200986 <buddy_init_memmap+0x9a>
            order--;
ffffffffc0200982:	15fd                	addi	a1,a1,-1
ffffffffc0200984:	b7ed                	j	ffffffffc020096e <buddy_init_memmap+0x82>
        buddy_insert(base, order);
ffffffffc0200986:	855a                	mv	a0,s6
ffffffffc0200988:	00f107a3          	sb	a5,15(sp)
ffffffffc020098c:	c45ff0ef          	jal	ra,ffffffffc02005d0 <buddy_insert>
        base += size;
ffffffffc0200990:	00f14783          	lbu	a5,15(sp)
        n -= size;
ffffffffc0200994:	8c81                	sub	s1,s1,s0
        base += size;
ffffffffc0200996:	00f997b3          	sll	a5,s3,a5
ffffffffc020099a:	9b3e                	add	s6,s6,a5
    while (n != 0) {
ffffffffc020099c:	f0e1                	bnez	s1,ffffffffc020095c <buddy_init_memmap+0x70>
}
ffffffffc020099e:	60e6                	ld	ra,88(sp)
ffffffffc02009a0:	6446                	ld	s0,80(sp)
ffffffffc02009a2:	64a6                	ld	s1,72(sp)
ffffffffc02009a4:	6906                	ld	s2,64(sp)
ffffffffc02009a6:	79e2                	ld	s3,56(sp)
ffffffffc02009a8:	7a42                	ld	s4,48(sp)
ffffffffc02009aa:	7aa2                	ld	s5,40(sp)
ffffffffc02009ac:	7b02                	ld	s6,32(sp)
ffffffffc02009ae:	6be2                	ld	s7,24(sp)
ffffffffc02009b0:	6125                	addi	sp,sp,96
ffffffffc02009b2:	8082                	ret
    assert(n > 0);
ffffffffc02009b4:	00001697          	auipc	a3,0x1
ffffffffc02009b8:	64468693          	addi	a3,a3,1604 # ffffffffc0201ff8 <etext+0x38c>
ffffffffc02009bc:	00001617          	auipc	a2,0x1
ffffffffc02009c0:	53c60613          	addi	a2,a2,1340 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02009c4:	03e00593          	li	a1,62
ffffffffc02009c8:	00001517          	auipc	a0,0x1
ffffffffc02009cc:	54850513          	addi	a0,a0,1352 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02009d0:	ff2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(PageReserved(p));
ffffffffc02009d4:	00001697          	auipc	a3,0x1
ffffffffc02009d8:	62c68693          	addi	a3,a3,1580 # ffffffffc0202000 <etext+0x394>
ffffffffc02009dc:	00001617          	auipc	a2,0x1
ffffffffc02009e0:	51c60613          	addi	a2,a2,1308 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02009e4:	04000593          	li	a1,64
ffffffffc02009e8:	00001517          	auipc	a0,0x1
ffffffffc02009ec:	52850513          	addi	a0,a0,1320 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02009f0:	fd2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02009f4 <buddy_check_only_block.constprop.0>:

/* The isolated test arena should contain exactly this one free block. */
static void
buddy_check_only_block(struct Page *base, size_t order) {
ffffffffc02009f4:	1141                	addi	sp,sp,-16
ffffffffc02009f6:	00005717          	auipc	a4,0x5
ffffffffc02009fa:	62270713          	addi	a4,a4,1570 # ffffffffc0206018 <buddy_free_lists>
ffffffffc02009fe:	e406                	sd	ra,8(sp)
ffffffffc0200a00:	4785                	li	a5,1
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
        list_entry_t *head = &buddy_free_lists[i];
        if (i == order) {
ffffffffc0200a02:	4615                	li	a2,5
ffffffffc0200a04:	04873e03          	ld	t3,72(a4)
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc0200a08:	02000593          	li	a1,32
            assert(list_next(head) == &base->page_link);
ffffffffc0200a0c:	01850313          	addi	t1,a0,24
            assert(list_next(&base->page_link) == head);
ffffffffc0200a10:	00005897          	auipc	a7,0x5
ffffffffc0200a14:	64888893          	addi	a7,a7,1608 # ffffffffc0206058 <buddy_free_lists+0x40>
            assert(PageProperty(base) && base->property == buddy_block_size(i));
ffffffffc0200a18:	4841                	li	a6,16
        if (i == order) {
ffffffffc0200a1a:	00c78b63          	beq	a5,a2,ffffffffc0200a30 <buddy_check_only_block.constprop.0+0x3c>
        } else {
            assert(list_empty(head));
ffffffffc0200a1e:	6714                	ld	a3,8(a4)
ffffffffc0200a20:	04e69d63          	bne	a3,a4,ffffffffc0200a7a <buddy_check_only_block.constprop.0+0x86>
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc0200a24:	04b78163          	beq	a5,a1,ffffffffc0200a66 <buddy_check_only_block.constprop.0+0x72>
ffffffffc0200a28:	0785                	addi	a5,a5,1
ffffffffc0200a2a:	0741                	addi	a4,a4,16
        if (i == order) {
ffffffffc0200a2c:	fec799e3          	bne	a5,a2,ffffffffc0200a1e <buddy_check_only_block.constprop.0+0x2a>
            assert(list_next(head) == &base->page_link);
ffffffffc0200a30:	086e1563          	bne	t3,t1,ffffffffc0200aba <buddy_check_only_block.constprop.0+0xc6>
            assert(list_next(&base->page_link) == head);
ffffffffc0200a34:	7114                	ld	a3,32(a0)
ffffffffc0200a36:	07169263          	bne	a3,a7,ffffffffc0200a9a <buddy_check_only_block.constprop.0+0xa6>
            assert(PageProperty(base) && base->property == buddy_block_size(i));
ffffffffc0200a3a:	6514                	ld	a3,8(a0)
ffffffffc0200a3c:	8a89                	andi	a3,a3,2
ffffffffc0200a3e:	c681                	beqz	a3,ffffffffc0200a46 <buddy_check_only_block.constprop.0+0x52>
ffffffffc0200a40:	4914                	lw	a3,16(a0)
ffffffffc0200a42:	ff0683e3          	beq	a3,a6,ffffffffc0200a28 <buddy_check_only_block.constprop.0+0x34>
ffffffffc0200a46:	00001697          	auipc	a3,0x1
ffffffffc0200a4a:	61a68693          	addi	a3,a3,1562 # ffffffffc0202060 <etext+0x3f4>
ffffffffc0200a4e:	00001617          	auipc	a2,0x1
ffffffffc0200a52:	4aa60613          	addi	a2,a2,1194 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0200a56:	0a600593          	li	a1,166
ffffffffc0200a5a:	00001517          	auipc	a0,0x1
ffffffffc0200a5e:	4b650513          	addi	a0,a0,1206 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc0200a62:	f60ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        }
    }
    assert(buddy_free_count == buddy_block_size(order));
ffffffffc0200a66:	00005717          	auipc	a4,0x5
ffffffffc0200a6a:	7ca73703          	ld	a4,1994(a4) # ffffffffc0206230 <buddy_free_count>
ffffffffc0200a6e:	47c1                	li	a5,16
ffffffffc0200a70:	06f71563          	bne	a4,a5,ffffffffc0200ada <buddy_check_only_block.constprop.0+0xe6>
    buddy_check_free_lists();
}
ffffffffc0200a74:	60a2                	ld	ra,8(sp)
ffffffffc0200a76:	0141                	addi	sp,sp,16
    buddy_check_free_lists();
ffffffffc0200a78:	b981                	j	ffffffffc02006c8 <buddy_check_free_lists>
            assert(list_empty(head));
ffffffffc0200a7a:	00001697          	auipc	a3,0x1
ffffffffc0200a7e:	62668693          	addi	a3,a3,1574 # ffffffffc02020a0 <etext+0x434>
ffffffffc0200a82:	00001617          	auipc	a2,0x1
ffffffffc0200a86:	47660613          	addi	a2,a2,1142 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0200a8a:	0a800593          	li	a1,168
ffffffffc0200a8e:	00001517          	auipc	a0,0x1
ffffffffc0200a92:	48250513          	addi	a0,a0,1154 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc0200a96:	f2cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(list_next(&base->page_link) == head);
ffffffffc0200a9a:	00001697          	auipc	a3,0x1
ffffffffc0200a9e:	59e68693          	addi	a3,a3,1438 # ffffffffc0202038 <etext+0x3cc>
ffffffffc0200aa2:	00001617          	auipc	a2,0x1
ffffffffc0200aa6:	45660613          	addi	a2,a2,1110 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0200aaa:	0a500593          	li	a1,165
ffffffffc0200aae:	00001517          	auipc	a0,0x1
ffffffffc0200ab2:	46250513          	addi	a0,a0,1122 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc0200ab6:	f0cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(list_next(head) == &base->page_link);
ffffffffc0200aba:	00001697          	auipc	a3,0x1
ffffffffc0200abe:	55668693          	addi	a3,a3,1366 # ffffffffc0202010 <etext+0x3a4>
ffffffffc0200ac2:	00001617          	auipc	a2,0x1
ffffffffc0200ac6:	43660613          	addi	a2,a2,1078 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0200aca:	0a400593          	li	a1,164
ffffffffc0200ace:	00001517          	auipc	a0,0x1
ffffffffc0200ad2:	44250513          	addi	a0,a0,1090 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc0200ad6:	eecff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_free_count == buddy_block_size(order));
ffffffffc0200ada:	00001697          	auipc	a3,0x1
ffffffffc0200ade:	5de68693          	addi	a3,a3,1502 # ffffffffc02020b8 <etext+0x44c>
ffffffffc0200ae2:	00001617          	auipc	a2,0x1
ffffffffc0200ae6:	41660613          	addi	a2,a2,1046 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0200aea:	0ab00593          	li	a1,171
ffffffffc0200aee:	00001517          	auipc	a0,0x1
ffffffffc0200af2:	42250513          	addi	a0,a0,1058 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc0200af6:	eccff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200afa <buddy_alloc_pages.part.0>:
buddy_alloc_pages(size_t n) {
ffffffffc0200afa:	872a                	mv	a4,a0
    size_t order = 0;
ffffffffc0200afc:	4781                	li	a5,0
    return (size_t)1 << order;
ffffffffc0200afe:	4685                	li	a3,1
    while (order < BUDDY_MAX_ORDER && buddy_block_size(order) < n) {
ffffffffc0200b00:	45fd                	li	a1,31
ffffffffc0200b02:	a021                	j	ffffffffc0200b0a <buddy_alloc_pages.part.0+0x10>
        order++;
ffffffffc0200b04:	0785                	addi	a5,a5,1
    while (order < BUDDY_MAX_ORDER && buddy_block_size(order) < n) {
ffffffffc0200b06:	0ab78f63          	beq	a5,a1,ffffffffc0200bc4 <buddy_alloc_pages.part.0+0xca>
    return (size_t)1 << order;
ffffffffc0200b0a:	00f69633          	sll	a2,a3,a5
    while (order < BUDDY_MAX_ORDER && buddy_block_size(order) < n) {
ffffffffc0200b0e:	fee66be3          	bltu	a2,a4,ffffffffc0200b04 <buddy_alloc_pages.part.0+0xa>
    if (size < n || size > buddy_free_count) {
ffffffffc0200b12:	00005f97          	auipc	t6,0x5
ffffffffc0200b16:	71ef8f93          	addi	t6,t6,1822 # ffffffffc0206230 <buddy_free_count>
ffffffffc0200b1a:	000fbf03          	ld	t5,0(t6)
ffffffffc0200b1e:	02cf6363          	bltu	t5,a2,ffffffffc0200b44 <buddy_alloc_pages.part.0+0x4a>
ffffffffc0200b22:	00005697          	auipc	a3,0x5
ffffffffc0200b26:	4f668693          	addi	a3,a3,1270 # ffffffffc0206018 <buddy_free_lists>
ffffffffc0200b2a:	00479713          	slli	a4,a5,0x4
ffffffffc0200b2e:	9736                	add	a4,a4,a3
ffffffffc0200b30:	883e                	mv	a6,a5
    while (found <= BUDDY_MAX_ORDER &&
ffffffffc0200b32:	02000593          	li	a1,32
    return list->next == list;
ffffffffc0200b36:	6708                	ld	a0,8(a4)
ffffffffc0200b38:	00e51863          	bne	a0,a4,ffffffffc0200b48 <buddy_alloc_pages.part.0+0x4e>
        found++;
ffffffffc0200b3c:	0805                	addi	a6,a6,1
    while (found <= BUDDY_MAX_ORDER &&
ffffffffc0200b3e:	0741                	addi	a4,a4,16
ffffffffc0200b40:	feb81be3          	bne	a6,a1,ffffffffc0200b36 <buddy_alloc_pages.part.0+0x3c>
        return NULL;
ffffffffc0200b44:	4501                	li	a0,0
ffffffffc0200b46:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b48:	00853883          	ld	a7,8(a0)
ffffffffc0200b4c:	00053303          	ld	t1,0(a0)
    ClearPageProperty(base);
ffffffffc0200b50:	ff053703          	ld	a4,-16(a0)
ffffffffc0200b54:	fff80593          	addi	a1,a6,-1
    prev->next = next;
ffffffffc0200b58:	01133423          	sd	a7,8(t1)
    next->prev = prev;
ffffffffc0200b5c:	0068b023          	sd	t1,0(a7)
ffffffffc0200b60:	9b75                	andi	a4,a4,-3
ffffffffc0200b62:	00459893          	slli	a7,a1,0x4
    elm->prev = elm->next = elm;
ffffffffc0200b66:	e508                	sd	a0,8(a0)
ffffffffc0200b68:	e108                	sd	a0,0(a0)
ffffffffc0200b6a:	fee53823          	sd	a4,-16(a0)
    base->property = 0;
ffffffffc0200b6e:	fe052c23          	sw	zero,-8(a0)
ffffffffc0200b72:	96c6                	add	a3,a3,a7
    struct Page *base = le2page(list_next(&buddy_free_lists[found]), page_link);
ffffffffc0200b74:	1521                	addi	a0,a0,-24
        buddy_link(base + buddy_block_size(found), found);
ffffffffc0200b76:	02800e93          	li	t4,40
    return (size_t)1 << order;
ffffffffc0200b7a:	4e05                	li	t3,1
    while (found > order) {
ffffffffc0200b7c:	0107e463          	bltu	a5,a6,ffffffffc0200b84 <buddy_alloc_pages.part.0+0x8a>
ffffffffc0200b80:	a82d                	j	ffffffffc0200bba <buddy_alloc_pages.part.0+0xc0>
ffffffffc0200b82:	15fd                	addi	a1,a1,-1
        buddy_link(base + buddy_block_size(found), found);
ffffffffc0200b84:	00be9733          	sll	a4,t4,a1
ffffffffc0200b88:	972a                	add	a4,a4,a0
    SetPageProperty(base);
ffffffffc0200b8a:	00873803          	ld	a6,8(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b8e:	0086b303          	ld	t1,8(a3)
    return (size_t)1 << order;
ffffffffc0200b92:	00be18b3          	sll	a7,t3,a1
    SetPageProperty(base);
ffffffffc0200b96:	00286813          	ori	a6,a6,2
ffffffffc0200b9a:	01073423          	sd	a6,8(a4)
    base->property = buddy_block_size(order);
ffffffffc0200b9e:	01172823          	sw	a7,16(a4)
    list_add(&buddy_free_lists[order], &base->page_link);
ffffffffc0200ba2:	01870813          	addi	a6,a4,24
    prev->next = next->prev = elm;
ffffffffc0200ba6:	01033023          	sd	a6,0(t1)
ffffffffc0200baa:	0106b423          	sd	a6,8(a3)
    elm->prev = prev;
ffffffffc0200bae:	ef14                	sd	a3,24(a4)
    elm->next = next;
ffffffffc0200bb0:	02673023          	sd	t1,32(a4)
    while (found > order) {
ffffffffc0200bb4:	16c1                	addi	a3,a3,-16
ffffffffc0200bb6:	fcf596e3          	bne	a1,a5,ffffffffc0200b82 <buddy_alloc_pages.part.0+0x88>
    buddy_free_count -= size;
ffffffffc0200bba:	40cf0633          	sub	a2,t5,a2
ffffffffc0200bbe:	00cfb023          	sd	a2,0(t6)
    return base;
ffffffffc0200bc2:	8082                	ret
    if (size < n || size > buddy_free_count) {
ffffffffc0200bc4:	01f69613          	slli	a2,a3,0x1f
        return NULL;
ffffffffc0200bc8:	4501                	li	a0,0
    if (size < n || size > buddy_free_count) {
ffffffffc0200bca:	f4e674e3          	bgeu	a2,a4,ffffffffc0200b12 <buddy_alloc_pages.part.0+0x18>
}
ffffffffc0200bce:	8082                	ret

ffffffffc0200bd0 <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc0200bd0:	c111                	beqz	a0,ffffffffc0200bd4 <buddy_alloc_pages+0x4>
ffffffffc0200bd2:	b725                	j	ffffffffc0200afa <buddy_alloc_pages.part.0>
buddy_alloc_pages(size_t n) {
ffffffffc0200bd4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200bd6:	00001697          	auipc	a3,0x1
ffffffffc0200bda:	42268693          	addi	a3,a3,1058 # ffffffffc0201ff8 <etext+0x38c>
ffffffffc0200bde:	00001617          	auipc	a2,0x1
ffffffffc0200be2:	31a60613          	addi	a2,a2,794 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0200be6:	05600593          	li	a1,86
ffffffffc0200bea:	00001517          	auipc	a0,0x1
ffffffffc0200bee:	32650513          	addi	a0,a0,806 # ffffffffc0201f10 <etext+0x2a4>
buddy_alloc_pages(size_t n) {
ffffffffc0200bf2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200bf4:	dceff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200bf8 <buddy_check>:

static void
buddy_check(void) {
ffffffffc0200bf8:	cc010113          	addi	sp,sp,-832
ffffffffc0200bfc:	33213023          	sd	s2,800(sp)
ffffffffc0200c00:	32113c23          	sd	ra,824(sp)
ffffffffc0200c04:	32813823          	sd	s0,816(sp)
ffffffffc0200c08:	32913423          	sd	s1,808(sp)
ffffffffc0200c0c:	31313c23          	sd	s3,792(sp)
ffffffffc0200c10:	31413823          	sd	s4,784(sp)
ffffffffc0200c14:	31513423          	sd	s5,776(sp)
ffffffffc0200c18:	31613023          	sd	s6,768(sp)
ffffffffc0200c1c:	2f713c23          	sd	s7,760(sp)
ffffffffc0200c20:	2f813823          	sd	s8,752(sp)
ffffffffc0200c24:	2f913423          	sd	s9,744(sp)
ffffffffc0200c28:	2fa13023          	sd	s10,736(sp)
ffffffffc0200c2c:	2db13c23          	sd	s11,728(sp)
    return buddy_free_count;
ffffffffc0200c30:	00005917          	auipc	s2,0x5
ffffffffc0200c34:	60090913          	addi	s2,s2,1536 # ffffffffc0206230 <buddy_free_count>
    buddy_check_free_lists();
ffffffffc0200c38:	a91ff0ef          	jal	ra,ffffffffc02006c8 <buddy_check_free_lists>
    return buddy_free_count;
ffffffffc0200c3c:	00093783          	ld	a5,0(s2)
ffffffffc0200c40:	873e                	mv	a4,a5
ffffffffc0200c42:	e83e                	sd	a5,16(sp)
    size_t original_free = buddy_nr_free_pages();
    assert(original_free >= 32);
ffffffffc0200c44:	47fd                	li	a5,31
ffffffffc0200c46:	78e7f563          	bgeu	a5,a4,ffffffffc02013d0 <buddy_check+0x7d8>
    assert(n > 0);
ffffffffc0200c4a:	02000513          	li	a0,32
ffffffffc0200c4e:	eadff0ef          	jal	ra,ffffffffc0200afa <buddy_alloc_pages.part.0>
ffffffffc0200c52:	84aa                	mv	s1,a0

    /* Keep the upper half allocated so the arena cannot merge with outside
     * blocks while the real free lists are temporarily hidden. */
    struct Page *arena = buddy_alloc_pages(32);
    assert(arena != NULL && (page2ppn(arena) & 31) == 0);
ffffffffc0200c54:	04050ee3          	beqz	a0,ffffffffc02014b0 <buddy_check+0x8b8>
ffffffffc0200c58:	00005c17          	auipc	s8,0x5
ffffffffc0200c5c:	5e8c0c13          	addi	s8,s8,1512 # ffffffffc0206240 <pages>
ffffffffc0200c60:	000c3983          	ld	s3,0(s8)
ffffffffc0200c64:	00002b97          	auipc	s7,0x2
ffffffffc0200c68:	eecbbb83          	ld	s7,-276(s7) # ffffffffc0202b50 <error_string+0x38>
ffffffffc0200c6c:	00002797          	auipc	a5,0x2
ffffffffc0200c70:	eec7b783          	ld	a5,-276(a5) # ffffffffc0202b58 <nbase>
ffffffffc0200c74:	413509b3          	sub	s3,a0,s3
ffffffffc0200c78:	4039d993          	srai	s3,s3,0x3
ffffffffc0200c7c:	037989b3          	mul	s3,s3,s7
ffffffffc0200c80:	e03e                	sd	a5,0(sp)
ffffffffc0200c82:	99be                	add	s3,s3,a5
ffffffffc0200c84:	01f9f993          	andi	s3,s3,31
ffffffffc0200c88:	020994e3          	bnez	s3,ffffffffc02014b0 <buddy_check+0x8b8>
    return buddy_free_count;
ffffffffc0200c8c:	00093703          	ld	a4,0(s2)
    assert(buddy_nr_free_pages() == original_free - 32);
ffffffffc0200c90:	67c2                	ld	a5,16(sp)
    return buddy_free_count;
ffffffffc0200c92:	ec3a                	sd	a4,24(sp)
    assert(buddy_nr_free_pages() == original_free - 32);
ffffffffc0200c94:	1781                	addi	a5,a5,-32
ffffffffc0200c96:	7ee79d63          	bne	a5,a4,ffffffffc0201490 <buddy_check+0x898>
ffffffffc0200c9a:	00005b17          	auipc	s6,0x5
ffffffffc0200c9e:	37eb0b13          	addi	s6,s6,894 # ffffffffc0206018 <buddy_free_lists>
ffffffffc0200ca2:	0d010d93          	addi	s11,sp,208
ffffffffc0200ca6:	00005417          	auipc	s0,0x5
ffffffffc0200caa:	57240413          	addi	s0,s0,1394 # ffffffffc0206218 <is_panic>
ffffffffc0200cae:	876e                	mv	a4,s11
ffffffffc0200cb0:	8a5a                	mv	s4,s6
ffffffffc0200cb2:	87da                	mv	a5,s6

    list_entry_t saved_lists[BUDDY_MAX_ORDER + 1];
    size_t saved_free = buddy_free_count;
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
        saved_lists[i] = buddy_free_lists[i];
ffffffffc0200cb4:	6390                	ld	a2,0(a5)
ffffffffc0200cb6:	6794                	ld	a3,8(a5)
    elm->prev = elm->next = elm;
ffffffffc0200cb8:	e39c                	sd	a5,0(a5)
ffffffffc0200cba:	e310                	sd	a2,0(a4)
ffffffffc0200cbc:	e714                	sd	a3,8(a4)
ffffffffc0200cbe:	e79c                	sd	a5,8(a5)
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc0200cc0:	07c1                	addi	a5,a5,16
ffffffffc0200cc2:	0741                	addi	a4,a4,16
ffffffffc0200cc4:	fe8798e3          	bne	a5,s0,ffffffffc0200cb4 <buddy_check+0xbc>
        list_init(&buddy_free_lists[i]);
    }
    buddy_free_count = 0;
ffffffffc0200cc8:	45c1                	li	a1,16
ffffffffc0200cca:	8526                	mv	a0,s1
ffffffffc0200ccc:	00005797          	auipc	a5,0x5
ffffffffc0200cd0:	5607b223          	sd	zero,1380(a5) # ffffffffc0206230 <buddy_free_count>
    assert(n > 0);
ffffffffc0200cd4:	b13ff0ef          	jal	ra,ffffffffc02007e6 <buddy_free_pages.part.0>

    buddy_free_pages(arena, 16);
    buddy_check_only_block(arena, 4);
ffffffffc0200cd8:	8526                	mv	a0,s1
ffffffffc0200cda:	d1bff0ef          	jal	ra,ffffffffc02009f4 <buddy_check_only_block.constprop.0>
    assert(n > 0);
ffffffffc0200cde:	4505                	li	a0,1
ffffffffc0200ce0:	e1bff0ef          	jal	ra,ffffffffc0200afa <buddy_alloc_pages.part.0>

    /* One page must split a 16-page block through three levels. */
    assert(buddy_alloc_pages(1) == arena);
ffffffffc0200ce4:	78a49663          	bne	s1,a0,ffffffffc0201470 <buddy_check+0x878>
    assert(buddy_nr_free_pages() == 15);
ffffffffc0200ce8:	00093703          	ld	a4,0(s2)
ffffffffc0200cec:	47bd                	li	a5,15
ffffffffc0200cee:	7ef71163          	bne	a4,a5,ffffffffc02014d0 <buddy_check+0x8d8>
ffffffffc0200cf2:	000c3303          	ld	t1,0(s8)
    for (size_t order = 0; order < 4; order++) {
ffffffffc0200cf6:	6802                	ld	a6,0(sp)
ffffffffc0200cf8:	00005617          	auipc	a2,0x5
ffffffffc0200cfc:	32060613          	addi	a2,a2,800 # ffffffffc0206018 <buddy_free_lists>
    return (size_t)1 << order;
ffffffffc0200d00:	4885                	li	a7,1
        struct Page *sibling = arena + buddy_block_size(order);
ffffffffc0200d02:	02800513          	li	a0,40
    for (size_t order = 0; order < 4; order++) {
ffffffffc0200d06:	4591                	li	a1,4
        struct Page *sibling = arena + buddy_block_size(order);
ffffffffc0200d08:	013517b3          	sll	a5,a0,s3
        list_entry_t *head = &buddy_free_lists[order];
        assert(list_next(head) == &sibling->page_link);
ffffffffc0200d0c:	00863e03          	ld	t3,8(a2)
        struct Page *sibling = arena + buddy_block_size(order);
ffffffffc0200d10:	97a6                	add	a5,a5,s1
        assert(list_next(head) == &sibling->page_link);
ffffffffc0200d12:	01878713          	addi	a4,a5,24
    return (size_t)1 << order;
ffffffffc0200d16:	013896b3          	sll	a3,a7,s3
        assert(list_next(head) == &sibling->page_link);
ffffffffc0200d1a:	60ee1b63          	bne	t3,a4,ffffffffc0201330 <buddy_check+0x738>
        assert(list_next(&sibling->page_link) == head);
ffffffffc0200d1e:	7398                	ld	a4,32(a5)
ffffffffc0200d20:	5ec71863          	bne	a4,a2,ffffffffc0201310 <buddy_check+0x718>
        assert(PageProperty(sibling) &&
ffffffffc0200d24:	6798                	ld	a4,8(a5)
ffffffffc0200d26:	8b09                	andi	a4,a4,2
ffffffffc0200d28:	5c070463          	beqz	a4,ffffffffc02012f0 <buddy_check+0x6f8>
ffffffffc0200d2c:	0107e703          	lwu	a4,16(a5)
ffffffffc0200d30:	5cd71063          	bne	a4,a3,ffffffffc02012f0 <buddy_check+0x6f8>
ffffffffc0200d34:	406787b3          	sub	a5,a5,t1
ffffffffc0200d38:	878d                	srai	a5,a5,0x3
ffffffffc0200d3a:	037787b3          	mul	a5,a5,s7
               sibling->property == buddy_block_size(order));
        assert((page2ppn(sibling) & (buddy_block_size(order) - 1)) == 0);
ffffffffc0200d3e:	177d                	addi	a4,a4,-1
ffffffffc0200d40:	97c2                	add	a5,a5,a6
ffffffffc0200d42:	8ff9                	and	a5,a5,a4
ffffffffc0200d44:	080796e3          	bnez	a5,ffffffffc02015d0 <buddy_check+0x9d8>
    for (size_t order = 0; order < 4; order++) {
ffffffffc0200d48:	0985                	addi	s3,s3,1
ffffffffc0200d4a:	0641                	addi	a2,a2,16
ffffffffc0200d4c:	fab99ee3          	bne	s3,a1,ffffffffc0200d08 <buddy_check+0x110>
    }
    assert(list_empty(&buddy_free_lists[4]));
ffffffffc0200d50:	048a3703          	ld	a4,72(s4)
ffffffffc0200d54:	00005797          	auipc	a5,0x5
ffffffffc0200d58:	30478793          	addi	a5,a5,772 # ffffffffc0206058 <buddy_free_lists+0x40>
ffffffffc0200d5c:	60f71a63          	bne	a4,a5,ffffffffc0201370 <buddy_check+0x778>
    buddy_check_free_lists();
ffffffffc0200d60:	969ff0ef          	jal	ra,ffffffffc02006c8 <buddy_check_free_lists>
    assert(n > 0);
ffffffffc0200d64:	4585                	li	a1,1
ffffffffc0200d66:	8526                	mv	a0,s1
ffffffffc0200d68:	a7fff0ef          	jal	ra,ffffffffc02007e6 <buddy_free_pages.part.0>
    buddy_free_pages(arena, 1);
    buddy_check_only_block(arena, 4);
ffffffffc0200d6c:	8526                	mv	a0,s1
ffffffffc0200d6e:	c87ff0ef          	jal	ra,ffffffffc02009f4 <buddy_check_only_block.constprop.0>

    /* Requests of 3 and 5 pages consume 4 and 8 pages respectively. */
    const size_t requests[] = {1, 2, 3, 5, 1};
ffffffffc0200d72:	00002797          	auipc	a5,0x2
ffffffffc0200d76:	99e78793          	addi	a5,a5,-1634 # ffffffffc0202710 <etext+0xaa4>
    const size_t blocks[] = {1, 2, 4, 8, 1};
ffffffffc0200d7a:	63b8                	ld	a4,64(a5)
    const size_t requests[] = {1, 2, 3, 5, 1};
ffffffffc0200d7c:	0007bf83          	ld	t6,0(a5)
ffffffffc0200d80:	0087bf03          	ld	t5,8(a5)
ffffffffc0200d84:	0107be03          	ld	t3,16(a5)
ffffffffc0200d88:	0187b303          	ld	t1,24(a5)
ffffffffc0200d8c:	0207b883          	ld	a7,32(a5)
    const size_t blocks[] = {1, 2, 4, 8, 1};
ffffffffc0200d90:	7788                	ld	a0,40(a5)
ffffffffc0200d92:	7b8c                	ld	a1,48(a5)
ffffffffc0200d94:	7f90                	ld	a2,56(a5)
ffffffffc0200d96:	67bc                	ld	a5,72(a5)
ffffffffc0200d98:	0a810d13          	addi	s10,sp,168
ffffffffc0200d9c:	08010993          	addi	s3,sp,128
ffffffffc0200da0:	ed3a                	sd	a4,152(sp)
ffffffffc0200da2:	f13e                	sd	a5,160(sp)
    size_t remaining = 16;
    for (size_t i = 0; i < 4; i++) {
        allocated[i] = buddy_alloc_pages(requests[i]);
        assert(allocated[i] != NULL);
        assert((page2ppn(allocated[i]) & (blocks[i] - 1)) == 0);
        assert(allocated[i] >= arena && allocated[i] + blocks[i] <= arena + 16);
ffffffffc0200da4:	28048713          	addi	a4,s1,640
    const size_t blocks[] = {1, 2, 4, 8, 1};
ffffffffc0200da8:	08bc                	addi	a5,sp,88
    for (size_t i = 0; i < 4; i++) {
ffffffffc0200daa:	f06e                	sd	s11,32(sp)
ffffffffc0200dac:	f45a                	sd	s6,40(sp)
    const size_t requests[] = {1, 2, 3, 5, 1};
ffffffffc0200dae:	ecfe                	sd	t6,88(sp)
ffffffffc0200db0:	f0fa                	sd	t5,96(sp)
ffffffffc0200db2:	f4f2                	sd	t3,104(sp)
ffffffffc0200db4:	f89a                	sd	t1,112(sp)
ffffffffc0200db6:	fcc6                	sd	a7,120(sp)
    const size_t blocks[] = {1, 2, 4, 8, 1};
ffffffffc0200db8:	e12a                	sd	a0,128(sp)
ffffffffc0200dba:	e52e                	sd	a1,136(sp)
ffffffffc0200dbc:	e932                	sd	a2,144(sp)
ffffffffc0200dbe:	4a85                	li	s5,1
    size_t remaining = 16;
ffffffffc0200dc0:	4a41                	li	s4,16
        assert(allocated[i] >= arena && allocated[i] + blocks[i] <= arena + 16);
ffffffffc0200dc2:	e43a                	sd	a4,8(sp)
    for (size_t i = 0; i < 4; i++) {
ffffffffc0200dc4:	8dbe                	mv	s11,a5
ffffffffc0200dc6:	8b6a                	mv	s6,s10
ffffffffc0200dc8:	8cce                	mv	s9,s3
        allocated[i] = buddy_alloc_pages(requests[i]);
ffffffffc0200dca:	000db503          	ld	a0,0(s11)
    assert(n > 0);
ffffffffc0200dce:	58050163          	beqz	a0,ffffffffc0201350 <buddy_check+0x758>
ffffffffc0200dd2:	d29ff0ef          	jal	ra,ffffffffc0200afa <buddy_alloc_pages.part.0>
        allocated[i] = buddy_alloc_pages(requests[i]);
ffffffffc0200dd6:	00ab3023          	sd	a0,0(s6)
        assert(allocated[i] != NULL);
ffffffffc0200dda:	5a050b63          	beqz	a0,ffffffffc0201390 <buddy_check+0x798>
ffffffffc0200dde:	000c3783          	ld	a5,0(s8)
        assert((page2ppn(allocated[i]) & (blocks[i] - 1)) == 0);
ffffffffc0200de2:	000cb303          	ld	t1,0(s9)
ffffffffc0200de6:	6682                	ld	a3,0(sp)
ffffffffc0200de8:	40f507b3          	sub	a5,a0,a5
ffffffffc0200dec:	878d                	srai	a5,a5,0x3
ffffffffc0200dee:	037787b3          	mul	a5,a5,s7
ffffffffc0200df2:	fff30713          	addi	a4,t1,-1
ffffffffc0200df6:	97b6                	add	a5,a5,a3
ffffffffc0200df8:	8ff9                	and	a5,a5,a4
ffffffffc0200dfa:	60079b63          	bnez	a5,ffffffffc0201410 <buddy_check+0x818>
        assert(allocated[i] >= arena && allocated[i] + blocks[i] <= arena + 16);
ffffffffc0200dfe:	5e956963          	bltu	a0,s1,ffffffffc02013f0 <buddy_check+0x7f8>
ffffffffc0200e02:	00231813          	slli	a6,t1,0x2
ffffffffc0200e06:	981a                	add	a6,a6,t1
ffffffffc0200e08:	67a2                	ld	a5,8(sp)
ffffffffc0200e0a:	080e                	slli	a6,a6,0x3
ffffffffc0200e0c:	982a                	add	a6,a6,a0
ffffffffc0200e0e:	5f07e163          	bltu	a5,a6,ffffffffc02013f0 <buddy_check+0x7f8>
        for (size_t j = 0; j < i; j++) {
ffffffffc0200e12:	4705                	li	a4,1
ffffffffc0200e14:	864e                	mv	a2,s3
ffffffffc0200e16:	87ea                	mv	a5,s10
ffffffffc0200e18:	2aea8363          	beq	s5,a4,ffffffffc02010be <buddy_check+0x4c6>
            assert(allocated[i] + blocks[i] <= allocated[j] ||
ffffffffc0200e1c:	6398                	ld	a4,0(a5)
ffffffffc0200e1e:	01077a63          	bgeu	a4,a6,ffffffffc0200e32 <buddy_check+0x23a>
ffffffffc0200e22:	620c                	ld	a1,0(a2)
ffffffffc0200e24:	00259693          	slli	a3,a1,0x2
ffffffffc0200e28:	96ae                	add	a3,a3,a1
ffffffffc0200e2a:	068e                	slli	a3,a3,0x3
ffffffffc0200e2c:	9736                	add	a4,a4,a3
ffffffffc0200e2e:	2ce56163          	bltu	a0,a4,ffffffffc02010f0 <buddy_check+0x4f8>
        for (size_t j = 0; j < i; j++) {
ffffffffc0200e32:	07a1                	addi	a5,a5,8
ffffffffc0200e34:	0621                	addi	a2,a2,8
ffffffffc0200e36:	ff6793e3          	bne	a5,s6,ffffffffc0200e1c <buddy_check+0x224>
                   allocated[j] + blocks[j] <= allocated[i]);
        }
        remaining -= blocks[i];
        assert(buddy_nr_free_pages() == remaining);
ffffffffc0200e3a:	00093783          	ld	a5,0(s2)
        remaining -= blocks[i];
ffffffffc0200e3e:	406a0a33          	sub	s4,s4,t1
        assert(buddy_nr_free_pages() == remaining);
ffffffffc0200e42:	6cfa1763          	bne	s4,a5,ffffffffc0201510 <buddy_check+0x918>
        buddy_check_free_lists();
ffffffffc0200e46:	883ff0ef          	jal	ra,ffffffffc02006c8 <buddy_check_free_lists>
    for (size_t i = 0; i < 4; i++) {
ffffffffc0200e4a:	4791                	li	a5,4
ffffffffc0200e4c:	00fa8763          	beq	s5,a5,ffffffffc0200e5a <buddy_check+0x262>
ffffffffc0200e50:	0da1                	addi	s11,s11,8
ffffffffc0200e52:	0a85                	addi	s5,s5,1
ffffffffc0200e54:	0b21                	addi	s6,s6,8
ffffffffc0200e56:	0ca1                	addi	s9,s9,8
ffffffffc0200e58:	bf8d                	j	ffffffffc0200dca <buddy_check+0x1d2>
    }
    assert(remaining == 1);
ffffffffc0200e5a:	4785                	li	a5,1
ffffffffc0200e5c:	7d82                	ld	s11,32(sp)
ffffffffc0200e5e:	7b22                	ld	s6,40(sp)
ffffffffc0200e60:	6efa1863          	bne	s4,a5,ffffffffc0201550 <buddy_check+0x958>
    assert(n > 0);
ffffffffc0200e64:	4509                	li	a0,2
ffffffffc0200e66:	c95ff0ef          	jal	ra,ffffffffc0200afa <buddy_alloc_pages.part.0>
    assert(buddy_alloc_pages(2) == NULL);
ffffffffc0200e6a:	6c051363          	bnez	a0,ffffffffc0201530 <buddy_check+0x938>
    assert(buddy_nr_free_pages() == remaining);
ffffffffc0200e6e:	00093783          	ld	a5,0(s2)
ffffffffc0200e72:	37479f63          	bne	a5,s4,ffffffffc02011f0 <buddy_check+0x5f8>
    buddy_check_free_lists();
ffffffffc0200e76:	853ff0ef          	jal	ra,ffffffffc02006c8 <buddy_check_free_lists>
    assert(n > 0);
ffffffffc0200e7a:	4505                	li	a0,1
ffffffffc0200e7c:	c7fff0ef          	jal	ra,ffffffffc0200afa <buddy_alloc_pages.part.0>

    allocated[4] = buddy_alloc_pages(requests[4]);
ffffffffc0200e80:	e5aa                	sd	a0,200(sp)
ffffffffc0200e82:	8caa                	mv	s9,a0
    assert(allocated[4] != NULL && allocated[4] >= arena &&
ffffffffc0200e84:	72050663          	beqz	a0,ffffffffc02015b0 <buddy_check+0x9b8>
ffffffffc0200e88:	72956463          	bltu	a0,s1,ffffffffc02015b0 <buddy_check+0x9b8>
ffffffffc0200e8c:	67a2                	ld	a5,8(sp)
           allocated[4] < arena + 16);
    for (size_t j = 0; j < 4; j++) {
        assert(allocated[4] + 1 <= allocated[j] ||
ffffffffc0200e8e:	02850513          	addi	a0,a0,40
ffffffffc0200e92:	020d0593          	addi	a1,s10,32
    assert(allocated[4] != NULL && allocated[4] >= arena &&
ffffffffc0200e96:	70fcfd63          	bgeu	s9,a5,ffffffffc02015b0 <buddy_check+0x9b8>
        assert(allocated[4] + 1 <= allocated[j] ||
ffffffffc0200e9a:	000d3783          	ld	a5,0(s10)
ffffffffc0200e9e:	00a7fb63          	bgeu	a5,a0,ffffffffc0200eb4 <buddy_check+0x2bc>
ffffffffc0200ea2:	0009b683          	ld	a3,0(s3)
ffffffffc0200ea6:	00269713          	slli	a4,a3,0x2
ffffffffc0200eaa:	9736                	add	a4,a4,a3
ffffffffc0200eac:	070e                	slli	a4,a4,0x3
ffffffffc0200eae:	97ba                	add	a5,a5,a4
ffffffffc0200eb0:	6efce063          	bltu	s9,a5,ffffffffc0201590 <buddy_check+0x998>
    for (size_t j = 0; j < 4; j++) {
ffffffffc0200eb4:	0d21                	addi	s10,s10,8
ffffffffc0200eb6:	09a1                	addi	s3,s3,8
ffffffffc0200eb8:	febd11e3          	bne	s10,a1,ffffffffc0200e9a <buddy_check+0x2a2>
               allocated[j] + blocks[j] <= allocated[4]);
    }
    assert(buddy_nr_free_pages() == 0);
ffffffffc0200ebc:	00093783          	ld	a5,0(s2)
ffffffffc0200ec0:	6a079863          	bnez	a5,ffffffffc0201570 <buddy_check+0x978>
    assert(n > 0);
ffffffffc0200ec4:	4505                	li	a0,1
ffffffffc0200ec6:	c35ff0ef          	jal	ra,ffffffffc0200afa <buddy_alloc_pages.part.0>
    assert(buddy_alloc_pages(1) == NULL);
ffffffffc0200eca:	30051363          	bnez	a0,ffffffffc02011d0 <buddy_check+0x5d8>
    return buddy_free_count;
ffffffffc0200ece:	00093a03          	ld	s4,0(s2)
    assert(buddy_nr_free_pages() == 0);
ffffffffc0200ed2:	2c0a1f63          	bnez	s4,ffffffffc02011b0 <buddy_check+0x5b8>
    remaining = 0;
    buddy_check_free_lists();
ffffffffc0200ed6:	ff2ff0ef          	jal	ra,ffffffffc02006c8 <buddy_check_free_lists>

    for (size_t i = 5; i > 0; i--) {
        size_t j = i - 1;
        buddy_free_pages(allocated[j], requests[j]);
ffffffffc0200eda:	75e6                	ld	a1,120(sp)
ffffffffc0200edc:	07810993          	addi	s3,sp,120
ffffffffc0200ee0:	0c010a93          	addi	s5,sp,192
ffffffffc0200ee4:	0a010d13          	addi	s10,sp,160
ffffffffc0200ee8:	8566                	mv	a0,s9
    assert(n > 0);
ffffffffc0200eea:	c98d                	beqz	a1,ffffffffc0200f1c <buddy_check+0x324>
ffffffffc0200eec:	8fbff0ef          	jal	ra,ffffffffc02007e6 <buddy_free_pages.part.0>
        remaining += blocks[j];
ffffffffc0200ef0:	000d3703          	ld	a4,0(s10)
        assert(buddy_nr_free_pages() == remaining);
ffffffffc0200ef4:	00093783          	ld	a5,0(s2)
        remaining += blocks[j];
ffffffffc0200ef8:	9a3a                	add	s4,s4,a4
        assert(buddy_nr_free_pages() == remaining);
ffffffffc0200efa:	28fa1b63          	bne	s4,a5,ffffffffc0201190 <buddy_check+0x598>
        buddy_check_free_lists();
ffffffffc0200efe:	fcaff0ef          	jal	ra,ffffffffc02006c8 <buddy_check_free_lists>
    for (size_t i = 5; i > 0; i--) {
ffffffffc0200f02:	08b8                	addi	a4,sp,88
ffffffffc0200f04:	1d61                	addi	s10,s10,-8
ffffffffc0200f06:	ff898793          	addi	a5,s3,-8
ffffffffc0200f0a:	02e98963          	beq	s3,a4,ffffffffc0200f3c <buddy_check+0x344>
        buddy_free_pages(allocated[j], requests[j]);
ffffffffc0200f0e:	89be                	mv	s3,a5
ffffffffc0200f10:	0009b583          	ld	a1,0(s3)
ffffffffc0200f14:	000ab503          	ld	a0,0(s5)
ffffffffc0200f18:	1ae1                	addi	s5,s5,-8
    assert(n > 0);
ffffffffc0200f1a:	f9e9                	bnez	a1,ffffffffc0200eec <buddy_check+0x2f4>
ffffffffc0200f1c:	00001697          	auipc	a3,0x1
ffffffffc0200f20:	0dc68693          	addi	a3,a3,220 # ffffffffc0201ff8 <etext+0x38c>
ffffffffc0200f24:	00001617          	auipc	a2,0x1
ffffffffc0200f28:	fd460613          	addi	a2,a2,-44 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0200f2c:	07700593          	li	a1,119
ffffffffc0200f30:	00001517          	auipc	a0,0x1
ffffffffc0200f34:	fe050513          	addi	a0,a0,-32 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc0200f38:	a8aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    }
    buddy_check_only_block(arena, 4);
ffffffffc0200f3c:	8526                	mv	a0,s1
ffffffffc0200f3e:	ab7ff0ef          	jal	ra,ffffffffc02009f4 <buddy_check_only_block.constprop.0>

    /* Adjacent middle blocks are not buddies: 4..7 and 8..11. */
    struct Page *quarters[4];
    for (size_t i = 0; i < 4; i++) {
ffffffffc0200f42:	6d02                	ld	s10,0(sp)
ffffffffc0200f44:	03810c93          	addi	s9,sp,56
ffffffffc0200f48:	8aa6                	mv	s5,s1
    buddy_check_only_block(arena, 4);
ffffffffc0200f4a:	4a31                	li	s4,12
    for (size_t i = 0; i < 4; i++) {
ffffffffc0200f4c:	59f1                	li	s3,-4
    assert(n > 0);
ffffffffc0200f4e:	4511                	li	a0,4
ffffffffc0200f50:	babff0ef          	jal	ra,ffffffffc0200afa <buddy_alloc_pages.part.0>
        quarters[i] = buddy_alloc_pages(4);
ffffffffc0200f54:	00acb023          	sd	a0,0(s9)
        assert(quarters[i] == arena + 4 * i);
ffffffffc0200f58:	21551c63          	bne	a0,s5,ffffffffc0201170 <buddy_check+0x578>
ffffffffc0200f5c:	000c3783          	ld	a5,0(s8)
ffffffffc0200f60:	40fa87b3          	sub	a5,s5,a5
ffffffffc0200f64:	878d                	srai	a5,a5,0x3
ffffffffc0200f66:	037787b3          	mul	a5,a5,s7
ffffffffc0200f6a:	97ea                	add	a5,a5,s10
        assert((page2ppn(quarters[i]) & 3) == 0);
ffffffffc0200f6c:	8b8d                	andi	a5,a5,3
ffffffffc0200f6e:	1e079163          	bnez	a5,ffffffffc0201150 <buddy_check+0x558>
        assert(buddy_nr_free_pages() == 12 - 4 * i);
ffffffffc0200f72:	00093783          	ld	a5,0(s2)
ffffffffc0200f76:	1b479d63          	bne	a5,s4,ffffffffc0201130 <buddy_check+0x538>
    for (size_t i = 0; i < 4; i++) {
ffffffffc0200f7a:	1a71                	addi	s4,s4,-4
ffffffffc0200f7c:	0ca1                	addi	s9,s9,8
ffffffffc0200f7e:	0a0a8a93          	addi	s5,s5,160
ffffffffc0200f82:	fd3a16e3          	bne	s4,s3,ffffffffc0200f4e <buddy_check+0x356>
    }
    buddy_free_pages(quarters[1], 4);
ffffffffc0200f86:	6a06                	ld	s4,64(sp)
    assert(n > 0);
ffffffffc0200f88:	4591                	li	a1,4
ffffffffc0200f8a:	8552                	mv	a0,s4
ffffffffc0200f8c:	85bff0ef          	jal	ra,ffffffffc02007e6 <buddy_free_pages.part.0>
    buddy_free_pages(quarters[2], 4);
ffffffffc0200f90:	69a6                	ld	s3,72(sp)
    assert(n > 0);
ffffffffc0200f92:	4591                	li	a1,4
ffffffffc0200f94:	854e                	mv	a0,s3
ffffffffc0200f96:	851ff0ef          	jal	ra,ffffffffc02007e6 <buddy_free_pages.part.0>
    assert(buddy_nr_free_pages() == 8);
ffffffffc0200f9a:	00093703          	ld	a4,0(s2)
ffffffffc0200f9e:	47a1                	li	a5,8
ffffffffc0200fa0:	16f71863          	bne	a4,a5,ffffffffc0201110 <buddy_check+0x518>
    assert(PageProperty(quarters[1]) && quarters[1]->property == 4);
ffffffffc0200fa4:	008a3783          	ld	a5,8(s4)
ffffffffc0200fa8:	8b89                	andi	a5,a5,2
ffffffffc0200faa:	40078363          	beqz	a5,ffffffffc02013b0 <buddy_check+0x7b8>
ffffffffc0200fae:	010a2703          	lw	a4,16(s4)
ffffffffc0200fb2:	4791                	li	a5,4
ffffffffc0200fb4:	3ef71e63          	bne	a4,a5,ffffffffc02013b0 <buddy_check+0x7b8>
    assert(PageProperty(quarters[2]) && quarters[2]->property == 4);
ffffffffc0200fb8:	0089b783          	ld	a5,8(s3)
ffffffffc0200fbc:	8b89                	andi	a5,a5,2
ffffffffc0200fbe:	24078963          	beqz	a5,ffffffffc0201210 <buddy_check+0x618>
ffffffffc0200fc2:	0109a783          	lw	a5,16(s3)
ffffffffc0200fc6:	24e79563          	bne	a5,a4,ffffffffc0201210 <buddy_check+0x618>
    assert(n > 0);
ffffffffc0200fca:	4521                	li	a0,8
ffffffffc0200fcc:	b2fff0ef          	jal	ra,ffffffffc0200afa <buddy_alloc_pages.part.0>
    assert(buddy_alloc_pages(8) == NULL);
ffffffffc0200fd0:	28051063          	bnez	a0,ffffffffc0201250 <buddy_check+0x658>
    assert(buddy_nr_free_pages() == 8);
ffffffffc0200fd4:	00093983          	ld	s3,0(s2)
ffffffffc0200fd8:	47a1                	li	a5,8
ffffffffc0200fda:	24f99b63          	bne	s3,a5,ffffffffc0201230 <buddy_check+0x638>
    buddy_check_free_lists();
ffffffffc0200fde:	eeaff0ef          	jal	ra,ffffffffc02006c8 <buddy_check_free_lists>
    assert(n > 0);
ffffffffc0200fe2:	7562                	ld	a0,56(sp)
ffffffffc0200fe4:	4591                	li	a1,4
ffffffffc0200fe6:	801ff0ef          	jal	ra,ffffffffc02007e6 <buddy_free_pages.part.0>

    /* Releasing the true buddy permits an 8-page allocation. */
    buddy_free_pages(quarters[0], 4);
    assert(PageProperty(arena) && arena->property == 8);
ffffffffc0200fea:	649c                	ld	a5,8(s1)
ffffffffc0200fec:	8b89                	andi	a5,a5,2
ffffffffc0200fee:	2e078163          	beqz	a5,ffffffffc02012d0 <buddy_check+0x6d8>
ffffffffc0200ff2:	489c                	lw	a5,16(s1)
ffffffffc0200ff4:	2d379e63          	bne	a5,s3,ffffffffc02012d0 <buddy_check+0x6d8>
    assert(buddy_nr_free_pages() == 12);
ffffffffc0200ff8:	00093703          	ld	a4,0(s2)
ffffffffc0200ffc:	47b1                	li	a5,12
ffffffffc0200ffe:	2af71963          	bne	a4,a5,ffffffffc02012b0 <buddy_check+0x6b8>
    assert(n > 0);
ffffffffc0201002:	4521                	li	a0,8
ffffffffc0201004:	af7ff0ef          	jal	ra,ffffffffc0200afa <buddy_alloc_pages.part.0>
    assert(buddy_alloc_pages(8) == arena);
ffffffffc0201008:	28a49463          	bne	s1,a0,ffffffffc0201290 <buddy_check+0x698>
    assert(buddy_nr_free_pages() == 4);
ffffffffc020100c:	00093703          	ld	a4,0(s2)
ffffffffc0201010:	4791                	li	a5,4
ffffffffc0201012:	24f71f63          	bne	a4,a5,ffffffffc0201270 <buddy_check+0x678>
    assert(n > 0);
ffffffffc0201016:	45a1                	li	a1,8
ffffffffc0201018:	fceff0ef          	jal	ra,ffffffffc02007e6 <buddy_free_pages.part.0>
ffffffffc020101c:	6546                	ld	a0,80(sp)
ffffffffc020101e:	4591                	li	a1,4
ffffffffc0201020:	fc6ff0ef          	jal	ra,ffffffffc02007e6 <buddy_free_pages.part.0>
    buddy_free_pages(arena, 8);
    buddy_free_pages(quarters[3], 4);
    buddy_check_only_block(arena, 4);  /* 4+4, then 8+8 */
ffffffffc0201024:	8526                	mv	a0,s1
ffffffffc0201026:	9cfff0ef          	jal	ra,ffffffffc02009f4 <buddy_check_only_block.constprop.0>
    assert(n > 0);
ffffffffc020102a:	4541                	li	a0,16
ffffffffc020102c:	acfff0ef          	jal	ra,ffffffffc0200afa <buddy_alloc_pages.part.0>

    assert(buddy_alloc_pages(16) == arena);
ffffffffc0201030:	42a49063          	bne	s1,a0,ffffffffc0201450 <buddy_check+0x858>
    assert(buddy_nr_free_pages() == 0);
ffffffffc0201034:	00093783          	ld	a5,0(s2)
ffffffffc0201038:	3e079c63          	bnez	a5,ffffffffc0201430 <buddy_check+0x838>
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
        assert(list_empty(&buddy_free_lists[i]));
ffffffffc020103c:	008b3783          	ld	a5,8(s6)
ffffffffc0201040:	09679863          	bne	a5,s6,ffffffffc02010d0 <buddy_check+0x4d8>
        buddy_free_lists[i] = saved_lists[i];
ffffffffc0201044:	000db703          	ld	a4,0(s11)
ffffffffc0201048:	008db783          	ld	a5,8(s11)
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc020104c:	0b41                	addi	s6,s6,16
        buddy_free_lists[i] = saved_lists[i];
ffffffffc020104e:	feeb3823          	sd	a4,-16(s6)
ffffffffc0201052:	fefb3c23          	sd	a5,-8(s6)
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc0201056:	0dc1                	addi	s11,s11,16
ffffffffc0201058:	fe8b12e3          	bne	s6,s0,ffffffffc020103c <buddy_check+0x444>
    }
    buddy_free_count = saved_free;
ffffffffc020105c:	67e2                	ld	a5,24(sp)
ffffffffc020105e:	02000593          	li	a1,32
ffffffffc0201062:	8526                	mv	a0,s1
ffffffffc0201064:	00f93023          	sd	a5,0(s2)
    assert(n > 0);
ffffffffc0201068:	f7eff0ef          	jal	ra,ffffffffc02007e6 <buddy_free_pages.part.0>
    buddy_free_pages(arena, 32);
    assert(buddy_nr_free_pages() == original_free);
ffffffffc020106c:	00093783          	ld	a5,0(s2)
ffffffffc0201070:	6742                	ld	a4,16(sp)
ffffffffc0201072:	46f71f63          	bne	a4,a5,ffffffffc02014f0 <buddy_check+0x8f8>
    buddy_check_free_lists();
ffffffffc0201076:	e52ff0ef          	jal	ra,ffffffffc02006c8 <buddy_check_free_lists>
    cprintf("buddy_check() succeeded!\n");
}
ffffffffc020107a:	33013403          	ld	s0,816(sp)
ffffffffc020107e:	33813083          	ld	ra,824(sp)
ffffffffc0201082:	32813483          	ld	s1,808(sp)
ffffffffc0201086:	32013903          	ld	s2,800(sp)
ffffffffc020108a:	31813983          	ld	s3,792(sp)
ffffffffc020108e:	31013a03          	ld	s4,784(sp)
ffffffffc0201092:	30813a83          	ld	s5,776(sp)
ffffffffc0201096:	30013b03          	ld	s6,768(sp)
ffffffffc020109a:	2f813b83          	ld	s7,760(sp)
ffffffffc020109e:	2f013c03          	ld	s8,752(sp)
ffffffffc02010a2:	2e813c83          	ld	s9,744(sp)
ffffffffc02010a6:	2e013d03          	ld	s10,736(sp)
ffffffffc02010aa:	2d813d83          	ld	s11,728(sp)
    cprintf("buddy_check() succeeded!\n");
ffffffffc02010ae:	00001517          	auipc	a0,0x1
ffffffffc02010b2:	62a50513          	addi	a0,a0,1578 # ffffffffc02026d8 <etext+0xa6c>
}
ffffffffc02010b6:	34010113          	addi	sp,sp,832
    cprintf("buddy_check() succeeded!\n");
ffffffffc02010ba:	892ff06f          	j	ffffffffc020014c <cprintf>
        assert(buddy_nr_free_pages() == remaining);
ffffffffc02010be:	00093783          	ld	a5,0(s2)
        remaining -= blocks[i];
ffffffffc02010c2:	406a0a33          	sub	s4,s4,t1
        assert(buddy_nr_free_pages() == remaining);
ffffffffc02010c6:	45479563          	bne	a5,s4,ffffffffc0201510 <buddy_check+0x918>
        buddy_check_free_lists();
ffffffffc02010ca:	dfeff0ef          	jal	ra,ffffffffc02006c8 <buddy_check_free_lists>
    for (size_t i = 0; i < 4; i++) {
ffffffffc02010ce:	b349                	j	ffffffffc0200e50 <buddy_check+0x258>
        assert(list_empty(&buddy_free_lists[i]));
ffffffffc02010d0:	00001697          	auipc	a3,0x1
ffffffffc02010d4:	5b868693          	addi	a3,a3,1464 # ffffffffc0202688 <etext+0xa1c>
ffffffffc02010d8:	00001617          	auipc	a2,0x1
ffffffffc02010dc:	e2060613          	addi	a2,a2,-480 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02010e0:	12200593          	li	a1,290
ffffffffc02010e4:	00001517          	auipc	a0,0x1
ffffffffc02010e8:	e2c50513          	addi	a0,a0,-468 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02010ec:	8d6ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(allocated[i] + blocks[i] <= allocated[j] ||
ffffffffc02010f0:	00001697          	auipc	a3,0x1
ffffffffc02010f4:	23868693          	addi	a3,a3,568 # ffffffffc0202328 <etext+0x6bc>
ffffffffc02010f8:	00001617          	auipc	a2,0x1
ffffffffc02010fc:	e0060613          	addi	a2,a2,-512 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201100:	0e200593          	li	a1,226
ffffffffc0201104:	00001517          	auipc	a0,0x1
ffffffffc0201108:	e0c50513          	addi	a0,a0,-500 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020110c:	8b6ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == 8);
ffffffffc0201110:	00001697          	auipc	a3,0x1
ffffffffc0201114:	41868693          	addi	a3,a3,1048 # ffffffffc0202528 <etext+0x8bc>
ffffffffc0201118:	00001617          	auipc	a2,0x1
ffffffffc020111c:	de060613          	addi	a2,a2,-544 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201120:	10e00593          	li	a1,270
ffffffffc0201124:	00001517          	auipc	a0,0x1
ffffffffc0201128:	dec50513          	addi	a0,a0,-532 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020112c:	896ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(buddy_nr_free_pages() == 12 - 4 * i);
ffffffffc0201130:	00001697          	auipc	a3,0x1
ffffffffc0201134:	3d068693          	addi	a3,a3,976 # ffffffffc0202500 <etext+0x894>
ffffffffc0201138:	00001617          	auipc	a2,0x1
ffffffffc020113c:	dc060613          	addi	a2,a2,-576 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201140:	10a00593          	li	a1,266
ffffffffc0201144:	00001517          	auipc	a0,0x1
ffffffffc0201148:	dcc50513          	addi	a0,a0,-564 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020114c:	876ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((page2ppn(quarters[i]) & 3) == 0);
ffffffffc0201150:	00001697          	auipc	a3,0x1
ffffffffc0201154:	38868693          	addi	a3,a3,904 # ffffffffc02024d8 <etext+0x86c>
ffffffffc0201158:	00001617          	auipc	a2,0x1
ffffffffc020115c:	da060613          	addi	a2,a2,-608 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201160:	10900593          	li	a1,265
ffffffffc0201164:	00001517          	auipc	a0,0x1
ffffffffc0201168:	dac50513          	addi	a0,a0,-596 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020116c:	856ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(quarters[i] == arena + 4 * i);
ffffffffc0201170:	00001697          	auipc	a3,0x1
ffffffffc0201174:	34868693          	addi	a3,a3,840 # ffffffffc02024b8 <etext+0x84c>
ffffffffc0201178:	00001617          	auipc	a2,0x1
ffffffffc020117c:	d8060613          	addi	a2,a2,-640 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201180:	10800593          	li	a1,264
ffffffffc0201184:	00001517          	auipc	a0,0x1
ffffffffc0201188:	d8c50513          	addi	a0,a0,-628 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020118c:	836ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(buddy_nr_free_pages() == remaining);
ffffffffc0201190:	00001697          	auipc	a3,0x1
ffffffffc0201194:	1f068693          	addi	a3,a3,496 # ffffffffc0202380 <etext+0x714>
ffffffffc0201198:	00001617          	auipc	a2,0x1
ffffffffc020119c:	d6060613          	addi	a2,a2,-672 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02011a0:	0ff00593          	li	a1,255
ffffffffc02011a4:	00001517          	auipc	a0,0x1
ffffffffc02011a8:	d6c50513          	addi	a0,a0,-660 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02011ac:	816ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == 0);
ffffffffc02011b0:	00001697          	auipc	a3,0x1
ffffffffc02011b4:	2c868693          	addi	a3,a3,712 # ffffffffc0202478 <etext+0x80c>
ffffffffc02011b8:	00001617          	auipc	a2,0x1
ffffffffc02011bc:	d4060613          	addi	a2,a2,-704 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02011c0:	0f700593          	li	a1,247
ffffffffc02011c4:	00001517          	auipc	a0,0x1
ffffffffc02011c8:	d4c50513          	addi	a0,a0,-692 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02011cc:	ff7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_alloc_pages(1) == NULL);
ffffffffc02011d0:	00001697          	auipc	a3,0x1
ffffffffc02011d4:	2c868693          	addi	a3,a3,712 # ffffffffc0202498 <etext+0x82c>
ffffffffc02011d8:	00001617          	auipc	a2,0x1
ffffffffc02011dc:	d2060613          	addi	a2,a2,-736 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02011e0:	0f600593          	li	a1,246
ffffffffc02011e4:	00001517          	auipc	a0,0x1
ffffffffc02011e8:	d2c50513          	addi	a0,a0,-724 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02011ec:	fd7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == remaining);
ffffffffc02011f0:	00001697          	auipc	a3,0x1
ffffffffc02011f4:	19068693          	addi	a3,a3,400 # ffffffffc0202380 <etext+0x714>
ffffffffc02011f8:	00001617          	auipc	a2,0x1
ffffffffc02011fc:	d0060613          	addi	a2,a2,-768 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201200:	0eb00593          	li	a1,235
ffffffffc0201204:	00001517          	auipc	a0,0x1
ffffffffc0201208:	d0c50513          	addi	a0,a0,-756 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020120c:	fb7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(quarters[2]) && quarters[2]->property == 4);
ffffffffc0201210:	00001697          	auipc	a3,0x1
ffffffffc0201214:	37068693          	addi	a3,a3,880 # ffffffffc0202580 <etext+0x914>
ffffffffc0201218:	00001617          	auipc	a2,0x1
ffffffffc020121c:	ce060613          	addi	a2,a2,-800 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201220:	11000593          	li	a1,272
ffffffffc0201224:	00001517          	auipc	a0,0x1
ffffffffc0201228:	cec50513          	addi	a0,a0,-788 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020122c:	f97fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == 8);
ffffffffc0201230:	00001697          	auipc	a3,0x1
ffffffffc0201234:	2f868693          	addi	a3,a3,760 # ffffffffc0202528 <etext+0x8bc>
ffffffffc0201238:	00001617          	auipc	a2,0x1
ffffffffc020123c:	cc060613          	addi	a2,a2,-832 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201240:	11200593          	li	a1,274
ffffffffc0201244:	00001517          	auipc	a0,0x1
ffffffffc0201248:	ccc50513          	addi	a0,a0,-820 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020124c:	f77fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_alloc_pages(8) == NULL);
ffffffffc0201250:	00001697          	auipc	a3,0x1
ffffffffc0201254:	36868693          	addi	a3,a3,872 # ffffffffc02025b8 <etext+0x94c>
ffffffffc0201258:	00001617          	auipc	a2,0x1
ffffffffc020125c:	ca060613          	addi	a2,a2,-864 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201260:	11100593          	li	a1,273
ffffffffc0201264:	00001517          	auipc	a0,0x1
ffffffffc0201268:	cac50513          	addi	a0,a0,-852 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020126c:	f57fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == 4);
ffffffffc0201270:	00001697          	auipc	a3,0x1
ffffffffc0201274:	3d868693          	addi	a3,a3,984 # ffffffffc0202648 <etext+0x9dc>
ffffffffc0201278:	00001617          	auipc	a2,0x1
ffffffffc020127c:	c8060613          	addi	a2,a2,-896 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201280:	11a00593          	li	a1,282
ffffffffc0201284:	00001517          	auipc	a0,0x1
ffffffffc0201288:	c8c50513          	addi	a0,a0,-884 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020128c:	f37fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_alloc_pages(8) == arena);
ffffffffc0201290:	00001697          	auipc	a3,0x1
ffffffffc0201294:	39868693          	addi	a3,a3,920 # ffffffffc0202628 <etext+0x9bc>
ffffffffc0201298:	00001617          	auipc	a2,0x1
ffffffffc020129c:	c6060613          	addi	a2,a2,-928 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02012a0:	11900593          	li	a1,281
ffffffffc02012a4:	00001517          	auipc	a0,0x1
ffffffffc02012a8:	c6c50513          	addi	a0,a0,-916 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02012ac:	f17fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == 12);
ffffffffc02012b0:	00001697          	auipc	a3,0x1
ffffffffc02012b4:	35868693          	addi	a3,a3,856 # ffffffffc0202608 <etext+0x99c>
ffffffffc02012b8:	00001617          	auipc	a2,0x1
ffffffffc02012bc:	c4060613          	addi	a2,a2,-960 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02012c0:	11800593          	li	a1,280
ffffffffc02012c4:	00001517          	auipc	a0,0x1
ffffffffc02012c8:	c4c50513          	addi	a0,a0,-948 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02012cc:	ef7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(arena) && arena->property == 8);
ffffffffc02012d0:	00001697          	auipc	a3,0x1
ffffffffc02012d4:	30868693          	addi	a3,a3,776 # ffffffffc02025d8 <etext+0x96c>
ffffffffc02012d8:	00001617          	auipc	a2,0x1
ffffffffc02012dc:	c2060613          	addi	a2,a2,-992 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02012e0:	11700593          	li	a1,279
ffffffffc02012e4:	00001517          	auipc	a0,0x1
ffffffffc02012e8:	c2c50513          	addi	a0,a0,-980 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02012ec:	ed7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(PageProperty(sibling) &&
ffffffffc02012f0:	00001697          	auipc	a3,0x1
ffffffffc02012f4:	f0068693          	addi	a3,a3,-256 # ffffffffc02021f0 <etext+0x584>
ffffffffc02012f8:	00001617          	auipc	a2,0x1
ffffffffc02012fc:	c0060613          	addi	a2,a2,-1024 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201300:	0ce00593          	li	a1,206
ffffffffc0201304:	00001517          	auipc	a0,0x1
ffffffffc0201308:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020130c:	eb7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_next(&sibling->page_link) == head);
ffffffffc0201310:	00001697          	auipc	a3,0x1
ffffffffc0201314:	eb868693          	addi	a3,a3,-328 # ffffffffc02021c8 <etext+0x55c>
ffffffffc0201318:	00001617          	auipc	a2,0x1
ffffffffc020131c:	be060613          	addi	a2,a2,-1056 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201320:	0cd00593          	li	a1,205
ffffffffc0201324:	00001517          	auipc	a0,0x1
ffffffffc0201328:	bec50513          	addi	a0,a0,-1044 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020132c:	e97fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_next(head) == &sibling->page_link);
ffffffffc0201330:	00001697          	auipc	a3,0x1
ffffffffc0201334:	e7068693          	addi	a3,a3,-400 # ffffffffc02021a0 <etext+0x534>
ffffffffc0201338:	00001617          	auipc	a2,0x1
ffffffffc020133c:	bc060613          	addi	a2,a2,-1088 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201340:	0cc00593          	li	a1,204
ffffffffc0201344:	00001517          	auipc	a0,0x1
ffffffffc0201348:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020134c:	e77fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0201350:	00001697          	auipc	a3,0x1
ffffffffc0201354:	ca868693          	addi	a3,a3,-856 # ffffffffc0201ff8 <etext+0x38c>
ffffffffc0201358:	00001617          	auipc	a2,0x1
ffffffffc020135c:	ba060613          	addi	a2,a2,-1120 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201360:	05600593          	li	a1,86
ffffffffc0201364:	00001517          	auipc	a0,0x1
ffffffffc0201368:	bac50513          	addi	a0,a0,-1108 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020136c:	e57fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(list_empty(&buddy_free_lists[4]));
ffffffffc0201370:	00001697          	auipc	a3,0x1
ffffffffc0201374:	f0868693          	addi	a3,a3,-248 # ffffffffc0202278 <etext+0x60c>
ffffffffc0201378:	00001617          	auipc	a2,0x1
ffffffffc020137c:	b8060613          	addi	a2,a2,-1152 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201380:	0d200593          	li	a1,210
ffffffffc0201384:	00001517          	auipc	a0,0x1
ffffffffc0201388:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020138c:	e37fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(allocated[i] != NULL);
ffffffffc0201390:	00001697          	auipc	a3,0x1
ffffffffc0201394:	f1068693          	addi	a3,a3,-240 # ffffffffc02022a0 <etext+0x634>
ffffffffc0201398:	00001617          	auipc	a2,0x1
ffffffffc020139c:	b6060613          	addi	a2,a2,-1184 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02013a0:	0de00593          	li	a1,222
ffffffffc02013a4:	00001517          	auipc	a0,0x1
ffffffffc02013a8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02013ac:	e17fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(quarters[1]) && quarters[1]->property == 4);
ffffffffc02013b0:	00001697          	auipc	a3,0x1
ffffffffc02013b4:	19868693          	addi	a3,a3,408 # ffffffffc0202548 <etext+0x8dc>
ffffffffc02013b8:	00001617          	auipc	a2,0x1
ffffffffc02013bc:	b4060613          	addi	a2,a2,-1216 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02013c0:	10f00593          	li	a1,271
ffffffffc02013c4:	00001517          	auipc	a0,0x1
ffffffffc02013c8:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02013cc:	df7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(original_free >= 32);
ffffffffc02013d0:	00001697          	auipc	a3,0x1
ffffffffc02013d4:	d1868693          	addi	a3,a3,-744 # ffffffffc02020e8 <etext+0x47c>
ffffffffc02013d8:	00001617          	auipc	a2,0x1
ffffffffc02013dc:	b2060613          	addi	a2,a2,-1248 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02013e0:	0b300593          	li	a1,179
ffffffffc02013e4:	00001517          	auipc	a0,0x1
ffffffffc02013e8:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02013ec:	dd7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(allocated[i] >= arena && allocated[i] + blocks[i] <= arena + 16);
ffffffffc02013f0:	00001697          	auipc	a3,0x1
ffffffffc02013f4:	ef868693          	addi	a3,a3,-264 # ffffffffc02022e8 <etext+0x67c>
ffffffffc02013f8:	00001617          	auipc	a2,0x1
ffffffffc02013fc:	b0060613          	addi	a2,a2,-1280 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201400:	0e000593          	li	a1,224
ffffffffc0201404:	00001517          	auipc	a0,0x1
ffffffffc0201408:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020140c:	db7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((page2ppn(allocated[i]) & (blocks[i] - 1)) == 0);
ffffffffc0201410:	00001697          	auipc	a3,0x1
ffffffffc0201414:	ea868693          	addi	a3,a3,-344 # ffffffffc02022b8 <etext+0x64c>
ffffffffc0201418:	00001617          	auipc	a2,0x1
ffffffffc020141c:	ae060613          	addi	a2,a2,-1312 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201420:	0df00593          	li	a1,223
ffffffffc0201424:	00001517          	auipc	a0,0x1
ffffffffc0201428:	aec50513          	addi	a0,a0,-1300 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020142c:	d97fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == 0);
ffffffffc0201430:	00001697          	auipc	a3,0x1
ffffffffc0201434:	04868693          	addi	a3,a3,72 # ffffffffc0202478 <etext+0x80c>
ffffffffc0201438:	00001617          	auipc	a2,0x1
ffffffffc020143c:	ac060613          	addi	a2,a2,-1344 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201440:	12000593          	li	a1,288
ffffffffc0201444:	00001517          	auipc	a0,0x1
ffffffffc0201448:	acc50513          	addi	a0,a0,-1332 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020144c:	d77fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_alloc_pages(16) == arena);
ffffffffc0201450:	00001697          	auipc	a3,0x1
ffffffffc0201454:	21868693          	addi	a3,a3,536 # ffffffffc0202668 <etext+0x9fc>
ffffffffc0201458:	00001617          	auipc	a2,0x1
ffffffffc020145c:	aa060613          	addi	a2,a2,-1376 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201460:	11f00593          	li	a1,287
ffffffffc0201464:	00001517          	auipc	a0,0x1
ffffffffc0201468:	aac50513          	addi	a0,a0,-1364 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020146c:	d57fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_alloc_pages(1) == arena);
ffffffffc0201470:	00001697          	auipc	a3,0x1
ffffffffc0201474:	cf068693          	addi	a3,a3,-784 # ffffffffc0202160 <etext+0x4f4>
ffffffffc0201478:	00001617          	auipc	a2,0x1
ffffffffc020147c:	a8060613          	addi	a2,a2,-1408 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201480:	0c700593          	li	a1,199
ffffffffc0201484:	00001517          	auipc	a0,0x1
ffffffffc0201488:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020148c:	d37fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == original_free - 32);
ffffffffc0201490:	00001697          	auipc	a3,0x1
ffffffffc0201494:	ca068693          	addi	a3,a3,-864 # ffffffffc0202130 <etext+0x4c4>
ffffffffc0201498:	00001617          	auipc	a2,0x1
ffffffffc020149c:	a6060613          	addi	a2,a2,-1440 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02014a0:	0b900593          	li	a1,185
ffffffffc02014a4:	00001517          	auipc	a0,0x1
ffffffffc02014a8:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02014ac:	d17fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(arena != NULL && (page2ppn(arena) & 31) == 0);
ffffffffc02014b0:	00001697          	auipc	a3,0x1
ffffffffc02014b4:	c5068693          	addi	a3,a3,-944 # ffffffffc0202100 <etext+0x494>
ffffffffc02014b8:	00001617          	auipc	a2,0x1
ffffffffc02014bc:	a4060613          	addi	a2,a2,-1472 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02014c0:	0b800593          	li	a1,184
ffffffffc02014c4:	00001517          	auipc	a0,0x1
ffffffffc02014c8:	a4c50513          	addi	a0,a0,-1460 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02014cc:	cf7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == 15);
ffffffffc02014d0:	00001697          	auipc	a3,0x1
ffffffffc02014d4:	cb068693          	addi	a3,a3,-848 # ffffffffc0202180 <etext+0x514>
ffffffffc02014d8:	00001617          	auipc	a2,0x1
ffffffffc02014dc:	a2060613          	addi	a2,a2,-1504 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02014e0:	0c800593          	li	a1,200
ffffffffc02014e4:	00001517          	auipc	a0,0x1
ffffffffc02014e8:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02014ec:	cd7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == original_free);
ffffffffc02014f0:	00001697          	auipc	a3,0x1
ffffffffc02014f4:	1c068693          	addi	a3,a3,448 # ffffffffc02026b0 <etext+0xa44>
ffffffffc02014f8:	00001617          	auipc	a2,0x1
ffffffffc02014fc:	a0060613          	addi	a2,a2,-1536 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201500:	12700593          	li	a1,295
ffffffffc0201504:	00001517          	auipc	a0,0x1
ffffffffc0201508:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020150c:	cb7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(buddy_nr_free_pages() == remaining);
ffffffffc0201510:	00001697          	auipc	a3,0x1
ffffffffc0201514:	e7068693          	addi	a3,a3,-400 # ffffffffc0202380 <etext+0x714>
ffffffffc0201518:	00001617          	auipc	a2,0x1
ffffffffc020151c:	9e060613          	addi	a2,a2,-1568 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201520:	0e600593          	li	a1,230
ffffffffc0201524:	00001517          	auipc	a0,0x1
ffffffffc0201528:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020152c:	c97fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_alloc_pages(2) == NULL);
ffffffffc0201530:	00001697          	auipc	a3,0x1
ffffffffc0201534:	e8868693          	addi	a3,a3,-376 # ffffffffc02023b8 <etext+0x74c>
ffffffffc0201538:	00001617          	auipc	a2,0x1
ffffffffc020153c:	9c060613          	addi	a2,a2,-1600 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201540:	0ea00593          	li	a1,234
ffffffffc0201544:	00001517          	auipc	a0,0x1
ffffffffc0201548:	9cc50513          	addi	a0,a0,-1588 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020154c:	c77fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(remaining == 1);
ffffffffc0201550:	00001697          	auipc	a3,0x1
ffffffffc0201554:	e5868693          	addi	a3,a3,-424 # ffffffffc02023a8 <etext+0x73c>
ffffffffc0201558:	00001617          	auipc	a2,0x1
ffffffffc020155c:	9a060613          	addi	a2,a2,-1632 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201560:	0e900593          	li	a1,233
ffffffffc0201564:	00001517          	auipc	a0,0x1
ffffffffc0201568:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020156c:	c57fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == 0);
ffffffffc0201570:	00001697          	auipc	a3,0x1
ffffffffc0201574:	f0868693          	addi	a3,a3,-248 # ffffffffc0202478 <etext+0x80c>
ffffffffc0201578:	00001617          	auipc	a2,0x1
ffffffffc020157c:	98060613          	addi	a2,a2,-1664 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc0201580:	0f500593          	li	a1,245
ffffffffc0201584:	00001517          	auipc	a0,0x1
ffffffffc0201588:	98c50513          	addi	a0,a0,-1652 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc020158c:	c37fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(allocated[4] + 1 <= allocated[j] ||
ffffffffc0201590:	00001697          	auipc	a3,0x1
ffffffffc0201594:	e9868693          	addi	a3,a3,-360 # ffffffffc0202428 <etext+0x7bc>
ffffffffc0201598:	00001617          	auipc	a2,0x1
ffffffffc020159c:	96060613          	addi	a2,a2,-1696 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02015a0:	0f200593          	li	a1,242
ffffffffc02015a4:	00001517          	auipc	a0,0x1
ffffffffc02015a8:	96c50513          	addi	a0,a0,-1684 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02015ac:	c17fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(allocated[4] != NULL && allocated[4] >= arena &&
ffffffffc02015b0:	00001697          	auipc	a3,0x1
ffffffffc02015b4:	e2868693          	addi	a3,a3,-472 # ffffffffc02023d8 <etext+0x76c>
ffffffffc02015b8:	00001617          	auipc	a2,0x1
ffffffffc02015bc:	94060613          	addi	a2,a2,-1728 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02015c0:	0ef00593          	li	a1,239
ffffffffc02015c4:	00001517          	auipc	a0,0x1
ffffffffc02015c8:	94c50513          	addi	a0,a0,-1716 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02015cc:	bf7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((page2ppn(sibling) & (buddy_block_size(order) - 1)) == 0);
ffffffffc02015d0:	00001697          	auipc	a3,0x1
ffffffffc02015d4:	c6868693          	addi	a3,a3,-920 # ffffffffc0202238 <etext+0x5cc>
ffffffffc02015d8:	00001617          	auipc	a2,0x1
ffffffffc02015dc:	92060613          	addi	a2,a2,-1760 # ffffffffc0201ef8 <etext+0x28c>
ffffffffc02015e0:	0d000593          	li	a1,208
ffffffffc02015e4:	00001517          	auipc	a0,0x1
ffffffffc02015e8:	92c50513          	addi	a0,a0,-1748 # ffffffffc0201f10 <etext+0x2a4>
ffffffffc02015ec:	bd7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02015f0 <pmm_init>:

static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &buddy_pmm_manager;
ffffffffc02015f0:	00001797          	auipc	a5,0x1
ffffffffc02015f4:	17078793          	addi	a5,a5,368 # ffffffffc0202760 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02015f8:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(free_start), (free_end - free_start) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02015fa:	7179                	addi	sp,sp,-48
ffffffffc02015fc:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02015fe:	00001517          	auipc	a0,0x1
ffffffffc0201602:	19a50513          	addi	a0,a0,410 # ffffffffc0202798 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0201606:	00005417          	auipc	s0,0x5
ffffffffc020160a:	c4240413          	addi	s0,s0,-958 # ffffffffc0206248 <pmm_manager>
void pmm_init(void) {
ffffffffc020160e:	f406                	sd	ra,40(sp)
ffffffffc0201610:	ec26                	sd	s1,24(sp)
ffffffffc0201612:	e84a                	sd	s2,16(sp)
ffffffffc0201614:	e44e                	sd	s3,8(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0201616:	e01c                	sd	a5,0(s0)
void pmm_init(void) {
ffffffffc0201618:	e052                	sd	s4,0(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020161a:	b33fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc020161e:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201620:	00005497          	auipc	s1,0x5
ffffffffc0201624:	c4048493          	addi	s1,s1,-960 # ffffffffc0206260 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201628:	679c                	ld	a5,8(a5)
ffffffffc020162a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020162c:	57f5                	li	a5,-3
ffffffffc020162e:	07fa                	slli	a5,a5,0x1e
ffffffffc0201630:	e09c                	sd	a5,0(s1)
    uint64_t mem_base = get_memory_base();
ffffffffc0201632:	f8bfe0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0201636:	89aa                	mv	s3,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0201638:	f8ffe0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_base == 0 || mem_size == 0 || mem_base < DRAM_BASE) {
ffffffffc020163c:	800007b7          	lui	a5,0x80000
ffffffffc0201640:	fff7c793          	not	a5,a5
    uint64_t mem_size = get_memory_size();
ffffffffc0201644:	892a                	mv	s2,a0
    if (mem_base == 0 || mem_size == 0 || mem_base < DRAM_BASE) {
ffffffffc0201646:	1337f663          	bgeu	a5,s3,ffffffffc0201772 <pmm_init+0x182>
ffffffffc020164a:	12050463          	beqz	a0,ffffffffc0201772 <pmm_init+0x182>
    uint64_t mem_end = mem_base + mem_size;
ffffffffc020164e:	47c5                	li	a5,17
ffffffffc0201650:	00a98a33          	add	s4,s3,a0
    if (mem_end > PHYSICAL_MEMORY_END) {
ffffffffc0201654:	07ee                	slli	a5,a5,0x1b
ffffffffc0201656:	0f47e963          	bltu	a5,s4,ffffffffc0201748 <pmm_init+0x158>
    cprintf("physical memory map:\n");
ffffffffc020165a:	00001517          	auipc	a0,0x1
ffffffffc020165e:	1ae50513          	addi	a0,a0,430 # ffffffffc0202808 <buddy_pmm_manager+0xa8>
ffffffffc0201662:	aebfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_base,
ffffffffc0201666:	fffa0693          	addi	a3,s4,-1
ffffffffc020166a:	864e                	mv	a2,s3
ffffffffc020166c:	85ca                	mv	a1,s2
ffffffffc020166e:	00001517          	auipc	a0,0x1
ffffffffc0201672:	1b250513          	addi	a0,a0,434 # ffffffffc0202820 <buddy_pmm_manager+0xc0>
ffffffffc0201676:	ad7fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = ROUNDDOWN(mem_end, PGSIZE) / PGSIZE;
ffffffffc020167a:	777d                	lui	a4,0xfffff
ffffffffc020167c:	00006797          	auipc	a5,0x6
ffffffffc0201680:	beb78793          	addi	a5,a5,-1045 # ffffffffc0207267 <end+0xfff>
ffffffffc0201684:	8ff9                	and	a5,a5,a4
ffffffffc0201686:	00ca5613          	srli	a2,s4,0xc
    size_t nr_desc = npage - nbase;
ffffffffc020168a:	fff805b7          	lui	a1,0xfff80
    npage = ROUNDDOWN(mem_end, PGSIZE) / PGSIZE;
ffffffffc020168e:	00005717          	auipc	a4,0x5
ffffffffc0201692:	bac73523          	sd	a2,-1110(a4) # ffffffffc0206238 <npage>
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0201696:	00005717          	auipc	a4,0x5
ffffffffc020169a:	baf73523          	sd	a5,-1110(a4) # ffffffffc0206240 <pages>
    size_t nr_desc = npage - nbase;
ffffffffc020169e:	00b606b3          	add	a3,a2,a1
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02016a2:	853e                	mv	a0,a5
    for (i = 0; i < nr_desc; i++) {
ffffffffc02016a4:	c685                	beqz	a3,ffffffffc02016cc <pmm_init+0xdc>
ffffffffc02016a6:	00261593          	slli	a1,a2,0x2
ffffffffc02016aa:	95b2                	add	a1,a1,a2
ffffffffc02016ac:	fec00737          	lui	a4,0xfec00
ffffffffc02016b0:	973e                	add	a4,a4,a5
ffffffffc02016b2:	058e                	slli	a1,a1,0x3
ffffffffc02016b4:	972e                	add	a4,a4,a1
        SetPageReserved(p);
ffffffffc02016b6:	4805                	li	a6,1
        p->property = 0;
ffffffffc02016b8:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02016bc:	0007a023          	sw	zero,0(a5)
        SetPageReserved(p);
ffffffffc02016c0:	0107b423          	sd	a6,8(a5)
    for (i = 0; i < nr_desc; i++) {
ffffffffc02016c4:	02878793          	addi	a5,a5,40
ffffffffc02016c8:	fef718e3          	bne	a4,a5,ffffffffc02016b8 <pmm_init+0xc8>
    uintptr_t free_start = ROUNDUP(PADDR(pages + nr_desc), PGSIZE);
ffffffffc02016cc:	00269593          	slli	a1,a3,0x2
ffffffffc02016d0:	95b6                	add	a1,a1,a3
ffffffffc02016d2:	058e                	slli	a1,a1,0x3
ffffffffc02016d4:	00b506b3          	add	a3,a0,a1
ffffffffc02016d8:	c02007b7          	lui	a5,0xc0200
ffffffffc02016dc:	0af6e963          	bltu	a3,a5,ffffffffc020178e <pmm_init+0x19e>
ffffffffc02016e0:	609c                	ld	a5,0(s1)
ffffffffc02016e2:	6585                	lui	a1,0x1
ffffffffc02016e4:	15fd                	addi	a1,a1,-1
ffffffffc02016e6:	8d9d                	sub	a1,a1,a5
ffffffffc02016e8:	95b6                	add	a1,a1,a3
ffffffffc02016ea:	76fd                	lui	a3,0xfffff
ffffffffc02016ec:	8df5                	and	a1,a1,a3
    uintptr_t free_end = npage * PGSIZE;
ffffffffc02016ee:	00c61793          	slli	a5,a2,0xc
    if (free_start < free_end) {
ffffffffc02016f2:	04f5ed63          	bltu	a1,a5,ffffffffc020174c <pmm_init+0x15c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02016f6:	601c                	ld	a5,0(s0)
ffffffffc02016f8:	7b9c                	ld	a5,48(a5)
ffffffffc02016fa:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02016fc:	00001517          	auipc	a0,0x1
ffffffffc0201700:	1ac50513          	addi	a0,a0,428 # ffffffffc02028a8 <buddy_pmm_manager+0x148>
ffffffffc0201704:	a49fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201708:	00004597          	auipc	a1,0x4
ffffffffc020170c:	8f858593          	addi	a1,a1,-1800 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201710:	00005797          	auipc	a5,0x5
ffffffffc0201714:	b4b7b423          	sd	a1,-1208(a5) # ffffffffc0206258 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201718:	c02007b7          	lui	a5,0xc0200
ffffffffc020171c:	08f5e563          	bltu	a1,a5,ffffffffc02017a6 <pmm_init+0x1b6>
ffffffffc0201720:	6090                	ld	a2,0(s1)
}
ffffffffc0201722:	7402                	ld	s0,32(sp)
ffffffffc0201724:	70a2                	ld	ra,40(sp)
ffffffffc0201726:	64e2                	ld	s1,24(sp)
ffffffffc0201728:	6942                	ld	s2,16(sp)
ffffffffc020172a:	69a2                	ld	s3,8(sp)
ffffffffc020172c:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020172e:	40c58633          	sub	a2,a1,a2
ffffffffc0201732:	00005797          	auipc	a5,0x5
ffffffffc0201736:	b0c7bf23          	sd	a2,-1250(a5) # ffffffffc0206250 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020173a:	00001517          	auipc	a0,0x1
ffffffffc020173e:	18e50513          	addi	a0,a0,398 # ffffffffc02028c8 <buddy_pmm_manager+0x168>
}
ffffffffc0201742:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201744:	a09fe06f          	j	ffffffffc020014c <cprintf>
ffffffffc0201748:	8a3e                	mv	s4,a5
ffffffffc020174a:	bf01                	j	ffffffffc020165a <pmm_init+0x6a>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020174c:	00c5d713          	srli	a4,a1,0xc
ffffffffc0201750:	06c77863          	bgeu	a4,a2,ffffffffc02017c0 <pmm_init+0x1d0>
    pmm_manager->init_memmap(base, n);
ffffffffc0201754:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201756:	fff806b7          	lui	a3,0xfff80
ffffffffc020175a:	96ba                	add	a3,a3,a4
ffffffffc020175c:	00269713          	slli	a4,a3,0x2
ffffffffc0201760:	9736                	add	a4,a4,a3
ffffffffc0201762:	6a14                	ld	a3,16(a2)
        init_memmap(pa2page(free_start), (free_end - free_start) / PGSIZE);
ffffffffc0201764:	40b785b3          	sub	a1,a5,a1
ffffffffc0201768:	070e                	slli	a4,a4,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020176a:	81b1                	srli	a1,a1,0xc
ffffffffc020176c:	953a                	add	a0,a0,a4
ffffffffc020176e:	9682                	jalr	a3
}
ffffffffc0201770:	b759                	j	ffffffffc02016f6 <pmm_init+0x106>
        panic("page_init: invalid physical memory info (base=0x%lx, size=0x%lx)",
ffffffffc0201772:	874a                	mv	a4,s2
ffffffffc0201774:	86ce                	mv	a3,s3
ffffffffc0201776:	00001617          	auipc	a2,0x1
ffffffffc020177a:	03a60613          	addi	a2,a2,58 # ffffffffc02027b0 <buddy_pmm_manager+0x50>
ffffffffc020177e:	05200593          	li	a1,82
ffffffffc0201782:	00001517          	auipc	a0,0x1
ffffffffc0201786:	07650513          	addi	a0,a0,118 # ffffffffc02027f8 <buddy_pmm_manager+0x98>
ffffffffc020178a:	a39fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t free_start = ROUNDUP(PADDR(pages + nr_desc), PGSIZE);
ffffffffc020178e:	00001617          	auipc	a2,0x1
ffffffffc0201792:	0c260613          	addi	a2,a2,194 # ffffffffc0202850 <buddy_pmm_manager+0xf0>
ffffffffc0201796:	07600593          	li	a1,118
ffffffffc020179a:	00001517          	auipc	a0,0x1
ffffffffc020179e:	05e50513          	addi	a0,a0,94 # ffffffffc02027f8 <buddy_pmm_manager+0x98>
ffffffffc02017a2:	a21fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02017a6:	86ae                	mv	a3,a1
ffffffffc02017a8:	00001617          	auipc	a2,0x1
ffffffffc02017ac:	0a860613          	addi	a2,a2,168 # ffffffffc0202850 <buddy_pmm_manager+0xf0>
ffffffffc02017b0:	09100593          	li	a1,145
ffffffffc02017b4:	00001517          	auipc	a0,0x1
ffffffffc02017b8:	04450513          	addi	a0,a0,68 # ffffffffc02027f8 <buddy_pmm_manager+0x98>
ffffffffc02017bc:	a07fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02017c0:	00001617          	auipc	a2,0x1
ffffffffc02017c4:	0b860613          	addi	a2,a2,184 # ffffffffc0202878 <buddy_pmm_manager+0x118>
ffffffffc02017c8:	06a00593          	li	a1,106
ffffffffc02017cc:	00001517          	auipc	a0,0x1
ffffffffc02017d0:	0cc50513          	addi	a0,a0,204 # ffffffffc0202898 <buddy_pmm_manager+0x138>
ffffffffc02017d4:	9effe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02017d8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02017d8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02017dc:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02017de:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02017e2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02017e4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02017e8:	f022                	sd	s0,32(sp)
ffffffffc02017ea:	ec26                	sd	s1,24(sp)
ffffffffc02017ec:	e84a                	sd	s2,16(sp)
ffffffffc02017ee:	f406                	sd	ra,40(sp)
ffffffffc02017f0:	e44e                	sd	s3,8(sp)
ffffffffc02017f2:	84aa                	mv	s1,a0
ffffffffc02017f4:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02017f6:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02017fa:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02017fc:	03067e63          	bgeu	a2,a6,ffffffffc0201838 <printnum+0x60>
ffffffffc0201800:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201802:	00805763          	blez	s0,ffffffffc0201810 <printnum+0x38>
ffffffffc0201806:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201808:	85ca                	mv	a1,s2
ffffffffc020180a:	854e                	mv	a0,s3
ffffffffc020180c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020180e:	fc65                	bnez	s0,ffffffffc0201806 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201810:	1a02                	slli	s4,s4,0x20
ffffffffc0201812:	00001797          	auipc	a5,0x1
ffffffffc0201816:	0f678793          	addi	a5,a5,246 # ffffffffc0202908 <buddy_pmm_manager+0x1a8>
ffffffffc020181a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020181e:	9a3e                	add	s4,s4,a5
}
ffffffffc0201820:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201822:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201826:	70a2                	ld	ra,40(sp)
ffffffffc0201828:	69a2                	ld	s3,8(sp)
ffffffffc020182a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020182c:	85ca                	mv	a1,s2
ffffffffc020182e:	87a6                	mv	a5,s1
}
ffffffffc0201830:	6942                	ld	s2,16(sp)
ffffffffc0201832:	64e2                	ld	s1,24(sp)
ffffffffc0201834:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201836:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201838:	03065633          	divu	a2,a2,a6
ffffffffc020183c:	8722                	mv	a4,s0
ffffffffc020183e:	f9bff0ef          	jal	ra,ffffffffc02017d8 <printnum>
ffffffffc0201842:	b7f9                	j	ffffffffc0201810 <printnum+0x38>

ffffffffc0201844 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201844:	7119                	addi	sp,sp,-128
ffffffffc0201846:	f4a6                	sd	s1,104(sp)
ffffffffc0201848:	f0ca                	sd	s2,96(sp)
ffffffffc020184a:	ecce                	sd	s3,88(sp)
ffffffffc020184c:	e8d2                	sd	s4,80(sp)
ffffffffc020184e:	e4d6                	sd	s5,72(sp)
ffffffffc0201850:	e0da                	sd	s6,64(sp)
ffffffffc0201852:	fc5e                	sd	s7,56(sp)
ffffffffc0201854:	f06a                	sd	s10,32(sp)
ffffffffc0201856:	fc86                	sd	ra,120(sp)
ffffffffc0201858:	f8a2                	sd	s0,112(sp)
ffffffffc020185a:	f862                	sd	s8,48(sp)
ffffffffc020185c:	f466                	sd	s9,40(sp)
ffffffffc020185e:	ec6e                	sd	s11,24(sp)
ffffffffc0201860:	892a                	mv	s2,a0
ffffffffc0201862:	84ae                	mv	s1,a1
ffffffffc0201864:	8d32                	mv	s10,a2
ffffffffc0201866:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201868:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020186c:	5b7d                	li	s6,-1
ffffffffc020186e:	00001a97          	auipc	s5,0x1
ffffffffc0201872:	0cea8a93          	addi	s5,s5,206 # ffffffffc020293c <buddy_pmm_manager+0x1dc>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201876:	00001b97          	auipc	s7,0x1
ffffffffc020187a:	2a2b8b93          	addi	s7,s7,674 # ffffffffc0202b18 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020187e:	000d4503          	lbu	a0,0(s10)
ffffffffc0201882:	001d0413          	addi	s0,s10,1
ffffffffc0201886:	01350a63          	beq	a0,s3,ffffffffc020189a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020188a:	c121                	beqz	a0,ffffffffc02018ca <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020188c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020188e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201890:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201892:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201896:	ff351ae3          	bne	a0,s3,ffffffffc020188a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020189a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020189e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02018a2:	4c81                	li	s9,0
ffffffffc02018a4:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02018a6:	5c7d                	li	s8,-1
ffffffffc02018a8:	5dfd                	li	s11,-1
ffffffffc02018aa:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02018ae:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018b0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02018b4:	0ff5f593          	zext.b	a1,a1
ffffffffc02018b8:	00140d13          	addi	s10,s0,1
ffffffffc02018bc:	04b56263          	bltu	a0,a1,ffffffffc0201900 <vprintfmt+0xbc>
ffffffffc02018c0:	058a                	slli	a1,a1,0x2
ffffffffc02018c2:	95d6                	add	a1,a1,s5
ffffffffc02018c4:	4194                	lw	a3,0(a1)
ffffffffc02018c6:	96d6                	add	a3,a3,s5
ffffffffc02018c8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02018ca:	70e6                	ld	ra,120(sp)
ffffffffc02018cc:	7446                	ld	s0,112(sp)
ffffffffc02018ce:	74a6                	ld	s1,104(sp)
ffffffffc02018d0:	7906                	ld	s2,96(sp)
ffffffffc02018d2:	69e6                	ld	s3,88(sp)
ffffffffc02018d4:	6a46                	ld	s4,80(sp)
ffffffffc02018d6:	6aa6                	ld	s5,72(sp)
ffffffffc02018d8:	6b06                	ld	s6,64(sp)
ffffffffc02018da:	7be2                	ld	s7,56(sp)
ffffffffc02018dc:	7c42                	ld	s8,48(sp)
ffffffffc02018de:	7ca2                	ld	s9,40(sp)
ffffffffc02018e0:	7d02                	ld	s10,32(sp)
ffffffffc02018e2:	6de2                	ld	s11,24(sp)
ffffffffc02018e4:	6109                	addi	sp,sp,128
ffffffffc02018e6:	8082                	ret
            padc = '0';
ffffffffc02018e8:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02018ea:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018ee:	846a                	mv	s0,s10
ffffffffc02018f0:	00140d13          	addi	s10,s0,1
ffffffffc02018f4:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02018f8:	0ff5f593          	zext.b	a1,a1
ffffffffc02018fc:	fcb572e3          	bgeu	a0,a1,ffffffffc02018c0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201900:	85a6                	mv	a1,s1
ffffffffc0201902:	02500513          	li	a0,37
ffffffffc0201906:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201908:	fff44783          	lbu	a5,-1(s0)
ffffffffc020190c:	8d22                	mv	s10,s0
ffffffffc020190e:	f73788e3          	beq	a5,s3,ffffffffc020187e <vprintfmt+0x3a>
ffffffffc0201912:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201916:	1d7d                	addi	s10,s10,-1
ffffffffc0201918:	ff379de3          	bne	a5,s3,ffffffffc0201912 <vprintfmt+0xce>
ffffffffc020191c:	b78d                	j	ffffffffc020187e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020191e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201922:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201926:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201928:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020192c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201930:	02d86463          	bltu	a6,a3,ffffffffc0201958 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201934:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201938:	002c169b          	slliw	a3,s8,0x2
ffffffffc020193c:	0186873b          	addw	a4,a3,s8
ffffffffc0201940:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201944:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201946:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020194a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020194c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201950:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201954:	fed870e3          	bgeu	a6,a3,ffffffffc0201934 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201958:	f40ddce3          	bgez	s11,ffffffffc02018b0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020195c:	8de2                	mv	s11,s8
ffffffffc020195e:	5c7d                	li	s8,-1
ffffffffc0201960:	bf81                	j	ffffffffc02018b0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201962:	fffdc693          	not	a3,s11
ffffffffc0201966:	96fd                	srai	a3,a3,0x3f
ffffffffc0201968:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020196c:	00144603          	lbu	a2,1(s0)
ffffffffc0201970:	2d81                	sext.w	s11,s11
ffffffffc0201972:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201974:	bf35                	j	ffffffffc02018b0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201976:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020197a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020197e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201980:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201982:	bfd9                	j	ffffffffc0201958 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201984:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201986:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020198a:	01174463          	blt	a4,a7,ffffffffc0201992 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020198e:	1a088e63          	beqz	a7,ffffffffc0201b4a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201992:	000a3603          	ld	a2,0(s4)
ffffffffc0201996:	46c1                	li	a3,16
ffffffffc0201998:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020199a:	2781                	sext.w	a5,a5
ffffffffc020199c:	876e                	mv	a4,s11
ffffffffc020199e:	85a6                	mv	a1,s1
ffffffffc02019a0:	854a                	mv	a0,s2
ffffffffc02019a2:	e37ff0ef          	jal	ra,ffffffffc02017d8 <printnum>
            break;
ffffffffc02019a6:	bde1                	j	ffffffffc020187e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02019a8:	000a2503          	lw	a0,0(s4)
ffffffffc02019ac:	85a6                	mv	a1,s1
ffffffffc02019ae:	0a21                	addi	s4,s4,8
ffffffffc02019b0:	9902                	jalr	s2
            break;
ffffffffc02019b2:	b5f1                	j	ffffffffc020187e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02019b4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02019b6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02019ba:	01174463          	blt	a4,a7,ffffffffc02019c2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02019be:	18088163          	beqz	a7,ffffffffc0201b40 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02019c2:	000a3603          	ld	a2,0(s4)
ffffffffc02019c6:	46a9                	li	a3,10
ffffffffc02019c8:	8a2e                	mv	s4,a1
ffffffffc02019ca:	bfc1                	j	ffffffffc020199a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019cc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02019d0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019d2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02019d4:	bdf1                	j	ffffffffc02018b0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02019d6:	85a6                	mv	a1,s1
ffffffffc02019d8:	02500513          	li	a0,37
ffffffffc02019dc:	9902                	jalr	s2
            break;
ffffffffc02019de:	b545                	j	ffffffffc020187e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019e0:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02019e4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019e6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02019e8:	b5e1                	j	ffffffffc02018b0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02019ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02019ec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02019f0:	01174463          	blt	a4,a7,ffffffffc02019f8 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02019f4:	14088163          	beqz	a7,ffffffffc0201b36 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02019f8:	000a3603          	ld	a2,0(s4)
ffffffffc02019fc:	46a1                	li	a3,8
ffffffffc02019fe:	8a2e                	mv	s4,a1
ffffffffc0201a00:	bf69                	j	ffffffffc020199a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201a02:	03000513          	li	a0,48
ffffffffc0201a06:	85a6                	mv	a1,s1
ffffffffc0201a08:	e03e                	sd	a5,0(sp)
ffffffffc0201a0a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201a0c:	85a6                	mv	a1,s1
ffffffffc0201a0e:	07800513          	li	a0,120
ffffffffc0201a12:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201a14:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201a16:	6782                	ld	a5,0(sp)
ffffffffc0201a18:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201a1a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201a1e:	bfb5                	j	ffffffffc020199a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201a20:	000a3403          	ld	s0,0(s4)
ffffffffc0201a24:	008a0713          	addi	a4,s4,8
ffffffffc0201a28:	e03a                	sd	a4,0(sp)
ffffffffc0201a2a:	14040263          	beqz	s0,ffffffffc0201b6e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201a2e:	0fb05763          	blez	s11,ffffffffc0201b1c <vprintfmt+0x2d8>
ffffffffc0201a32:	02d00693          	li	a3,45
ffffffffc0201a36:	0cd79163          	bne	a5,a3,ffffffffc0201af8 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201a3a:	00044783          	lbu	a5,0(s0)
ffffffffc0201a3e:	0007851b          	sext.w	a0,a5
ffffffffc0201a42:	cf85                	beqz	a5,ffffffffc0201a7a <vprintfmt+0x236>
ffffffffc0201a44:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201a48:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201a4c:	000c4563          	bltz	s8,ffffffffc0201a56 <vprintfmt+0x212>
ffffffffc0201a50:	3c7d                	addiw	s8,s8,-1
ffffffffc0201a52:	036c0263          	beq	s8,s6,ffffffffc0201a76 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201a56:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201a58:	0e0c8e63          	beqz	s9,ffffffffc0201b54 <vprintfmt+0x310>
ffffffffc0201a5c:	3781                	addiw	a5,a5,-32
ffffffffc0201a5e:	0ef47b63          	bgeu	s0,a5,ffffffffc0201b54 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201a62:	03f00513          	li	a0,63
ffffffffc0201a66:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201a68:	000a4783          	lbu	a5,0(s4)
ffffffffc0201a6c:	3dfd                	addiw	s11,s11,-1
ffffffffc0201a6e:	0a05                	addi	s4,s4,1
ffffffffc0201a70:	0007851b          	sext.w	a0,a5
ffffffffc0201a74:	ffe1                	bnez	a5,ffffffffc0201a4c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201a76:	01b05963          	blez	s11,ffffffffc0201a88 <vprintfmt+0x244>
ffffffffc0201a7a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201a7c:	85a6                	mv	a1,s1
ffffffffc0201a7e:	02000513          	li	a0,32
ffffffffc0201a82:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201a84:	fe0d9be3          	bnez	s11,ffffffffc0201a7a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201a88:	6a02                	ld	s4,0(sp)
ffffffffc0201a8a:	bbd5                	j	ffffffffc020187e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201a8c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201a8e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201a92:	01174463          	blt	a4,a7,ffffffffc0201a9a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201a96:	08088d63          	beqz	a7,ffffffffc0201b30 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201a9a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201a9e:	0a044d63          	bltz	s0,ffffffffc0201b58 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201aa2:	8622                	mv	a2,s0
ffffffffc0201aa4:	8a66                	mv	s4,s9
ffffffffc0201aa6:	46a9                	li	a3,10
ffffffffc0201aa8:	bdcd                	j	ffffffffc020199a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201aaa:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201aae:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201ab0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201ab2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201ab6:	8fb5                	xor	a5,a5,a3
ffffffffc0201ab8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201abc:	02d74163          	blt	a4,a3,ffffffffc0201ade <vprintfmt+0x29a>
ffffffffc0201ac0:	00369793          	slli	a5,a3,0x3
ffffffffc0201ac4:	97de                	add	a5,a5,s7
ffffffffc0201ac6:	639c                	ld	a5,0(a5)
ffffffffc0201ac8:	cb99                	beqz	a5,ffffffffc0201ade <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201aca:	86be                	mv	a3,a5
ffffffffc0201acc:	00001617          	auipc	a2,0x1
ffffffffc0201ad0:	e6c60613          	addi	a2,a2,-404 # ffffffffc0202938 <buddy_pmm_manager+0x1d8>
ffffffffc0201ad4:	85a6                	mv	a1,s1
ffffffffc0201ad6:	854a                	mv	a0,s2
ffffffffc0201ad8:	0ce000ef          	jal	ra,ffffffffc0201ba6 <printfmt>
ffffffffc0201adc:	b34d                	j	ffffffffc020187e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201ade:	00001617          	auipc	a2,0x1
ffffffffc0201ae2:	e4a60613          	addi	a2,a2,-438 # ffffffffc0202928 <buddy_pmm_manager+0x1c8>
ffffffffc0201ae6:	85a6                	mv	a1,s1
ffffffffc0201ae8:	854a                	mv	a0,s2
ffffffffc0201aea:	0bc000ef          	jal	ra,ffffffffc0201ba6 <printfmt>
ffffffffc0201aee:	bb41                	j	ffffffffc020187e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201af0:	00001417          	auipc	s0,0x1
ffffffffc0201af4:	e3040413          	addi	s0,s0,-464 # ffffffffc0202920 <buddy_pmm_manager+0x1c0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201af8:	85e2                	mv	a1,s8
ffffffffc0201afa:	8522                	mv	a0,s0
ffffffffc0201afc:	e43e                	sd	a5,8(sp)
ffffffffc0201afe:	0fc000ef          	jal	ra,ffffffffc0201bfa <strnlen>
ffffffffc0201b02:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201b06:	01b05b63          	blez	s11,ffffffffc0201b1c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201b0a:	67a2                	ld	a5,8(sp)
ffffffffc0201b0c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201b10:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201b12:	85a6                	mv	a1,s1
ffffffffc0201b14:	8552                	mv	a0,s4
ffffffffc0201b16:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201b18:	fe0d9ce3          	bnez	s11,ffffffffc0201b10 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b1c:	00044783          	lbu	a5,0(s0)
ffffffffc0201b20:	00140a13          	addi	s4,s0,1
ffffffffc0201b24:	0007851b          	sext.w	a0,a5
ffffffffc0201b28:	d3a5                	beqz	a5,ffffffffc0201a88 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201b2a:	05e00413          	li	s0,94
ffffffffc0201b2e:	bf39                	j	ffffffffc0201a4c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201b30:	000a2403          	lw	s0,0(s4)
ffffffffc0201b34:	b7ad                	j	ffffffffc0201a9e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201b36:	000a6603          	lwu	a2,0(s4)
ffffffffc0201b3a:	46a1                	li	a3,8
ffffffffc0201b3c:	8a2e                	mv	s4,a1
ffffffffc0201b3e:	bdb1                	j	ffffffffc020199a <vprintfmt+0x156>
ffffffffc0201b40:	000a6603          	lwu	a2,0(s4)
ffffffffc0201b44:	46a9                	li	a3,10
ffffffffc0201b46:	8a2e                	mv	s4,a1
ffffffffc0201b48:	bd89                	j	ffffffffc020199a <vprintfmt+0x156>
ffffffffc0201b4a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201b4e:	46c1                	li	a3,16
ffffffffc0201b50:	8a2e                	mv	s4,a1
ffffffffc0201b52:	b5a1                	j	ffffffffc020199a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201b54:	9902                	jalr	s2
ffffffffc0201b56:	bf09                	j	ffffffffc0201a68 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201b58:	85a6                	mv	a1,s1
ffffffffc0201b5a:	02d00513          	li	a0,45
ffffffffc0201b5e:	e03e                	sd	a5,0(sp)
ffffffffc0201b60:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201b62:	6782                	ld	a5,0(sp)
ffffffffc0201b64:	8a66                	mv	s4,s9
ffffffffc0201b66:	40800633          	neg	a2,s0
ffffffffc0201b6a:	46a9                	li	a3,10
ffffffffc0201b6c:	b53d                	j	ffffffffc020199a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201b6e:	03b05163          	blez	s11,ffffffffc0201b90 <vprintfmt+0x34c>
ffffffffc0201b72:	02d00693          	li	a3,45
ffffffffc0201b76:	f6d79de3          	bne	a5,a3,ffffffffc0201af0 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201b7a:	00001417          	auipc	s0,0x1
ffffffffc0201b7e:	da640413          	addi	s0,s0,-602 # ffffffffc0202920 <buddy_pmm_manager+0x1c0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b82:	02800793          	li	a5,40
ffffffffc0201b86:	02800513          	li	a0,40
ffffffffc0201b8a:	00140a13          	addi	s4,s0,1
ffffffffc0201b8e:	bd6d                	j	ffffffffc0201a48 <vprintfmt+0x204>
ffffffffc0201b90:	00001a17          	auipc	s4,0x1
ffffffffc0201b94:	d91a0a13          	addi	s4,s4,-623 # ffffffffc0202921 <buddy_pmm_manager+0x1c1>
ffffffffc0201b98:	02800513          	li	a0,40
ffffffffc0201b9c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ba0:	05e00413          	li	s0,94
ffffffffc0201ba4:	b565                	j	ffffffffc0201a4c <vprintfmt+0x208>

ffffffffc0201ba6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201ba6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201ba8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201bac:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201bae:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201bb0:	ec06                	sd	ra,24(sp)
ffffffffc0201bb2:	f83a                	sd	a4,48(sp)
ffffffffc0201bb4:	fc3e                	sd	a5,56(sp)
ffffffffc0201bb6:	e0c2                	sd	a6,64(sp)
ffffffffc0201bb8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201bba:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201bbc:	c89ff0ef          	jal	ra,ffffffffc0201844 <vprintfmt>
}
ffffffffc0201bc0:	60e2                	ld	ra,24(sp)
ffffffffc0201bc2:	6161                	addi	sp,sp,80
ffffffffc0201bc4:	8082                	ret

ffffffffc0201bc6 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201bc6:	4781                	li	a5,0
ffffffffc0201bc8:	00004717          	auipc	a4,0x4
ffffffffc0201bcc:	44873703          	ld	a4,1096(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201bd0:	88ba                	mv	a7,a4
ffffffffc0201bd2:	852a                	mv	a0,a0
ffffffffc0201bd4:	85be                	mv	a1,a5
ffffffffc0201bd6:	863e                	mv	a2,a5
ffffffffc0201bd8:	00000073          	ecall
ffffffffc0201bdc:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201bde:	8082                	ret

ffffffffc0201be0 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201be0:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201be4:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201be6:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201be8:	cb81                	beqz	a5,ffffffffc0201bf8 <strlen+0x18>
        cnt ++;
ffffffffc0201bea:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201bec:	00a707b3          	add	a5,a4,a0
ffffffffc0201bf0:	0007c783          	lbu	a5,0(a5)
ffffffffc0201bf4:	fbfd                	bnez	a5,ffffffffc0201bea <strlen+0xa>
ffffffffc0201bf6:	8082                	ret
    }
    return cnt;
}
ffffffffc0201bf8:	8082                	ret

ffffffffc0201bfa <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201bfa:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201bfc:	e589                	bnez	a1,ffffffffc0201c06 <strnlen+0xc>
ffffffffc0201bfe:	a811                	j	ffffffffc0201c12 <strnlen+0x18>
        cnt ++;
ffffffffc0201c00:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201c02:	00f58863          	beq	a1,a5,ffffffffc0201c12 <strnlen+0x18>
ffffffffc0201c06:	00f50733          	add	a4,a0,a5
ffffffffc0201c0a:	00074703          	lbu	a4,0(a4)
ffffffffc0201c0e:	fb6d                	bnez	a4,ffffffffc0201c00 <strnlen+0x6>
ffffffffc0201c10:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201c12:	852e                	mv	a0,a1
ffffffffc0201c14:	8082                	ret

ffffffffc0201c16 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201c16:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201c1a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201c1e:	cb89                	beqz	a5,ffffffffc0201c30 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201c20:	0505                	addi	a0,a0,1
ffffffffc0201c22:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201c24:	fee789e3          	beq	a5,a4,ffffffffc0201c16 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201c28:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201c2c:	9d19                	subw	a0,a0,a4
ffffffffc0201c2e:	8082                	ret
ffffffffc0201c30:	4501                	li	a0,0
ffffffffc0201c32:	bfed                	j	ffffffffc0201c2c <strcmp+0x16>

ffffffffc0201c34 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201c34:	c20d                	beqz	a2,ffffffffc0201c56 <strncmp+0x22>
ffffffffc0201c36:	962e                	add	a2,a2,a1
ffffffffc0201c38:	a031                	j	ffffffffc0201c44 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201c3a:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201c3c:	00e79a63          	bne	a5,a4,ffffffffc0201c50 <strncmp+0x1c>
ffffffffc0201c40:	00b60b63          	beq	a2,a1,ffffffffc0201c56 <strncmp+0x22>
ffffffffc0201c44:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201c48:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201c4a:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201c4e:	f7f5                	bnez	a5,ffffffffc0201c3a <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201c50:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201c54:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201c56:	4501                	li	a0,0
ffffffffc0201c58:	8082                	ret

ffffffffc0201c5a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201c5a:	ca01                	beqz	a2,ffffffffc0201c6a <memset+0x10>
ffffffffc0201c5c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201c5e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201c60:	0785                	addi	a5,a5,1
ffffffffc0201c62:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201c66:	fec79de3          	bne	a5,a2,ffffffffc0201c60 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201c6a:	8082                	ret
