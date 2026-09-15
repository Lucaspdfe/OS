BUILD_DIR ?= build/

ASM=nasm
ASMFLAGS = -f elf

CC=i686-elf-gcc
CFLAGS=-std=c99 -g -ffreestanding

LD = i686-elf-gcc
LINKFLAGS = -T linker.ld -nostdlib -ffreestanding -Wl,--oformat=binary

SOURCES_C=$(wildcard *.c)
SOURCES_ASM=$(wildcard *.asm)
OBJECTS_C=$(patsubst %.c, $(BUILD_DIR)/stage2/c/%.obj, $(SOURCES_C))
OBJECTS_ASM=$(patsubst %.asm, $(BUILD_DIR)/stage2/asm/%.obj, $(SOURCES_ASM))

.PHONY: all stage2 clean
all: stage2

stage2: $(BUILD_DIR)/stage2.bin
$(BUILD_DIR)/stage2.bin: $(OBJECTS_ASM) $(OBJECTS_C)
	$(LD) $(LINKFLAGS) -Wl,-Map=$(BUILD_DIR)/stage2.map -o $@ $^

$(BUILD_DIR)/stage2/c/%.obj: %.c
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/stage2/asm/%.obj: %.asm
	mkdir -p $(@D)
	$(ASM) $(ASMFLAGS) -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
