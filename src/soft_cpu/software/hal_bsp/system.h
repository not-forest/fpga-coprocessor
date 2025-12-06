/*
 * system.h - SOPC Builder system and BSP software package information
 *
 * Machine generated for CPU 'CPU' in SOPC Builder design 'niosv_cpu'
 * SOPC Builder design path: /home/notforest/Documents/fpga-coprocessor/src/soft_cpu/niosv_cpu.sopcinfo
 *
 * Generated: Sat Dec 06 22:38:11 UTC 2025
 */

/*
 * DO NOT MODIFY THIS FILE
 *
 * Changing this file will have subtle consequences
 * which will almost certainly lead to a nonfunctioning
 * system. If you do modify this file, be aware that your
 * changes will be overwritten and lost when this file
 * is generated again.
 *
 * DO NOT MODIFY THIS FILE
 */

/*
 * License Agreement
 *
 * Copyright (c) 2008
 * Altera Corporation, San Jose, California, USA.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * This agreement shall be governed in all respects by the laws of the State
 * of California and by the laws of the United States of America.
 */

#ifndef __SYSTEM_H_
#define __SYSTEM_H_

/* Include definitions from linker script generator */
#include "linker.h"


/*
 * CPU configuration
 *
 */

#define ALT_CPU_ARCHITECTURE "intel_niosv_c"
#define ALT_CPU_CPU_FREQ 50000000u
#define ALT_CPU_DATA_ADDR_WIDTH 0x20
#define ALT_CPU_DCACHE_LINE_SIZE 0
#define ALT_CPU_DCACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_DCACHE_SIZE 0
#define ALT_CPU_FREQ 50000000
#define ALT_CPU_HAS_CSR_SUPPORT 0
#define ALT_CPU_ICACHE_LINE_SIZE 0
#define ALT_CPU_ICACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_ICACHE_SIZE 0
#define ALT_CPU_INST_ADDR_WIDTH 0x20
#define ALT_CPU_NAME "CPU"
#define ALT_CPU_NIOSV_CORE_VARIANT 4
#define ALT_CPU_NUM_GPR 32
#define ALT_CPU_RESET_ADDR 0x00028000


/*
 * CPU configuration (with legacy prefix - don't use these anymore)
 *
 */

#define NIOSVSMALLCORE_CPU_FREQ 50000000u
#define NIOSVSMALLCORE_DATA_ADDR_WIDTH 0x20
#define NIOSVSMALLCORE_DCACHE_LINE_SIZE 0
#define NIOSVSMALLCORE_DCACHE_LINE_SIZE_LOG2 0
#define NIOSVSMALLCORE_DCACHE_SIZE 0
#define NIOSVSMALLCORE_HAS_CSR_SUPPORT 0
#define NIOSVSMALLCORE_ICACHE_LINE_SIZE 0
#define NIOSVSMALLCORE_ICACHE_LINE_SIZE_LOG2 0
#define NIOSVSMALLCORE_ICACHE_SIZE 0
#define NIOSVSMALLCORE_INST_ADDR_WIDTH 0x20
#define NIOSVSMALLCORE_NIOSV_CORE_VARIANT 4
#define NIOSVSMALLCORE_NUM_GPR 32
#define NIOSVSMALLCORE_RESET_ADDR 0x00028000


/*
 * DATA_BATCH configuration
 *
 */

#define ALT_MODULE_CLASS_DATA_BATCH systolic_batch_block
#define DATA_BATCH_BASE 0x30040
#define DATA_BATCH_IRQ -1
#define DATA_BATCH_IRQ_INTERRUPT_CONTROLLER_ID -1
#define DATA_BATCH_NAME "/dev/DATA_BATCH"
#define DATA_BATCH_SPAN 64
#define DATA_BATCH_TYPE "systolic_batch_block"


/*
 * DEBUG configuration
 *
 */

#define ALT_MODULE_CLASS_DEBUG altera_avalon_uart
#define DEBUG_BASE 0x0
#define DEBUG_BAUD 9600
#define DEBUG_DATA_BITS 8
#define DEBUG_FIXED_BAUD 1
#define DEBUG_FREQ 50000000
#define DEBUG_IRQ -1
#define DEBUG_IRQ_INTERRUPT_CONTROLLER_ID -1
#define DEBUG_NAME "/dev/DEBUG"
#define DEBUG_PARITY 'N'
#define DEBUG_SIM_CHAR_STREAM ""
#define DEBUG_SIM_TRUE_BAUD 0
#define DEBUG_SPAN 32
#define DEBUG_STOP_BITS 1
#define DEBUG_SYNC_REG_DEPTH 2
#define DEBUG_TYPE "altera_avalon_uart"
#define DEBUG_USE_CTS_RTS 1
#define DEBUG_USE_EOP_REGISTER 0


/*
 * Define for each module class mastered by the CPU
 *
 */

#define __ALTERA_AVALON_ONCHIP_MEMORY2
#define __ALTERA_AVALON_SPI
#define __ALTERA_AVALON_UART
#define __INTEL_NIOSV_C
#define __SYSTOLIC_BATCH_BLOCK
#define __SYSTOLIC_SERIALIZER


/*
 * MEM configuration
 *
 */

#define ALT_MODULE_CLASS_MEM altera_avalon_onchip_memory2
#define MEM_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define MEM_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define MEM_BASE 0x28000
#define MEM_CONTENTS_INFO ""
#define MEM_DUAL_PORT 0
#define MEM_GUI_RAM_BLOCK_TYPE "AUTO"
#define MEM_INIT_CONTENTS_FILE "SRAM"
#define MEM_INIT_MEM_CONTENT 1
#define MEM_INSTANCE_ID "NONE"
#define MEM_IRQ -1
#define MEM_IRQ_INTERRUPT_CONTROLLER_ID -1
#define MEM_NAME "/dev/MEM"
#define MEM_NON_DEFAULT_INIT_FILE_ENABLED 1
#define MEM_RAM_BLOCK_TYPE "AUTO"
#define MEM_READ_DURING_WRITE_MODE "DONT_CARE"
#define MEM_SINGLE_CLOCK_OP 0
#define MEM_SIZE_MULTIPLE 1
#define MEM_SIZE_VALUE 20480
#define MEM_SPAN 20480
#define MEM_TYPE "altera_avalon_onchip_memory2"
#define MEM_WRITABLE 1


/*
 * SERIALIZER_0 configuration
 *
 */

#define ALT_MODULE_CLASS_SERIALIZER_0 systolic_serializer
#define SERIALIZER_0_BASE 0x300e0
#define SERIALIZER_0_IRQ -1
#define SERIALIZER_0_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SERIALIZER_0_NAME "/dev/SERIALIZER_0"
#define SERIALIZER_0_SPAN 8
#define SERIALIZER_0_TYPE "systolic_serializer"


/*
 * SPI_0 configuration
 *
 */

#define ALT_MODULE_CLASS_SPI_0 altera_avalon_spi
#define SPI_0_BASE 0x300c0
#define SPI_0_CLOCKMULT 1
#define SPI_0_CLOCKPHASE 1
#define SPI_0_CLOCKPOLARITY 1
#define SPI_0_CLOCKUNITS "Hz"
#define SPI_0_DATABITS 8
#define SPI_0_DATAWIDTH 16
#define SPI_0_DELAYMULT "1.0E-9"
#define SPI_0_DELAYUNITS "ns"
#define SPI_0_EXTRADELAY 0
#define SPI_0_INSERT_SYNC 1
#define SPI_0_IRQ -1
#define SPI_0_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SPI_0_ISMASTER 0
#define SPI_0_LSBFIRST 0
#define SPI_0_NAME "/dev/SPI_0"
#define SPI_0_NUMSLAVES 1
#define SPI_0_PREFIX "spi_"
#define SPI_0_SPAN 32
#define SPI_0_SYNC_REG_DEPTH 2
#define SPI_0_TARGETCLOCK 128000u
#define SPI_0_TARGETSSDELAY "0.0"
#define SPI_0_TYPE "altera_avalon_spi"


/*
 * System configuration
 *
 */

#define ALT_DEVICE_FAMILY "Cyclone IV E"
#define ALT_IRQ_BASE NULL
#define ALT_LOG_PORT "/dev/null"
#define ALT_LOG_PORT_BASE 0x0
#define ALT_LOG_PORT_DEV null
#define ALT_LOG_PORT_TYPE ""
#define ALT_NUM_EXTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERRUPT_CONTROLLERS 0
#define ALT_STDERR "/dev/DEBUG"
#define ALT_STDERR_BASE 0x0
#define ALT_STDERR_DEV DEBUG
#define ALT_STDERR_IS_UART
#define ALT_STDERR_PRESENT
#define ALT_STDERR_TYPE "altera_avalon_uart"
#define ALT_STDIN "/dev/DEBUG"
#define ALT_STDIN_BASE 0x0
#define ALT_STDIN_DEV DEBUG
#define ALT_STDIN_IS_UART
#define ALT_STDIN_PRESENT
#define ALT_STDIN_TYPE "altera_avalon_uart"
#define ALT_STDOUT "/dev/DEBUG"
#define ALT_STDOUT_BASE 0x0
#define ALT_STDOUT_DEV DEBUG
#define ALT_STDOUT_IS_UART
#define ALT_STDOUT_PRESENT
#define ALT_STDOUT_TYPE "altera_avalon_uart"
#define ALT_SYSTEM_NAME "niosv_cpu"
#define ALT_SYS_CLK_TICKS_PER_SEC NONE_TICKS_PER_SEC
#define ALT_TIMESTAMP_CLK_TIMER_DEVICE_TYPE NONE_TIMER_DEVICE_TYPE


/*
 * WEIGHT_BATCH configuration
 *
 */

#define ALT_MODULE_CLASS_WEIGHT_BATCH systolic_batch_block
#define WEIGHT_BATCH_BASE 0x30000
#define WEIGHT_BATCH_IRQ -1
#define WEIGHT_BATCH_IRQ_INTERRUPT_CONTROLLER_ID -1
#define WEIGHT_BATCH_NAME "/dev/WEIGHT_BATCH"
#define WEIGHT_BATCH_SPAN 64
#define WEIGHT_BATCH_TYPE "systolic_batch_block"


/*
 * hal2 configuration
 *
 */

#define ALT_MAX_FD 0
#define ALT_SYS_CLK none
#define ALT_TIMESTAMP_CLK none
#define INTEL_FPGA_DFL_START_ADDRESS 0xffffffffffffffff
#define INTEL_FPGA_USE_DFL_WALKER 0

#endif /* __SYSTEM_H_ */
