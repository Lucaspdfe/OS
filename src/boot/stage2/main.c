#include <stdint.h>
#include "string.h"
#include "stdio.h"
#include "x86.h"
#include "mbr.h"
#include "filesystem.h"

void main(uint8_t bootDrive) {
    clearscreen();
    printf("Hello, world!\n");

    uint32_t vbr = MBR_GetBootableLBA(bootDrive);
    printf("Volume Boot Record LBA: 0x%08X\n", vbr);

    int fs_status = filesystem_init(bootDrive);
    if (fs_status != 0) {
        printf("FAT mount failed: %d\n", fs_status);
        for (;;);
    }

    printf("FAT16/FAT32 mounted. Reading test.txt:\n");

    void *file = filesystem_open("test.txt");
    if (!file) {
        printf("Could not open test.txt\n");
        for (;;);
    }

    char buffer[128];
    int bytes_read;

    while ((bytes_read = filesystem_read(file, buffer, sizeof(buffer))) > 0) {
        for (int i = 0; i < bytes_read; ++i)
            printf("%c", buffer[i]);
    }

    if (bytes_read < 0)
        printf("\nRead error.\n");

    filesystem_close(file);

    for (;;);
}
