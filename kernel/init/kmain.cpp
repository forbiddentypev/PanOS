#include <arch/early_console.hpp>
#include <arch/serial.hpp>

extern "C" void kernel_main(unsigned long multiboot_magic,
                            unsigned long multiboot_info) {
    (void)multiboot_magic;
    (void)multiboot_info;

    pan::arch::serial_init();
    pan::arch::early_console_init();
    pan::arch::early_console_enable_serial();

    pan::arch::early_console_write("PAN OS 64 BIT KERNEL INITIALIZED\n");
    pan::arch::early_console_test_higher_half();

    for (;;) {
        __asm__ volatile("hlt");
    }
}
