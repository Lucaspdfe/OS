#pragma once
#include <stdint.h>
#include <stdbool.h>

void __attribute__((cdecl)) outb(uint16_t port, uint8_t value);
uint8_t __attribute__((cdecl)) inb(uint16_t port);
uint8_t __attribute__((cdecl)) disk_read(uint8_t disk, uint64_t LBA, uint16_t sectors, void* buffer);
