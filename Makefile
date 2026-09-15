BUILD_DIR=build

ASM=nasm

.PHONY: all stage1 stage2 image clean always
all: image

image: $(BUILD_DIR)/img.raw
$(BUILD_DIR)/img.raw: stage1 stage2 always
	truncate -s 64M $@
	parted -s $@ mklabel msdos \
		      mkpart primary fat32 1MiB 100% \
		      set 1 boot on
	mkfs.fat -F 32 --offset 2048 -h 2048 $@
	install-mbr $@
	
	# Write first 3 bytes (jump and nop)
	dd if=$(BUILD_DIR)/stage1.bin of=$@ bs=1 count=3 seek=1048576 conv=notrunc
	
	# write rest of stage1 (skipping over BPB)
	dd if=$(BUILD_DIR)/stage1.bin of=$@ bs=1 skip=90 seek=1048666 conv=notrunc

	# copy stage2.bin to the image
	mcopy -i $@@@1048576 $(BUILD_DIR)/stage2.bin ::

	# copy test.txt to the image
	mcopy -i $@@@1048576 test.txt ::

stage1: $(BUILD_DIR)/stage1.bin
$(BUILD_DIR)/stage1.bin: src/boot/stage1/boot.asm always
	$(ASM) -f bin $< -o $@

stage2: $(BUILD_DIR)/stage2.bin
$(BUILD_DIR)/stage2.bin: always
	$(MAKE) --no-print-directory -C src/boot/stage2 BUILD_DIR=$(abspath $(BUILD_DIR))

clean:
	rm -rf build

always:
	mkdir -p build

run:
	./run.sh
