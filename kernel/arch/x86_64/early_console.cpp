#include <arch/early_console.hpp>
#include <arch/serial.hpp>

extern "C" void kernel_main(unsigned long, unsigned long);

namespace pan::arch {

static constexpr unsigned long VGA_PHYS = 0xB8000;
static constexpr unsigned long KERNEL_VIRT_BASE = 0xFFFFFFFF80000000UL;

static volatile unsigned short* vga_buffer =
    reinterpret_cast<volatile unsigned short*>(VGA_PHYS);
static unsigned int vga_row = 0;
static unsigned int vga_col = 0;
static constexpr unsigned int VGA_WIDTH = 80;
static constexpr unsigned int VGA_HEIGHT = 25;
static constexpr unsigned char VGA_COLOR = 0x07;

static bool serial_ready = false;

void early_console_init() {
    for (unsigned int i = 0; i < VGA_WIDTH * VGA_HEIGHT; ++i) {
        vga_buffer[i] = (VGA_COLOR << 8) | ' ';
    }
    vga_row = 0;
    vga_col = 0;
}

static void putchar_vga(char c) {
    if (c == '\n') {
        vga_col = 0;
        if (++vga_row >= VGA_HEIGHT) {
            vga_row = VGA_HEIGHT - 1;
            for (unsigned int i = 0; i < (VGA_HEIGHT - 1) * VGA_WIDTH; ++i) {
                vga_buffer[i] = vga_buffer[i + VGA_WIDTH];
            }
            for (unsigned int i = (VGA_HEIGHT - 1) * VGA_WIDTH;
                 i < VGA_HEIGHT * VGA_WIDTH; ++i) {
                vga_buffer[i] = (VGA_COLOR << 8) | ' ';
            }
        }
        return;
    }
    vga_buffer[vga_row * VGA_WIDTH + vga_col] =
        (VGA_COLOR << 8) | static_cast<unsigned char>(c);
    if (++vga_col >= VGA_WIDTH) {
        vga_col = 0;
        if (++vga_row >= VGA_HEIGHT) {
            vga_row = VGA_HEIGHT - 1;
        }
    }
}

void early_console_enable_serial() {
    serial_ready = true;
}

void early_console_write(const char* str) {
    while (*str) {
        putchar_vga(*str);
        if (serial_ready) {
            serial_putchar(*str);
        }
        str++;
    }
}

void early_console_write_dual(const char* str) {
    while (*str) {
        putchar_vga(*str);
        if (serial_ready) {
            serial_putchar(*str);
        }
        str++;
    }
}

static void puthex64(unsigned long value) {
    const char hex[] = "0123456789ABCDEF";
    char buf[19] = "0x";
    for (int i = 15; i >= 0; --i) {
        buf[2 + (15 - i)] = hex[(value >> (i * 4)) & 0xF];
    }
    buf[18] = '\0';
    early_console_write_dual(buf);
}

void early_console_test_higher_half() {
    /* kernel_main should be at higher-half address */
    unsigned long addr = reinterpret_cast<unsigned long>(&kernel_main);

    early_console_write_dual("\n[kernel] kernel_main @ ");
    puthex64(addr);
    early_console_write_dual("\n");

    if (addr >= KERNEL_VIRT_BASE) {
        early_console_write_dual("[kernel] OK: running from higher-half\n");
    } else {
        early_console_write_dual("[kernel] FAIL: not in higher-half\n");
    }
}

}  // namespace pan::arch
