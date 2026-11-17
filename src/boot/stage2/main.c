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

static void print_text_byte(uint8_t byte)
{
    /* Keep normal text formatting; make binary/control bytes visible. */
    if (byte == '\n' || byte == '\r' || byte == '\t' ||
        (byte >= 0x20 && byte <= 0x7e)) {
        putc((char)byte);
    } else {
        putc('.');
    }
}

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
        
        err = fat_dir_next(&dir);
        
        if (err == FAT_ERR_EOF)
            break;
        
        if (err != FAT_ERR_NONE)
            break;
    }
    
    if (err != FAT_ERR_NONE && err != FAT_ERR_EOF)
        printf("Directory read failed: %s\n", fat_get_error(err));

    File test_file;
    err = fat_file_open(&test_file, "/root/TEST.TXT", FAT_READ);
    if (err != FAT_ERR_NONE) {
        printf("Could not open TEST.TXT: %s (%d)\n",
               fat_get_error(err), err);
        for (;;) { __asm__ volatile ("hlt"); }
    }

    printf("\nContents of TEST.TXT (%u bytes):\n", test_file.size);

    uint8_t buffer[128];
    uint32_t total_read = 0;

    for (;;) {
        int bytes_read = 0;
        err = fat_file_read(&test_file, buffer, sizeof(buffer), &bytes_read);
        if (err != FAT_ERR_NONE) {
            printf("\nFile read failed: %s (%d)\n", fat_get_error(err), err);
            break;
        }

        if (bytes_read == 0)
            break;

        for (int i = 0; i < bytes_read; i++)
            print_text_byte(buffer[i]);

        total_read += (uint32_t)bytes_read;
    }

    printf("\n\nRead %u bytes from TEST.TXT.\n", total_read);

    /*
     * Do not call fat_file_close() yet: this stage's disk adapter is read-only,
     * while the upstream close/sync path attempts to update the access date.
     * The file remains open until stage 2 halts below.
     */
    for (;;) { __asm__ volatile ("hlt"); }
}
