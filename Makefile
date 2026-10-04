ASM=nasm
SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_image kernel bootloader tools_fat clean always run run-monitor

all: floppy_image tools_fat

#
# Image disquette FAT12
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "REWRITEOS" $(BUILD_DIR)/main_floppy.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img test.txt "::test.txt"

#
# Bootloader
#
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

#
# Outil FAT (tourne sur ton PC, pour comprendre FAT12)
#
tools_fat: $(BUILD_DIR)/tools/fat

$(BUILD_DIR)/tools/fat: always tools/fat/fat.c
	mkdir -p $(BUILD_DIR)/tools
	gcc -g -Wall -o $(BUILD_DIR)/tools/fat tools/fat/fat.c

#
# Utilitaires
#
always:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

run: floppy_image
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img

# QEMU avec son moniteur dans le terminal : tape par exemple  xp /16xb 0x7e00
run-monitor: floppy_image
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img -monitor stdio
