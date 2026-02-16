# Pan OS – Phase 0 Toolchain
# x86_64-elf target, GRUB multiboot2
# Requires: x86_64-elf-gcc, nasm
# Fedora: dnf install gcc-x86_64-elf nasm

cmake_minimum_required(VERSION 3.16)

find_program(CMAKE_ASM_NASM_COMPILER nasm REQUIRED)

project(PanOS LANGUAGES C CXX ASM_NASM)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Toolchain: x86_64-elf (bare-metal, no host libc)
# Install: https://wiki.osdev.org/GCC_Cross-Compiler or
#   Ubuntu/Debian: apt install gcc-x86-64-elf
#   Arch:          pacman -S x86_64-elf-gcc
#   Fedora:        dnf install gcc-x86_64-elf (or build cross-compiler)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

if(NOT CMAKE_C_COMPILER)
    find_program(X86_64_ELF_CC x86_64-elf-gcc)
    if(X86_64_ELF_CC)
        set(CMAKE_C_COMPILER ${X86_64_ELF_CC})
    endif()
endif()
if(NOT CMAKE_CXX_COMPILER)
    find_program(X86_64_ELF_CXX x86_64-elf-g++)
    if(X86_64_ELF_CXX)
        set(CMAKE_CXX_COMPILER ${X86_64_ELF_CXX})
    endif()
endif()
if(NOT CMAKE_C_COMPILER)
    message(WARNING "x86_64-elf-gcc not found. Using system compiler - kernel may not boot.")
endif()
find_program(CMAKE_ASM_NASM_COMPILER nasm REQUIRED)

enable_language(C)
enable_language(CXX)

# Kernel C/C++ flags (ARCHITECTURE.md Phase 0)
set(KERNEL_FLAGS "-ffreestanding -fno-exceptions -fno-rtti -mno-red-zone -mcmodel=kernel -O2 -nostdlib -Wall -Wextra -fno-asynchronous-unwind-tables -fno-unwind-tables")
set(CMAKE_C_FLAGS   ${KERNEL_FLAGS})
set(CMAKE_CXX_FLAGS ${KERNEL_FLAGS})

# Assembly flags
set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> -f ${CMAKE_ASM_NASM_OBJECT_FORMAT} <FLAGS> -o <OBJECT> <SOURCE>")

# Kernel executable
add_executable(pan_kernel
    kernel/arch/x86_64/boot.asm
    kernel/arch/x86_64/serial.cpp
    kernel/arch/x86_64/early_console.cpp
    kernel/init/kmain.cpp
)

target_include_directories(pan_kernel PRIVATE
    ${CMAKE_SOURCE_DIR}/kernel/include
    ${CMAKE_SOURCE_DIR}/kernel/arch/x86_64/include
)

target_link_options(pan_kernel PRIVATE
    -T ${CMAKE_SOURCE_DIR}/kernel/arch/x86_64/linker.ld
    -nostdlib
)
target_link_libraries(pan_kernel)

# ISO build (GRUB)
set(GRUB_ISO_DIR ${CMAKE_BINARY_DIR}/iso)
set(GRUB_BOOT_DIR ${GRUB_ISO_DIR}/boot)
set(GRUB_GRUB_DIR ${GRUB_BOOT_DIR}/grub)

# ISO target (requires grub-mkrescue: dnf install grub2-tools xorriso)
find_program(GRUB_MKRESCUE grub-mkrescue)
if(GRUB_MKRESCUE)
add_custom_target(pan_iso
    COMMAND ${CMAKE_COMMAND} -E make_directory ${GRUB_BOOT_DIR} ${GRUB_GRUB_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:pan_kernel> ${GRUB_BOOT_DIR}/pan_kernel
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/grub/grub.cfg ${GRUB_GRUB_DIR}/grub.cfg
    COMMAND grub-mkrescue -o ${CMAKE_BINARY_DIR}/pan.iso ${GRUB_ISO_DIR}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    DEPENDS pan_kernel
    COMMENT "Building bootable ISO: pan.iso"
)
else()
message(STATUS "grub-mkrescue not found - run 'make pan_iso' will fail. Install grub2-tools and xorriso.")
add_custom_target(pan_iso
    COMMAND ${CMAKE_COMMAND} -E echo "ERROR: grub-mkrescue required. Install: dnf install grub2-tools xorriso"
    COMMAND false
)
endif()
