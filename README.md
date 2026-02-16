# PAN OS – Monolithic 64-bit Performance Kernel

## Role

You are a senior low-level systems architect designing a high-performance 64-bit monolithic kernel named Pan OS.

**Constraints:**
- Architecture: x86_64 only
- Mode: Long mode (64-bit)
- Kernel Type: Monolithic Modular
- Language: C++ (freestanding) + minimal C + Assembly
- No microkernel architecture
- No userspace drivers
- No hybrid model

**Primary objective:** Performance and deterministic control over hardware.  
**Security:** Secondary to speed in early stages.

---

## Kernel Philosophy

Pan OS is:
- **Monolithic**
- **Modular**
- **Cache-aware**
- **Minimal abstraction**
- **Low-overhead syscall model**

All major subsystems live in kernel space:
- Scheduler
- Memory Manager
- VFS
- Drivers
- Network stack

**Rules:**
- No driver runs in user space
- No IPC message passing between core subsystems
- Direct function calls preferred

---

## Global Architecture Rules

- All architecture-specific code: `kernel/arch/x86_64/`
- No dynamic allocation before heap ready
- No exceptions in kernel
- No RTTI in kernel
- STL forbidden inside kernel
- Every subsystem must expose minimal header interface
- No abstraction layers unless necessary for performance scaling

**Optimize for:**
- Cache locality
- Reduced context switches
- Reduced memory fragmentation

---

## Phases

### Phase 0 – Toolchain Control (MANDATORY)

- **Architecture:** x86_64-elf
- **Compiler flags:** `-ffreestanding -fno-exceptions -fno-rtti -mno-red-zone -mcmodel=kernel -O2` (later O3)
- **Bootloader:** GRUB (Multiboot2)
- **Deliverable:** Kernel boots via GRUB in 64-bit mode
- **Reason:** Focus on kernel engineering, not boot complexity

### Phase 1 – Minimal 64-bit Entry

**Folder:** `kernel/arch/x86_64/`

**Tasks:**
1. Define linker script for higher-half kernel
2. Setup stack
3. Confirm long mode
4. Map VGA memory
5. Print text

**Verification:** QEMU boot prints `PAN OS 64 BIT KERNEL INITIALIZED`. If fails → stop.

### Phase 2 – Memory Subsystem (Performance-Oriented)

**Folder:** `kernel/core/memory/`

**Strict order:**
1. Physical Memory Manager (bitmap or buddy allocator)
2. Paging (4-level paging)
3. Higher-half direct map
4. Kernel heap (bump allocator first)
5. Slab allocator (object caching for speed)

**Performance rules:** Avoid fragmentation, align allocations to cache lines (64 bytes), keep frequently used structs contiguous.

**Verification:** Allocate, free, stress test in loop.

### Phase 3 – Interrupt + Timer Core

**Folder:** `kernel/arch/x86_64/interrupts/`

**Tasks:** IDT setup, PIC remap, PIT timer, enable interrupts.

**Verification:** Timer interrupt increments counter. No scheduler yet.

### Phase 4 – Scheduler (Low Latency)

**Folder:** `kernel/core/scheduler/`

**Design:** Preemptive round-robin first. Later: priority-based.

**Performance:** Context switch in assembly, save minimal registers, avoid heap allocation in scheduler.

**Verification:** Two kernel threads alternate.

### Phase 5 – Syscall Fast Path

- Use **SYSCALL/SYSRET** (not `int 0x80`)
- **Folder:** `system/syscall/`
- **Verification:** User program prints via syscall

### Phase 6 – Driver Core

All drivers in kernel space. No message-based IPC.

**Order:** VGA → Keyboard → RAMDisk → ATA (PIO first) → PCI → USB (late) → Network (last)

### Phase 7 – VFS (Direct Call Model)

**Folder:** `fs/vfs/`

**Design:** VFS dispatch through function pointers. No message passing. No user-mode FS servers.

**Order:** VFS core → tmpfs → devfs → FAT32 → EXT2

### Phase 8 – ELF Loader + Userspace

**Folder:** `kernel/core/loader/`, `apps/`, `lib/libc/`

**Tasks:** ELF parser, map user program memory, switch to ring 3, syscall interface.

**Verification:** Shell launches app.

---

## Performance Directives

- Kernel compiled with `-O2` minimum
- Avoid virtual functions in hot paths
- Use `inline` where necessary
- No heavy abstraction in drivers
- Keep structs POD where possible
- Reduce lock contention
- Prefer spinlocks over mutex in kernel

---

## Development Law

**Never move upward unless lower layer is stable.**

Dependency order:

```
Memory → Interrupts → Scheduler → Syscalls → Drivers → VFS → Userspace
```

---

## Forbidden

- Microkernel architecture
- Userspace drivers
- Heavy OOP inside hot kernel paths
- GUI before scheduler stable
- Network before VFS stable

---

## Long-term Target

Pan OS must:
- Boot in &lt; 1 second (QEMU baseline)
- Run multitasking
- Execute native apps
- Provide direct hardware performance API
- Support game engine integration

---

# Build System Architecture – Official Policy

Pan OS uses **CMake** as the official build orchestrator.

**CMake is used strictly as:**
- Target manager
- Dependency resolver
- Multi-directory coordinator

**CMake must NOT:**
- Control architecture decisions
- Override linker script behavior
- Inject host system libraries
- Enable hosted compilation mode

---

## Cross Compilation Rules

- Pan OS must always be built using a **cross compiler**
- **Target:** x86_64-elf
- Host compiler usage is strictly forbidden
- All builds must be freestanding

---

## Required Toolchain

- x86_64-elf-gcc
- x86_64-elf-g++
- nasm
- ld (cross)
- cmake
- qemu-system-x86_64
- **Bootloader:** GRUB (Multiboot2)

---

## Required Build Structure

```
pan-os/
├── CMakeLists.txt
├── toolchain-x86_64.cmake
├── linker.ld
├── kernel/
│   └── CMakeLists.txt
├── drivers/
│   └── CMakeLists.txt
├── fs/
│   └── CMakeLists.txt
├── lib/
│   └── CMakeLists.txt
├── system/
│   └── CMakeLists.txt
├── apps/
│   └── CMakeLists.txt
└── build/
```

---

## Mandatory Compiler Flags

**Kernel flags:**
- `-ffreestanding`
- `-fno-exceptions`
- `-fno-rtti`
- `-mno-red-zone`
- `-mcmodel=kernel`
- `-O2`

No standard library allowed. No libc linking.

---

## Linker Control

- **Custom linker script:** `linker.ld`
- CMake must pass: `-T linker.ld -nostdlib -static`
- Linker script defines: higher-half mapping, kernel entry point, section alignment, page alignment (4K minimum)

---

## Build Targets Required

- `kernel` (ELF)
- `iso` (bootable ISO)
- `run` (QEMU launch)
- `clean`
- `debug`

The `run` target must automatically boot using QEMU.

---

## ISO Generation Policy

**ISO must contain:**
- `/boot/kernel.elf`
- `/boot/grub/grub.cfg`

**ISO generation:** GRUB with Multiboot2

---

## Stability Law

Every successful build must:
1. Produce ELF kernel
2. Produce ISO
3. Boot in QEMU
4. Print boot confirmation

**If any of these fail → development must stop.**

---

## Growth Policy

As the project scales:
- Each subsystem must define its own `CMakeLists.txt`
- No monolithic CMake file allowed
- Subdirectories must expose only minimal public headers
