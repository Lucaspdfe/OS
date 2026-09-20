#include <stdint.h>
#include "stdio.h"
#include "x86.h"

void main(uint8_t bootDrive) {
    uint8_t buffer[512];

    uint8_t error = disk_read(bootDrive, 0, 1, buffer);
    if (error) {
        printf("Read failed!!! Error: %d", error);
    }

    if (buffer[510] == 0x55 && buffer[511] == 0xAA) printf("read working!");
    else printf("read not working...");
    for(;;);
}