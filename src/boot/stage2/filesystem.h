#pragma once
#include <stdint.h>

/* Mount the FAT16/FAT32 volume on the BIOS boot drive. Returns 0 on success. */
int filesystem_init(uint8_t boot_drive);

/* Open an existing file for reading. Returns NULL if it cannot be opened. */
void *filesystem_open(const char *path);

/* Read up to byte_count bytes. Returns bytes read; 0 at EOF (or an I/O
 * failure reported as no data by the underlying library); -1 for bad arguments. */
int filesystem_read(void *file, void *buffer, uint32_t byte_count);

/* Close an open file handle. */
void filesystem_close(void *file);
