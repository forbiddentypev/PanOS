#include <arch/serial.hpp>

namespace pan::arch {

static constexpr unsigned short COM1 = 0x3F8;

static inline void outb(unsigned short port, unsigned char value) {
    __asm__ volatile("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline unsigned char inb(unsigned short port) {
    unsigned char value;
    __asm__ volatile("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

void serial_init() {
    outb(COM1 + 1, 0x00);   /* Disable interrupts */
    outb(COM1 + 3, 0x80);   /* Enable DLAB */
    outb(COM1 + 0, 0x01);   /* Divisor 1 = 115200 baud */
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x03);   /* 8n1 */
    outb(COM1 + 2, 0xC7);   /* Enable FIFO */
    outb(COM1 + 4, 0x0B);   /* IRQs off, RTS/DSR on */
}

void serial_putchar(char c) {
    while ((inb(COM1 + 5) & 0x20) == 0)
        ;
    outb(COM1, static_cast<unsigned char>(c));
}

void serial_write(const char* str) {
    while (*str) {
        serial_putchar(*str++);
    }
}

}  // namespace pan::arch
