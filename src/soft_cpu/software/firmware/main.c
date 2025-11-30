/**
  *  @file   main.c
  *  @author not-forest <sshkliaiev@gmail.com>
  *  @brief  Main NIOS V firmware entry point. 
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

#define BUFF_SIZE 256

#include "firmware.h"
#include <altera_avalon_spi.h>

static syscmd_t current_mode = { .type = Unknown };
/* Inner state machine for handling input and output data. */
static enum {
    NonSync, Command, ReadData, ReadWeight, Write
} inner_state = NonSync;

/**
  * @brief Synchronization function.
  *
  * Master shall send synchronization array of words to restart the iteration pointer.
  **/
static uint8_t sync_compare(sysword_t sync_word) {
    static uint8_t sync_counter = 0;
    const sysword_t PATTERN[] = COPROCESSOR_SYNC_ARRAY_PATTERN;

    if (PATTERN[sync_counter++] == sync_word) {
        return sizeof(PATTERN) - sync_counter;
    } else {
        sync_counter = 0;
        return 0xFF;    // Ignored.
    }
}

/**
  * @brief Batch writing function for matrix multiplication.
  **/
static void matmul_batch_write(uint32_t iteration, sysword_t word) {
    //TODO! 
}

/**
  * @brief Parser function for batch write operations.
  **/
static inline void any_batch_write(uint32_t iteration, sysword_t word) {
    switch (current_mode.type) {
        case MatMul:
            matmul_batch_write(iteration, word);
            break;
        case Filter:
            break;
        default:
            LOG(ERROR, "Unexpected system state during batch write parser: %d", current_mode.type);
            // Restart maybe.
    }
}

void syscmd_deserialize(sysword_t *buf) { 
    current_mode.n = (buf[0] << 24) | (buf[1] << 16) | (buf[2] << 8) | buf[3];
    current_mode.m = (buf[4] << 24) | (buf[5] << 16) | (buf[6] << 8) | buf[7];
    current_mode.type = (buf[8] << 8) | buf[9];

    switch (current_mode.type) {
        case PROPER_STATE:
            break;
        default:
            LOG(ERROR, "Corrupted command frame. Resync required.");
            inner_state = NonSync;
    }
}

/* Main firmware entry point. */
int main() {
    sysword_t rx[BUFF_SIZE], tx[BUFF_SIZE] = {0};
    uint16_t txp = 0;
    uint32_t iteration = 0;
    LOG(INFO, "Entering main loop");

    for (;;) {
        /**
          * Performing full-duplex read/write. Always trying to obtain up to `BUFF_SIZE` words.
          **/
        alt_avalon_spi_command(SPI_0_BASE, 0, txp, tx, BUFF_SIZE, rx, 0);

        for (int i = 0; i < BUFF_SIZE; ++i) {
            switch (inner_state) {
                case NonSync:       /* Must synchronize with upcoming command by finding the synchronization sequence. */
                    if (sync_compare(rx[i]) == 0)
                        inner_state = Command;  // Command is expected afterward.

                    break;
                case Command:       /* Comes after synchronization sequence or previous data slice. */
                    if (i + 10 < BUFF_SIZE) {
                        inner_state = NonSync;
                        break;
                    }

                    syscmd_deserialize(&rx[i]); 
                    i += 10;
                    inner_state = ReadWeight;

                    break;
                case ReadData:      /* Shall write to batch block for both weights and data according to current function. */
                case ReadWeight:
                    any_batch_write(iteration, rx[i]);
                    break;
                case Write:         /* Pushing data back from systolic array to master. Used differently with different algorithms. */
                    LOG(DEBUG, "Nothing to write yet.");
                    break;
            }
        }
    }

    return 0;
}
