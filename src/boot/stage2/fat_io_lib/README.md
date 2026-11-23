# FAT IO library

Vendored from https://github.com/ultraembedded/fat_io_lib (FAT16/FAT32
library, upstream version 2.6). The upstream GPL-3.0 license is included in
this directory as `LICENSE`.

The boot-stage configuration in `src/fat_custom.h` disables writes,
formatting, timestamps, and directory listing. The OS provides the disk
read callback; it uses the BIOS boot drive and absolute LBAs.

The upstream sources have only had unused hosted-C-library includes removed
where they are not needed by this freestanding build. See the source headers
for the original copyright and license notices.
