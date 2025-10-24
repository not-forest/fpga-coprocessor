/*
 * system.h - SOPC Builder system and BSP software package information
 *
 * Machine generated for CPU 'CPU' in SOPC Builder design 'coproc_soft_cpu'
 * SOPC Builder design path: /home/notforest/Documents/fpga-coprocessor/src/soft_cpu/coproc_soft_cpu.sopcinfo
 *
 * Generated: Fri Oct 24 20:44:22 UTC 2025
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

#define ALT_CPU_ARCHITECTURE "intel_niosv_m"
#define ALT_CPU_CPU_FREQ 100000000u
#define ALT_CPU_DATA_ADDR_WIDTH 0x20
#define ALT_CPU_DCACHE_LINE_SIZE 0
#define ALT_CPU_DCACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_DCACHE_SIZE 0
#define ALT_CPU_FREQ 100000000
#define ALT_CPU_HAS_CSR_SUPPORT 1
#define ALT_CPU_HAS_DEBUG_STUB
#define ALT_CPU_ICACHE_LINE_SIZE 0
#define ALT_CPU_ICACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_ICACHE_SIZE 0
#define ALT_CPU_INST_ADDR_WIDTH 0x20
#define ALT_CPU_INT_MODE 0
#define ALT_CPU_MTIME_OFFSET 0x00030000
#define ALT_CPU_NAME "CPU"
#define ALT_CPU_NIOSV_CORE_VARIANT 1
#define ALT_CPU_NUM_GPR 32
#define ALT_CPU_RESET_ADDR 0x00028000
#define ALT_CPU_TICKS_PER_SEC NIOSV_INTERNAL_TIMER_TICKS_PER_SECOND
#define ALT_CPU_TIMER_DEVICE_TYPE 2


/*
 * CPU configuration (with legacy prefix - don't use these anymore)
 *
 */

#define ABBOTTSLAKE_CPU_FREQ 100000000u
#define ABBOTTSLAKE_DATA_ADDR_WIDTH 0x20
#define ABBOTTSLAKE_DCACHE_LINE_SIZE 0
#define ABBOTTSLAKE_DCACHE_LINE_SIZE_LOG2 0
#define ABBOTTSLAKE_DCACHE_SIZE 0
#define ABBOTTSLAKE_HAS_CSR_SUPPORT 1
#define ABBOTTSLAKE_HAS_DEBUG_STUB
#define ABBOTTSLAKE_ICACHE_LINE_SIZE 0
#define ABBOTTSLAKE_ICACHE_LINE_SIZE_LOG2 0
#define ABBOTTSLAKE_ICACHE_SIZE 0
#define ABBOTTSLAKE_INST_ADDR_WIDTH 0x20
#define ABBOTTSLAKE_INT_MODE 0
#define ABBOTTSLAKE_MTIME_OFFSET 0x00030000
#define ABBOTTSLAKE_NIOSV_CORE_VARIANT 1
#define ABBOTTSLAKE_NUM_GPR 32
#define ABBOTTSLAKE_RESET_ADDR 0x00028000
#define ABBOTTSLAKE_TICKS_PER_SEC NIOSV_INTERNAL_TIMER_TICKS_PER_SECOND
#define ABBOTTSLAKE_TIMER_DEVICE_TYPE 2


/*
 * CPU_dm_agent configuration
 *
 */

#define ALT_MODULE_CLASS_CPU_dm_agent intel_niosv_m
#define CPU_DM_AGENT_BASE 0x10000
#define CPU_DM_AGENT_CPU_FREQ 100000000u
#define CPU_DM_AGENT_DATA_ADDR_WIDTH 0x20
#define CPU_DM_AGENT_DCACHE_LINE_SIZE 0
#define CPU_DM_AGENT_DCACHE_LINE_SIZE_LOG2 0
#define CPU_DM_AGENT_DCACHE_SIZE 0
#define CPU_DM_AGENT_HAS_CSR_SUPPORT 1
#define CPU_DM_AGENT_HAS_DEBUG_STUB
#define CPU_DM_AGENT_ICACHE_LINE_SIZE 0
#define CPU_DM_AGENT_ICACHE_LINE_SIZE_LOG2 0
#define CPU_DM_AGENT_ICACHE_SIZE 0
#define CPU_DM_AGENT_INST_ADDR_WIDTH 0x20
#define CPU_DM_AGENT_INTERRUPT_CONTROLLER_ID 0
#define CPU_DM_AGENT_INT_MODE 0
#define CPU_DM_AGENT_IRQ -1
#define CPU_DM_AGENT_IRQ_INTERRUPT_CONTROLLER_ID -1
#define CPU_DM_AGENT_MTIME_OFFSET 0x00030000
#define CPU_DM_AGENT_NAME "/dev/CPU_dm_agent"
#define CPU_DM_AGENT_NIOSV_CORE_VARIANT 1
#define CPU_DM_AGENT_NUM_GPR 32
#define CPU_DM_AGENT_RESET_ADDR 0x00028000
#define CPU_DM_AGENT_SPAN 65536
#define CPU_DM_AGENT_TICKS_PER_SEC NIOSV_INTERNAL_TIMER_TICKS_PER_SECOND
#define CPU_DM_AGENT_TIMER_DEVICE_TYPE 2
#define CPU_DM_AGENT_TYPE "intel_niosv_m"


/*
 * CPU_timer_sw_agent configuration
 *
 */

#define ALT_MODULE_CLASS_CPU_timer_sw_agent intel_niosv_m
#define CPU_TIMER_SW_AGENT_BASE 0x30000
#define CPU_TIMER_SW_AGENT_CPU_FREQ 100000000u
#define CPU_TIMER_SW_AGENT_DATA_ADDR_WIDTH 0x20
#define CPU_TIMER_SW_AGENT_DCACHE_LINE_SIZE 0
#define CPU_TIMER_SW_AGENT_DCACHE_LINE_SIZE_LOG2 0
#define CPU_TIMER_SW_AGENT_DCACHE_SIZE 0
#define CPU_TIMER_SW_AGENT_HAS_CSR_SUPPORT 1
#define CPU_TIMER_SW_AGENT_HAS_DEBUG_STUB
#define CPU_TIMER_SW_AGENT_ICACHE_LINE_SIZE 0
#define CPU_TIMER_SW_AGENT_ICACHE_LINE_SIZE_LOG2 0
#define CPU_TIMER_SW_AGENT_ICACHE_SIZE 0
#define CPU_TIMER_SW_AGENT_INST_ADDR_WIDTH 0x20
#define CPU_TIMER_SW_AGENT_INTERRUPT_CONTROLLER_ID 0
#define CPU_TIMER_SW_AGENT_INT_MODE 0
#define CPU_TIMER_SW_AGENT_IRQ -1
#define CPU_TIMER_SW_AGENT_IRQ_INTERRUPT_CONTROLLER_ID -1
#define CPU_TIMER_SW_AGENT_MTIME_OFFSET 0x00030000
#define CPU_TIMER_SW_AGENT_NAME "/dev/CPU_timer_sw_agent"
#define CPU_TIMER_SW_AGENT_NIOSV_CORE_VARIANT 1
#define CPU_TIMER_SW_AGENT_NUM_GPR 32
#define CPU_TIMER_SW_AGENT_RESET_ADDR 0x00028000
#define CPU_TIMER_SW_AGENT_SPAN 64
#define CPU_TIMER_SW_AGENT_TICKS_PER_SEC NIOSV_INTERNAL_TIMER_TICKS_PER_SECOND
#define CPU_TIMER_SW_AGENT_TIMER_DEVICE_TYPE 2
#define CPU_TIMER_SW_AGENT_TYPE "intel_niosv_m"


/*
 * DEBUG_JTAG configuration
 *
 */

#define ALT_MODULE_CLASS_DEBUG_JTAG altera_avalon_jtag_uart
#define DEBUG_JTAG_BASE 0x30060
#define DEBUG_JTAG_IRQ 15
#define DEBUG_JTAG_IRQ_INTERRUPT_CONTROLLER_ID 0
#define DEBUG_JTAG_NAME "/dev/DEBUG_JTAG"
#define DEBUG_JTAG_READ_DEPTH 64
#define DEBUG_JTAG_READ_THRESHOLD 8
#define DEBUG_JTAG_SPAN 8
#define DEBUG_JTAG_TYPE "altera_avalon_jtag_uart"
#define DEBUG_JTAG_WRITE_DEPTH 64
#define DEBUG_JTAG_WRITE_THRESHOLD 8


/*
 * Define for each module class mastered by the CPU
 *
 */

#define __ALTERA_AVALON_JTAG_UART
#define __ALTERA_AVALON_ONCHIP_MEMORY2
#define __ALTERA_AVALON_SPI
#define __INTEL_NIOSV_M


/*
 * SPI_0 configuration
 *
 */

#define ALT_MODULE_CLASS_SPI_0 altera_avalon_spi
#define SPI_0_BASE 0x30040
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
#define SPI_0_IRQ 5
#define SPI_0_IRQ_INTERRUPT_CONTROLLER_ID 0
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
 * SRAM configuration
 *
 */

#define ALT_MODULE_CLASS_SRAM altera_avalon_onchip_memory2
#define SRAM_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define SRAM_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define SRAM_BASE 0x28000
#define SRAM_CONTENTS_INFO ""
#define SRAM_DUAL_PORT 0
#define SRAM_GUI_RAM_BLOCK_TYPE "AUTO"
#define SRAM_INIT_CONTENTS_FILE "SRAM"
#define SRAM_INIT_MEM_CONTENT 1
#define SRAM_INSTANCE_ID "NONE"
#define SRAM_IRQ -1
#define SRAM_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SRAM_NAME "/dev/SRAM"
#define SRAM_NON_DEFAULT_INIT_FILE_ENABLED 1
#define SRAM_RAM_BLOCK_TYPE "AUTO"
#define SRAM_READ_DURING_WRITE_MODE "DONT_CARE"
#define SRAM_SINGLE_CLOCK_OP 0
#define SRAM_SIZE_MULTIPLE 1
#define SRAM_SIZE_VALUE 25600
#define SRAM_SPAN 25600
#define SRAM_TYPE "altera_avalon_onchip_memory2"
#define SRAM_WRITABLE 1


/*
 * System configuration
 *
 */

#define ALT_DEVICE_FAMILY "Cyclone IV E"
#define ALT_ENHANCED_INTERRUPT_API_PRESENT
#define ALT_IRQ_BASE NULL
#define ALT_LOG_PORT "/dev/DEBUG_JTAG"
#define ALT_LOG_PORT_BASE 0x30060
#define ALT_LOG_PORT_DEV DEBUG_JTAG
#define ALT_LOG_PORT_IS_JTAG_UART
#define ALT_LOG_PORT_PRESENT
#define ALT_LOG_PORT_TYPE ALTERA_AVALON_JTAG_UART
#define ALT_NUM_EXTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERNAL_INTERRUPT_CONTROLLERS 1
#define ALT_NUM_INTERRUPT_CONTROLLERS 1
#define ALT_STDERR "/dev/DEBUG_JTAG"
#define ALT_STDERR_BASE 0x30060
#define ALT_STDERR_DEV DEBUG_JTAG
#define ALT_STDERR_IS_JTAG_UART
#define ALT_STDERR_PRESENT
#define ALT_STDERR_TYPE "altera_avalon_jtag_uart"
#define ALT_STDIN "/dev/DEBUG_JTAG"
#define ALT_STDIN_BASE 0x30060
#define ALT_STDIN_DEV DEBUG_JTAG
#define ALT_STDIN_IS_JTAG_UART
#define ALT_STDIN_PRESENT
#define ALT_STDIN_TYPE "altera_avalon_jtag_uart"
#define ALT_STDOUT "/dev/DEBUG_JTAG"
#define ALT_STDOUT_BASE 0x30060
#define ALT_STDOUT_DEV DEBUG_JTAG
#define ALT_STDOUT_IS_JTAG_UART
#define ALT_STDOUT_PRESENT
#define ALT_STDOUT_TYPE "altera_avalon_jtag_uart"
#define ALT_SYSTEM_NAME "coproc_soft_cpu"
#define ALT_SYS_CLK_TICKS_PER_SEC ALT_CPU_TICKS_PER_SEC
#define ALT_TIMESTAMP_CLK_TIMER_DEVICE_TYPE ALT_CPU_TIMER_DEVICE_TYPE


/*
 * hal2 configuration
 *
 */

#define ALT_INCLUDE_INSTRUCTION_RELATED_EXCEPTION_API
#define ALT_MAX_FD 4
#define ALT_SYS_CLK CPU
#define ALT_TIMESTAMP_CLK CPU
#define INTEL_FPGA_DFL_START_ADDRESS 0xffffffffffffffff
#define INTEL_FPGA_USE_DFL_WALKER 0


/*
 * intel_niosv_m_hal_driver configuration
 *
 */

#define NIOSV_INTERNAL_TIMER_TICKS_PER_SECOND 1000

#endif /* __SYSTEM_H_ */
