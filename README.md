# OS

A simple hobby OS I'm developing while going through middle/high school.

## Why suffer with this?

I got interested in OSDev due to microcontrollers and low-level C.

## Basic Q&A

Q: Do you have a name for this OS? 
A: No. If someone is reading this and has a name idea please suggest it.

Q: What are your plans? 
A: Make a OS with a from-scratch bootloader (UEFI and BIOS) and a x86_64 linux-compatible kernel.

Q: How do I build it?
A: In a later update I will make a set of instructions on how to compile and run the system.

Q: Do you plan on supporting real hardware?
A: Yes, this is the only reason why I'm supporting UEFI to boot the OS.

## Third-party code

The BIOS stage-2 bootloader vendors `ultraembedded/fat_io_lib` under
`src/boot/stage2/fat_io_lib`. That component is licensed under GPL-3.0;
its license and provenance are included alongside the vendored sources.
The root `LICENSE` continues to describe the original OS code. A build
that incorporates the FAT library must be distributed in compliance with
the GPL-3.0 terms applicable to the combined work.
