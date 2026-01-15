/**
  * @file mul2x2.c
  * @author notforest <sshkliaiev@gmail.com>
  * @brief Example of using coprocessor API for performing 2x2 matrix multiplication with FPGA acceleration.
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
#include <assert.h>
#include "api.h"

int main() {
    coproc_handle_t h = 0; 

    /* Obtain pointers to the mapped DMA buffers */
    int16_t *tx_buf = (int16_t *)coproc_get_tx_buffer(h);
    int16_t *rx_buf = (int16_t *)coproc_get_rx_buffer(h);

    if (!tx_buf || !rx_buf) {
        fprintf(stderr, "Error: Failed to map DMA buffers.\n");
        return -1;
    }

    /* Matrix A: [1, 2; 3, 4], Matrix B: [5, 6; 7, 8] */
    /* Assuming the hardware expects all elements of A followed by all of B */
    int16_t matrixArows[] = {1, 2, 3, 4};
    int16_t matrixBcols[] = {5, 7, 6, 8};

    /* Filling TX buffer */
    int idx = 0;
    for (int row = 0; row < 2; row++) {
        for (int col = 0; col < 2; col++) {
            for (int k = 0; k < 2; k++) {
                tx_buf[idx++] = matrixArows[row * 2 + k];
                tx_buf[idx++] = matrixBcols[col * 2 + k];
            }
        }
    }

    /* Set up command for 2x2 Matrix Multiplication */
    coproc_cmd_t cmd;
    cmd.n = 2;
    cmd.m = 2;
    cmd.type = MatMul;

    if (coproc_change_cmd(h, &cmd) < 0) {
        perror("Unable to change CMD");
        return -1;
    }
    printf("Command updated: Type={%d}, Dimensions={%dx%d}\n", 
            cmd.type, cmd.n, cmd.m);
    
    if (coproc_async_write(h) < 0) {
        perror("Async write failed");
        return -1;
    }
    printf("Started asynchronous matrix multiplication...\n");

    /* Poll for completion */
    int status;
    while ((status = coproc_check_completion(h)) == 0) {
        usleep(10);
    }

    if (status < 0) {
        fprintf(stderr, "Error: Processing failed.\n");
        return -1;
    }

    /* The result matrix C is 2x2 (4 elements) */
    printf("Resulting Matrix C:\n");
    printf("[%d  %d]\n", rx_buf[0], rx_buf[1]);
    printf("[%d  %d]\n", rx_buf[2], rx_buf[3]);

    /* Verification assertions */
    assert(rx_buf[0] == 19);
    assert(rx_buf[1] == 22);
    assert(rx_buf[2] == 43);
    assert(rx_buf[3] == 50);

    printf("Result verification successful!\n");

    return 0;
}
