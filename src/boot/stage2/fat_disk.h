#pragma once

#include <stdint.h>
#include "fat.h"

/* Bind FAT32's 512-byte LBA callbacks to the BIOS disk used to boot stage 2. */
void fat_disk_init(uint8_t boot_drive, DiskOps *ops);
