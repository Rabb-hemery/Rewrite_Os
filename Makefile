# Open Watcom : on suppose qu'il est installé dans /opt/watcom (modifiable : make WATCOM=/autre/chemin)
export WATCOM ?= /opt/watcom
export PATH := $(WATCOM)/binl64:$(WATCOM)/binl:$(PATH)

ASM=nasm
SRC_DIR=src
BUILD_DIR=$(abspath build)

.PHONY: all floppy_image bootloader stage1 stage2 kernel tools_fat clean always run run-monitor

all: floppy_image tools_fat

#
# Image disquette FAT12
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: stage1 stage2 kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "REWRITEOS" $(BUILD_DIR)/main_floppy.img
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/stage2.bin "::stage2.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img test.txt "::test.txt"
	mmd -i $(BUILD_DIR)/main_floppy.img "::mydir"
	mcopy -i $(BUILD_DIR)/main_floppy.img test.txt "::mydir/test.txt"
	seq 1 2000 > $(BUILD_DIR)/bigfile.txt
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/bigfile.txt "::bigfile.txt"

#
# Bootloader (en deux étapes)
#
bootloader: stage1 stage2

stage1: always
	$(MAKE) -C $(SRC_DIR)/bootloader/stage1 BUILD_DIR=$(BUILD_DIR)

stage2: always
	$(MAKE) -C $(SRC_DIR)/bootloader/stage2 BUILD_DIR=$(BUILD_DIR)

#
# Kernel
#
kernel: always
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(BUILD_DIR)

#
# Outil FAT (tourne sur ton PC, pour comprendre FAT12)
#
tools_fat: $(BUILD_DIR)/tools/fat

$(BUILD_DIR)/tools/fat: tools/fat/fat.c | always
	mkdir -p $(BUILD_DIR)/tools
	gcc -g -Wall -o $(BUILD_DIR)/tools/fat tools/fat/fat.c

#
# Utilitaires
#
always:
	mkdir -p $(BUILD_DIR)

clean:
	$(MAKE) -C $(SRC_DIR)/bootloader/stage1 BUILD_DIR=$(BUILD_DIR) clean
	$(MAKE) -C $(SRC_DIR)/bootloader/stage2 BUILD_DIR=$(BUILD_DIR) clean
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(BUILD_DIR) clean
	rm -rf $(BUILD_DIR)

run: floppy_image
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img

# QEMU avec son moniteur dans le terminal : tape par exemple  xp /16xb 0x7e00
run-monitor: floppy_image
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img -monitor stdio
