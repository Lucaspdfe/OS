#include <stdint.h>
#include "string.h"
#include "stdio.h"
#include "x86.h"
#include "mbr.h"

void main(uint8_t bootDrive) {
    clearscreen();
    printf("Hello, world!\n");

    uint32_t vbr = MBR_GetBootableLBA(bootDrive);
    printf("Volume Boot Record LBA: 0x%08X", vbr);

    for(;;);
}