## Main project's root makefile.
##
## Used to compile both testbenches and linux drivers for the coprocessor unit.

.PHONY: driver_make clean

SRC_DIR 	:= $(CURDIR)/src
DRIVER_DIR 	:= $(CURDIR)/driver
BUILD_DIR	:= $(CURDIR)/build
TB_DIR 		:= $(SRC_DIR)/tb
COPROC_LIB  := $(SRC_DIR)/ord.coproc

DRIVER_FILES = $(wildcard $(DRIVER_DIR)*.ko)

## Path configuration
# Test bench environment variable to show the results in GTKWare.
BENCH 		?= pll_tb

## Toolchain configuration. 
GG 			?= ghdl
GTKW		?= gtkwave

GG_FLAGS := --ieee=synopsys --workdir=build --work=coproc --std=08 -P/home/notforest/ghdl/scripts/vendors/altera

### LINUX ###

# Compiles linux driver for FPGA coprocessor.
driver_make: __build_folder
	make -C $(DRIVER_DIR) all
	mkdir -p $(BUILD_DIR)/driver
	cp $(DRIVER_FILES) $(DRIVER_DIR)/driver

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
