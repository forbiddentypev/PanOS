/* Pan OS – Higher-half linker script
 * Physical load: 1MB (GRUB multiboot2)
 * Virtual: 0xFFFFFFFF80100000 (higher-half)
 * Bootstrap runs identity-mapped, then jumps to higher-half
 */

__KERNEL_LOAD    = 1M;
__KERNEL_VIRT    = 0xFFFFFFFF80100000;

ENTRY(_start)

SECTIONS
{
    /* Bootstrap: identity-mapped at 1MB, must be first for multiboot header */
    . = __KERNEL_LOAD;

    .multiboot2 BLOCK(4K) : ALIGN(4K)
    {
        *(.multiboot2)
    }

    .text.bootstrap BLOCK(4K) : ALIGN(4K)
    {
        *(.text.bootstrap)
    }

    _bootstrap_end = .;

    /* Higher-half kernel */
    . = __KERNEL_VIRT;

    .text BLOCK(4K) : AT(_bootstrap_end)
    {
        *(.text .text.*)
    }

    .rodata BLOCK(4K) : AT(LOADADDR(.text) + SIZEOF(.text))
    {
        *(.rodata .rodata.*)
    }

    .data BLOCK(4K) : AT(LOADADDR(.rodata) + SIZEOF(.rodata))
    {
        *(.data .data.*)
    }

    /* BSS: continues load segment, zeroed by loader (p_memsz > p_filesz) */
    .bss BLOCK(4K) :
    {
        __bss_start = .;
        *(COMMON)
        *(.bss .bss.*)
        __bss_end = .;

        /* Stack: 64KB, 16-byte aligned for x86-64 ABI */
        __stack_bottom = .;
        . = ALIGN(16);
        . += 64K;
        __stack_top = .;
    }

    __kernel_end = .;
}
