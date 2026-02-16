# Pan OS – Phase 0
# Wrapper for CMake build

BUILD_DIR ?= build

all: $(BUILD_DIR)/pan.iso

$(BUILD_DIR)/pan.iso:
	@mkdir -p $(BUILD_DIR)/iso/boot/grub
	cp $(BUILD_DIR)/pan_kernel $(BUILD_DIR)/iso/boot/
	echo 'set timeout=0' > $(BUILD_DIR)/iso/boot/grub/grub.cfg
	echo 'set default=0' >> $(BUILD_DIR)/iso/boot/grub/grub.cfg
	echo 'menuentry "PanOS" { multiboot2 /boot/pan_kernel; boot }' >> $(BUILD_DIR)/iso/boot/grub/grub.cfg
	grub2-mkrescue -o $(BUILD_DIR)/pan.iso $(BUILD_DIR)/iso


run: $(BUILD_DIR)/pan.iso
	qemu-system-x86_64 -cdrom $(BUILD_DIR)/pan.iso

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all run clean
