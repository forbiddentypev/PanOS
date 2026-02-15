# Pan OS – Phase 0
# Wrapper for CMake build

BUILD_DIR ?= build

all: $(BUILD_DIR)/pan.iso

$(BUILD_DIR)/pan.iso:
	@mkdir -p $(BUILD_DIR)
	cmake -B $(BUILD_DIR) -S .
	$(MAKE) -C $(BUILD_DIR) pan_iso

run: $(BUILD_DIR)/pan.iso
	qemu-system-x86_64 -cdrom $(BUILD_DIR)/pan.iso

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all run clean
