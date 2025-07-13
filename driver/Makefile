# File: Makefile
# Desc: Customizable makefile for FPGA Coprocessor's linux driver.

# Target kernel version. A precombiled kernel modules are required for compilation.
KERNEL_VER ?= 5.10.110-v8+
# Architecture must be provided. For 32-bit targets: Raspberry Pi 1 (Model A, A+, B, B+), Raspberry Pi Zero / Zero W / Zero WH and
# Raspberry Pi 2 (Model B) an 'arm' architecture must be used. For 64-bit targets: Raspberry Pi 2 (Model B), Raspberry Pi 3 (Model B, B+, A+)
# Raspberry Pi 4 (Model B) and Raspberry Pi 400 an 'arm64' must be used. For 64-bit targets leave this default option unchanged. 
ARCH ?= arm64
# Compiler 'prefix' must be given for the main driver makefile script. For 64-bit targets leave this default option unchanged. For 32-bit targets
# 'arm-linux-gnueabi-' might be a possible option. If have some specific compiler to build your custom kernel, use it instead.
COMPILER ?= aarch64-linux-gnu-

obj-m += fpgacoproc.o
fpgacoproc-objs += mod.o spi.o 
ccflags-y += -DDEBUG

# Kernel headers directory. Can be adjusted when calling.
KDIR ?= /lib/modules/$(KERNEL_VER)/build

# FPGA Coprocessor overlay that must be used alongside this driver. Must be aligned with used chip model. 
DTO_OVERLAY ?= bcm2711-fpga-coprocessor.dtso
DTO_OVERLAY_S := ./overlays/$(DTO_OVERLAY)
DTO_OVERLAY_O := ${DTO_OVERLAY_S:.dtso=.dtbo}

all:
	make -C $(KDIR) M=$(CURDIR) ARCH=$(ARCH) CROSS_COMPILE=$(COMPILER) CFLAGS_MODULE="$(EXTRA_CFLAGS)" modules

dto:
	gcc -xc -E -P $(DTOFLAGS) $(DTO_OVERLAY_S) | tee /dev/tty | dtc -@ -I dts -O dtb -o $(DTO_OVERLAY_O)

clean:
	make -C $(KDIR) M=$(CURDIR) clean

clean_dto:
	@rm -rf $(wildcard ../dt_overlays/*.dtbo) 
