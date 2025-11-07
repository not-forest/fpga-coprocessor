## Main project's root makefile.
##
## Compiles VHDL testbenches, internal soft CPU firmware and linux drivers from one place.

.PHONY: driver_make clean

SRC_DIR 	:= $(CURDIR)/src
DRIVER_DIR 	:= $(CURDIR)/driver
BUILD_DIR	:= $(CURDIR)/build
TB_DIR 		:= $(SRC_DIR)/tb
COPROC_LIB  := $(SRC_DIR)/ord.coproc

VHDL_ALTERA_LIBS := /usr/local/lib/ghdl/vendors/intel/

QUARTUS_ROOT_DIR ?= $(HOME)/intelFPGA_lite/24.1std
NIOS_SOFT_DIR := $(SRC_DIR)/soft_cpu/software

## Path configuration
# Test bench environment variable to show the results in GTKWare.
BENCH 		?= systolic_tb

## Toolchain configuration. 
GG 			?= ghdl
GTKW		?= gtkwave

NIOS		?= niosv

GG_FLAGS := --ieee=synopsys --workdir=build --work=coproc --std=08 -P${VHDL_ALTERA_LIBS}
NIOS_TOOLCHAIN_FLAGS := --bsp-dir=$(NIOS_SOFT_DIR)/hal_bsp
NIOS_TOOLCHAIN_FLAGS += --app-dir=$(NIOS_SOFT_DIR)/firmware
NIOS_TOOLCHAIN_FLAGS += --srcs=$(NIOS_SOFT_DIR)/firmware
NIOS_TOOLCHAIN_FLAGS += --elf-name=coproc_firmware.elf

NIOS_TOOLCHAIN := $(QUARTUS_ROOT_DIR)/riscfree/toolchain/riscv32-unknown-elf/bin

### Coprocessor Firmware ###

### Opens BSP editor for used NIOS soft CPU.
firmware_bsp_editor:
	$(NIOS)-bsp-editor

## Regenerates the compilation toolchain for NIOS soft CPU firmware.
firmware_toolchain_regenerate:
	$(NIOS)-app $(NIOS_TOOLCHAIN_FLAGS)

## Compiles the inner firmware for NIOS processor with required toolchain.
firmware_compile: firmware_toolchain_regenerate
	cd $(NIOS_SOFT_DIR)/hal_bsp && \
	PATH=$(NIOS_TOOLCHAIN):$$PATH \
	CMAKE_C_COMPILER=$(NIOS_TOOLCHAIN)/riscv32-unknown-elf-gcc \
	CMAKE_CXX_COMPILER=$(NIOS_TOOLCHAIN)/riscv32-unknown-elf-g++ \
	CMAKE_ASM_COMPILER=$(NIOS_TOOLCHAIN)/riscv32-unknown-elf-gcc \
	CMAKE_AR=$(NIOS_TOOLCHAIN)/riscv32-unknown-elf-ar \
	CMAKE_RANLIB=$(NIOS_TOOLCHAIN)/riscv32-unknown-elf-ranlib \
	bash -c 'cmake . && make'

	cd $(NIOS_SOFT_DIR)/firmware && \
	PATH=$(NIOS_TOOLCHAIN):$$PATH \
	CMAKE_C_COMPILER=$(NIOS_TOOLCHAIN)/riscv32-unknown-elf-gcc \
	CMAKE_CXX_COMPILER=$(NIOS_TOOLCHAIN)/riscv32-unknown-elf-g++ \
	CMAKE_ASM_COMPILER=$(NIOS_TOOLCHAIN)/riscv32-unknown-elf-gcc \
	CMAKE_AR=$(NIOS_TOOLCHAIN)/riscv32-unknown-elf-ar \
	CMAKE_RANLIB=$(NIOS_TOOLCHAIN)/riscv32-unknown-elf-ranlib \
	bash -c 'cmake . && make'

## Flashed output elf file to internal SRAM via JTAG.
firmware_flash: firmware_compile
	niosv-download --go $(NIOS_SOFT_DIR)/firmware/coproc_firmware.elf

### Coprocessor Firmware ###

### LINUX ###

# Compiles linux driver for FPGA coprocessor.
driver_make: __build_folder
	make -C $(DRIVER_DIR) all
	mkdir -p $(BUILD_DIR)/driver
	cp $(DRIVER_DIR)/*.ko $(BUILD_DIR)/driver

# Cleans driver files.
driver_clean: __build_folder
	make -C $(DRIVER_DIR) clean

# Compiles the device tree overlay for the driver.
driver_dto_make: __build_folder
	make -C $(DRIVER_DIR) dto

# Cleans dto files.
driver_dto_clean: __build_folder
	make -C $(DRIVER_DIR) clean_dto

__build_folder:
	@mkdir -p $(BUILD_DIR)

### LINUX ###

### TBS ###

# Performs a benchmark for chosen testbench and shows the result in GTKWave
benchmark: $(BUILD_DIR) check_bench ghdl_compile
	@echo "Running benchmarks for test bench: $(BENCH)"
	$(GG) -a $(GG_FLAGS) "$(TB_DIR)/$(BENCH).vhd";
	$(GG) -e $(GG_FLAGS) $(BENCH);
	$(GG) -r $(GG_FLAGS) $(BENCH) --wave="$(BUILD_DIR)/$(BENCH).ghw";
	@echo "Opening in wave viewer..."
	$(GTKW) $(BUILD_DIR)/$(BENCH).ghw &

ghdl_compile:
	@echo "Compiling VHDL main library..."
	@while IFS= read -r file; do				\
		$(GG) -a $(GG_FLAGS) $$file;    		\
	done < $(COPROC_LIB)

check_bench:
	@if [ ! -d "$(TB_DIR)" ]; then 						\
		echo "Error: No test bench directory found."; 	\
		exit 1; 										\
	fi

clean:
	rm -rf $(BUILD_DIR)
	@echo "Cleaned..."

### TBS ###

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
