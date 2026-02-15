; Pan OS – Multiboot2 boot + long mode + higher-half
; Bootstrap runs identity-mapped, then jumps to higher-half kernel

section .multiboot2
align 8
multiboot2_header:
    dd 0xE85250D6
    dd 0
    dd multiboot2_header_end - multiboot2_header
    dd -(0xE85250D6 + 0 + (multiboot2_header_end - multiboot2_header))
    dw 0
    dw 0
    dd 8
multiboot2_header_end:

section .text.bootstrap
bits 32
global _start
extern kernel_main
extern __stack_top

; Page tables (below 1MB, identity-mapped)
PML4        equ 0x1000
PDPT_LOW    equ 0x2000
PD_LOW      equ 0x3000
PDPT_HIGH   equ 0x4000
PD_HIGH     equ 0x5000

; PML4 index 511 = higher-half
PML4_HIGH_IDX   equ 511
PDPT_HIGH_IDX   equ 511

_start:
    cli
    cld

    ; Save multiboot magic (eax) and info (ebx)
    mov edi, eax
    mov esi, ebx

    ; Identity map 0–2MB (bootstrap code)
    mov eax, PDPT_LOW
    or  eax, 0x03
    mov dword [PML4], eax

    mov eax, PD_LOW
    or  eax, 0x03
    mov dword [PDPT_LOW], eax

    mov eax, 0x83
    mov dword [PD_LOW], eax

    ; Higher-half map: 0xFFFFFFFF80000000 -> 0 (2MB)
    mov eax, PDPT_HIGH
    or  eax, 0x03
    mov dword [PML4 + PML4_HIGH_IDX * 8], eax

    mov eax, PD_HIGH
    or  eax, 0x03
    mov dword [PDPT_HIGH + PDPT_HIGH_IDX * 8], eax

    mov eax, 0x83
    mov dword [PD_HIGH], eax

    ; Load CR3
    mov eax, PML4
    mov cr3, eax

    ; Enable PAE
    mov eax, cr4
    or  eax, 1 << 5
    mov cr4, eax

    ; Enable long mode (EFER.LME)
    mov ecx, 0xC0000080
    rdmsr
    or  eax, 1 << 8
    wrmsr

    ; Enable paging
    mov eax, cr0
    or  eax, 1 << 31
    mov cr0, eax

    ; Load GDT
    lgdt [gdt64_ptr]

    ; Far jump to 64-bit (still identity-mapped)
    jmp 0x08:long_mode_low

bits 64
long_mode_low:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Stack in higher-half; 16-byte aligned
    mov rsp, __stack_top
    mov rbp, rsp
    and rsp, -16

    ; Jump to higher-half code (rdi=magic, rsi=info preserved)
    mov rax, higher_half_start
    jmp rax

; GDT must stay in bootstrap (identity-mapped) for lgdt
align 8
gdt64:
    dq 0
    dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53)
    dq (1 << 41) | (1 << 44) | (1 << 47)

gdt64_ptr:
    dw gdt64_ptr - gdt64 - 1
    dq gdt64

; Higher-half entry (linked at 0xFFFFFFFF80100000+)
section .text
global higher_half_start
higher_half_start:
    call kernel_main

halt:
    cli
    hlt
    jmp halt
