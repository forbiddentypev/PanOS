#pragma once

namespace pan::arch {

void serial_init();
void serial_write(const char* str);
void serial_putchar(char c);

}  // namespace pan::arch
