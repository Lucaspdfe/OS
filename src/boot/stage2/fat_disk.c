#include "fat_disk.h"
#include "x86.h"

/* The BIOS drive number passed to stage 2 (for example, 0x80). */
static uint8_t g_boot_drive;

static bool fat_disk_read_sector(uint8_t *buffer, uint32_t lba)
{
    /* disk_read returns zero on success and a BIOS status byte on failure. */
    return disk_read(g_boot_drive, (uint64_t)lba, 1, buffer) == 0;
}

static bool fat_disk_write_sector(const uint8_t *buffer, uint32_t lba)
{
    /* Stage 2 currently has no BIOS disk-write routine: stay read-only. */
    (void)buffer;
    (void)lba;
    return false;
}

void fat_disk_init(uint8_t boot_drive, DiskOps *ops)
{
    g_boot_drive = boot_drive;
    ops->read = fat_disk_read_sector;
    ops->write = fat_disk_write_sector;
}
