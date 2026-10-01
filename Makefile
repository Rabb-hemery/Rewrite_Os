ASM=nasm
SRC_DIR=src
BUILD_DIR=build

$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/main.bin
	cp $(BUILD_DIR)/main.bin $(BUILD_DIR)/main_floppy.img
	truncate -s 1440k $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main.bin: $(SRC_DIR)/main.asm
	mkdir -p $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/main.asm -f bin -o $(BUILD_DIR)/main.bin

run: $(BUILD_DIR)/main_floppy.img
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img

clean:
	rm -rf $(BUILD_DIR)

.PHONY: run clean
