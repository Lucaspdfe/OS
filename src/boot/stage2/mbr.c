#include "mbr.h"
#include "x86.h"

uint32_t MBR_GetBootableLBA(uint8_t disk) {
    uint8_t buffer[512];
    disk_read(disk, 0, 1, buffer);

    uint16_t index = 446;
    for (int i = 0; i < 4; i++) {
        if (buffer[index] & 0x80) {
            index += 8;
            uint32_t lba =
                (uint32_t)buffer[index] |
                ((uint32_t)buffer[index + 1] << 8) |
                ((uint32_t)buffer[index + 2] << 16) |
                ((uint32_t)buffer[index + 3] << 24);
            return lba;
        }
        index += 16;
    }
    return 0;
}
