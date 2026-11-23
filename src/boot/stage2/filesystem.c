#include <stdint.h>
#include "filesystem.h"
#include "x86.h"
#include "fat_io_lib/src/fat_filelib.h"

#define DISK_SECTOR_SIZE 512U

static uint8_t filesystem_boot_drive;

/*
 * fat_io_lib expects absolute disk LBAs and a 1=success/0=failure result.
 * The BIOS wrapper returns 0 on success and a nonzero BIOS status on error.
 * Read one sector per BIOS call to avoid EDD transfer-size and 64 KiB boundary
 * restrictions on firmware implementations.
 */
static int filesystem_media_read(uint32 sector, uint8 *buffer, uint32 sector_count)
{
    uint32 i;

    if (!buffer)
        return 0;

    for (i = 0; i < sector_count; ++i)
    {
        if (disk_read(filesystem_boot_drive,
                      (uint64_t)(sector + i),
                      1,
                      buffer + (i * DISK_SECTOR_SIZE)) != 0)
            return 0;
    }

    return 1;
}

int filesystem_init(uint8_t boot_drive)
{
    filesystem_boot_drive = boot_drive;
    return fl_attach_media(filesystem_media_read, 0);
}

void *filesystem_open(const char *path)
{
    return fl_fopen(path, "rb");
}

int filesystem_read(void *file, void *buffer, uint32_t byte_count)
{
    int result;

    if (!file || !buffer || byte_count > 0x7FFFFFFFU)
        return -1;

    if (fl_feof(file))
        return 0;

    result = fl_fread(buffer, 1, (int)byte_count, file);
    return result < 0 ? -1 : result;
}

void filesystem_close(void *file)
{
    if (file)
        fl_fclose(file);
}
