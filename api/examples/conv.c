/**
  * @file conv.c
  * @author notforest <sshkliaiev@gmail.com>
  * @brief Example of using coprocessor API for performing vector convolution with FPGA acceleration.
  *
  * @license
  *
  * BSD 2-Clause 
  *
  * Copyright (c) 2025, notforest.
  *
  * Redistribution and use in source and binary forms, with or without modification, are permitted 
  * provided that the following conditions are met:
  *
  *  1. Redistributions of source code must retain the above copyright notice, this list of conditions 
  * and the following disclaimer.
  *  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
  * and the following disclaimer in the documentation and/or other materials provided with the distribution.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
  * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
  * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
  * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
  * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN 
  * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  **/

#include <stdio.h>
#include <stdint.h>

#include <unistd.h>
#include "api.h"

#define VECTOR_LEN 1024

int main() {
    coproc_handle_t h = 0;
    int16_t *tx_buf = coproc_get_tx_buffer(h);
    int16_t *rx_buf = coproc_get_rx_buffer(h);

    // Output array for the full convolution result
    int32_t C[VECTOR_LEN];

    if (!tx_buf || !rx_buf) return -1;

    coproc_cmd_t cmd = {.n = VECTOR_LEN, .m = 1, .type = Conv};
    if (coproc_change_cmd(h, &cmd) < 0) return -1;

    printf("Command updated: Type=%d, N=%d, M=1\n", cmd.type, VECTOR_LEN);
    printf("Starting asynchronous coprocessor computation...\n");

    for (int n = 0; n < VECTOR_LEN; n++) {
        // Load interleaved data for this shift
        for (int i = 0; i < VECTOR_LEN; i++) {
            tx_buf[2 * i] = 1;      // Signal A
            tx_buf[2 * i + 1] = -2; // Signal B
        }

        if (coproc_async_write(h) < 0) return -1;

        while (coproc_check_completion(h) == 0) {
            usleep(1);
        }
        C[n] = rx_buf[0];
    }

    // Print table output
    printf("Results of vector convolution:\n");
    printf("%5s | %7s\n", "n", "C[n]");
    printf("------------------\n");

    // Display sample indices (e.g., first 3, middle, and last)
    int important_indices[] = {0, 1, 2, 512, 1023};
    for (int i = 0; i < 5; i++) {
        int idx = important_indices[i];
        printf("%5d | %7d\n", idx, C[idx]);

    }

    return 0;
}
