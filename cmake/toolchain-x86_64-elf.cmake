# Pan OS – x86_64-elf cross-compiler toolchain
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Full path to cross-compilers
set(CMAKE_C_COMPILER   /home/forbiddentypev/opt/cross/bin/x86_64-elf-gcc)
set(CMAKE_CXX_COMPILER /home/forbiddentypev/opt/cross/bin/x86_64-elf-g++)
# set(CMAKE_ASM_NASM_COMPILER /usr/bin/nasm)

# Compiler flags
set(CMAKE_C_FLAGS   "-ffreestanding -O2 -fno-exceptions -fno-rtti -fno-unwind-tables -mno-red-zone")
set(CMAKE_CXX_FLAGS "-ffreestanding -O2 -fno-exceptions -fno-rtti -fno-unwind-tables -mno-red-zone")
set(CMAKE_EXE_LINKER_FLAGS "-nostdlib")
