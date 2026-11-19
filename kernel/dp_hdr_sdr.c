typedef unsigned char u8;
typedef unsigned int u32;
typedef unsigned long u64;

extern int _printk(const char *fmt, ...);
extern void *ioremap_prot(u64 phys_addr, u64 size, u64 prot);
extern void iounmap(void *io_addr);

static inline u32 readl_raw(const volatile void *addr) {
    u32 val;
    __asm__ __volatile__("ldr %w0, [%1]" : "=r"(val) : "r"(addr) : "memory");
    __asm__ __volatile__("dsb ld" ::: "memory");
    return val;
}

static inline void writel_raw(u32 val, volatile void *addr) {
    __asm__ __volatile__("dsb st" ::: "memory");
    __asm__ __volatile__("str %w0, [%1]" :: "r"(val), "r"(addr) : "memory");
}

__asm__(
    ".section .text.init_fn,\"ax\",@progbits\n"
    ".align 2\n"
    ".word 0x36b1c5a6\n"
);
__attribute__((section(".text.init_fn")))
int init_module(void) {
    volatile u8 *base = (volatile u8 *)ioremap_prot(0x110f5000UL, 0x1000UL, 0x0068000000000f13UL);
    if (!base) return -1;

    u32 pkt = readl_raw(base + 0xc10);
    writel_raw((pkt & ~0xffU) | 0x87U, base + 0xc10);

    writel_raw(0x00000000U, base + 0xc60);
    writel_raw(0x00000000U, base + 0xc64);
    writel_raw(0x00000000U, base + 0xc68);
    writel_raw(0x00000000U, base + 0xc6c);
    writel_raw(0x00000000U, base + 0xc70);
    writel_raw(0x00000000U, base + 0xc74);
    writel_raw(0x00000000U, base + 0xc78);

    writel_raw(readl_raw(base + 0xc04) | 0x5U, base + 0xc04);
    writel_raw(readl_raw(base + 0xc08) | 0x5U, base + 0xc08);

    _printk("dp_hdr_sdr: sent SDR DRM(0x87, EOTF=0) + standard AVI! 5400=%08x 5c10=%08x avi0=%08x\n",
            readl_raw(base + 0x400),
            readl_raw(base + 0xc10),
            readl_raw(base + 0xc40));

    iounmap((void *)base);
    return -1;
}

__asm__(
    ".section .text.exit_fn,\"ax\",@progbits\n"
    ".align 2\n"
    ".word 0xa540670c\n"
);
__attribute__((section(".text.exit_fn")))
void cleanup_module(void) {}

__attribute__((section(".modinfo"), used))
static const char modinfo_str[] =
    "license=GPL\0"
    "vermagic=6.1.162-android14-11-gd7a0a08e0e15-ab16261946 SMP preempt mod_unload modversions aarch64\0"
    "name=dp_hdr_sdr\0";

struct modversion_info {
    u64 crc;
    char name[56];
};

__attribute__((section("__versions"), used, aligned(8)))
static const struct modversion_info versions[] = {
    { 0xea759d7fUL, "module_layout" },
    { 0x92997ed8UL, "_printk" },
    { 0x40863ba1UL, "ioremap_prot" },
    { 0xedc03953UL, "iounmap" },
};

struct this_module_stub {
    u8 pad0[0x18];
    char name[56];
    u8 pad1[0x170 - 0x18 - 56];
    int (*init)(void);
    u8 pad2[0x3d8 - 0x170 - 8];
    void (*exit)(void);
    u8 pad3[0x440 - 0x3d8 - 8];
};

__attribute__((section(".gnu.linkonce.this_module"), used, aligned(64)))
struct this_module_stub __this_module = {
    .name = "dp_hdr_sdr",
    .init = init_module,
    .exit = cleanup_module,
};

__asm__(
    ".section .plt, \"ax\", @progbits\n"
    ".space 128\n"
    ".section .init.plt, \"ax\", @progbits\n"
    ".space 128\n"
    ".previous\n"
);
