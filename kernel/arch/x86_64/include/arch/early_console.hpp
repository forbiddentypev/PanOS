#pragma once

namespace pan::arch {

void early_console_init();
void early_console_write(const char* str);

/** Enable dual output (VGA + serial). Call after serial_init(). */
void early_console_enable_serial();

/** Prints to both VGA and serial when serial enabled. */
void early_console_write_dual(const char* str);

/** Verifies kernel is running from higher-half (0xFFFFFFFF80000000+). */
void early_console_test_higher_half();

}  // namespace pan::arch
