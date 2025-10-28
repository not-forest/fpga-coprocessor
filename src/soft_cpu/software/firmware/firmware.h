/**
  *  @file   firmware.h
  *  @author not-forest <sshkliaiev@gmail.com>
  *  @brief  Firmware data type definitions and low level interface bindings.
  *  @license BSD 
  *
  *  BSD 2-Clause 
  *  
  *  Copyright (c) 2025, notforest.
  *  
  *  Redistribution and use in source and binary forms, with or without modification, are permitted 
  *  provided that the following conditions are met:
  *  
  *   1. Redistributions of source code must retain the above copyright notice, this list of conditions 
  *  and the following disclaimer.
  *   2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
  *  and the following disclaimer in the documentation and/or other materials provided with the distribution.
  *  
  *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
  *  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  *  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
  *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
  *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
  *  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN 
  *  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *  
  *  @test   Tested on Cyclone IV with Intel Quartus Lite 24.1
  **/

#pragma once

#ifndef FIRMWARE_NIOSV_COPROC_H
#define FIRMWARE_NIOSV_COPROC_H

#include <system.h>
#include <stdint.h>
#include <sys/alt_irq.h>
#include <sys/alt_stdio.h>
#include <sys/alt_timestamp.h>

/* Synchronization sequence with master. (TODO! Must be dynamin. Not enough security.) */
#define COPROCESSOR_SYNC_ARRAY_PATTERN {0xDE, 0xAD, 0xBE, 0xEF}

/**
  * @brief Single core critical section macro.
  **/
#define _CS(...)                                    \
    alt_irq_context _ctx = alt_irq_disable_all();   \
    __VA_ARGS__                                     \
    alt_irq_enable_all(__ctx);

// Logging definitions.
#define INFO
#define ERROR
#define DEBUG

/* Logging macro */
#define LOG(verbosity, ...) \
    alt_printf("[%lu] [%s]: %s\n", alt_timestamp(), #verbosity, __VA_ARGS__);

/**
  * @brief Word data type definition for systolic array.
  **/
typedef uint8_t sysword_t;

/**
  * @brief Systolic array mode of operation.
  **/
typedef struct {
    uint32_t n, m;
    enum {
        Sleep   = 0xAA00,
        Unknown = 0xAA01,

        MatMul  = 0xCC00, 
        Filter  = 0xCC01, 
    } type;
} syscmd_t;

#define PROPER_STATE Sleep: case Unknown: case MatMul: case Filter

/**
  * @brief Deserialize next command from upcoming bytes.
  *
  **/
void syscmd_deserialize(sysword_t *buf);

/**
  * @brief Writes data word to Avalon MM batch component slave into internal matrix by row and column. 
  *
  * Batch component only allows for write from NIOS domain.
  *
  * @param batch    data address of required batch.
  * @param row      row index in internal matrix.
  * @param col      column index in internal matrix.
  * @param word     word to write.
  **/
void write_batch_word(int batch, uint8_t row, uint8_t col, sysword_t word);

static void write_batch_weight_word(uint8_t row, uint8_t col, sysword_t word) {
    write_batch_word(WEIGHT_BATCH_BASE, row, col, word);
}

static void write_batch_data_word(uint8_t row, uint8_t col, sysword_t word) {
    write_batch_word(DATA_BATCH_BASE, row, col, word);
}

#endif // !FIRMWARE_NIOSV_COPROC_H
