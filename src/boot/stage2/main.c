#include <stdint.h>
#include "string.h"
#include "stdio.h"
#include "x86.h"
#include "mbr.h"
#include "fat.h"
#include "fat_disk.h"

/* These objects must outlive the mounted filesystem. */
static Fat root_fs;
static DiskOps disk_ops;

void main(uint8_t bootDrive)
{
    clearscreen();
    printf("Hello, world!\n");

    uint32_t vbr = MBR_GetBootableLBA(bootDrive);
    printf("Volume Boot Record LBA: 0x%08X\n", vbr);

    fat_disk_init(bootDrive, &disk_ops);

    /* Partition 0 is the first MBR partition, as used by the current image. */
    int err = fat_mount(&disk_ops, 0, &root_fs, "root");
    if (err != FAT_ERR_NONE) {
        printf("FAT32 mount failed: %s (%d)\n", fat_get_error(err), err);
        for (;;) { __asm__ volatile ("hlt"); }
    }

    printf("FAT32 mounted at /root\n");

    Dir dir;
    err = fat_dir_open(&dir, "/root");
    if (err != FAT_ERR_NONE) {
        printf("Could not open root directory: %s\n", fat_get_error(err));
        for (;;) { __asm__ volatile ("hlt"); }
    }

    DirInfo info;
    printf("Root directory:\n");
    while ((err = fat_dir_read(&dir, &info)) == FAT_ERR_NONE) {
        if (info.name_len < sizeof(info.name))
            info.name[info.name_len] = '\0';
        else
            info.name[sizeof(info.name) - 1] = '\0';

        printf("  %s %s (%u bytes)\n",
               (info.attr & FAT_ATTR_DIR) ? "[DIR] " : "[FILE]",
               info.name,
               info.size);
    }

    if (err != FAT_ERR_EOF)
        printf("Directory read failed: %s\n", fat_get_error(err));

    /* This stage currently exposes read-only directory browsing. */
    for (;;) { __asm__ volatile ("hlt"); }
}
