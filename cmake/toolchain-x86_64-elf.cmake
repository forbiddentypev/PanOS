# Pan OS – x86_64-elf cross-compiler toolchain
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-x86_64-elf.cmake -B build -S .

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(CMAKE_C_COMPILER   x86_64-elf-gcc)
set(CMAKE_CXX_COMPILER x86_64-elf-g++)
