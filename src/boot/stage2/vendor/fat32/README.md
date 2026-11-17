# FAT32 integration (stage 2)

Stage 2 vendors the minimal FAT32 implementation by Bjørn Brodtkorb from
https://github.com/strawberryhacker/fat32 (BSD-3-Clause; see LICENSE).

The adapter in fat_disk.c maps the library's one-sector, 512-byte LBA callbacks
to the BIOS disk_read routine and uses the boot drive supplied by stage 1.
The current BIOS disk interface has no write routine, so the adapter is
intentionally read-only. The demonstration mounts MBR partition 0 as /root
and lists its root directory. File writes must not be enabled until a reliable
BIOS disk-write implementation and error handling are added.

The upstream library currently supports MBR partition tables and FAT32 only;
it is not a GPT or FAT12/FAT16 implementation. Its DiskOps sector argument is
32-bit, so the adapter cannot address sectors beyond that range.
