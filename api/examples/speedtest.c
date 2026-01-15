/**
  * @file speedtest.c
  * @author notforest <sshkliaiev@gmail.com>
  * @brief Speed test comparison based on 4x4 matrix multiplication with N iterations.
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
#include <time.h>
#include "api.h"

// Helper function to get time in microseconds
long long get_time_us() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000000LL + (ts.tv_nsec / 1000);
}

// Standard CPU implementation of 4x4 MatMul
void cpu_matmul(int16_t *A, int16_t *B, int16_t *C) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            int32_t sum = 0;
            for (int k = 0; k < 4; k++) {
                sum += A[i * 4 + k] * B[k * 4 + j];
            }
            // Saturated cast to int16
            if (sum > 32767) sum = 32767;
            if (sum < -32768) sum = -32768;
            C[i * 4 + j] = (int16_t)sum;
        }
    }
}

int main() {
    coproc_handle_t h = 0; 
    int iterations = 30;

    int16_t *tx_buf = (int16_t *)coproc_get_tx_buffer(h);
    int16_t *rx_buf = (int16_t *)coproc_get_rx_buffer(h);

    if (!tx_buf || !rx_buf) {
        fprintf(stderr, "Error: Failed to map DMA buffers.\n");
        return -1;
    }

    // Initialization 4x4 data
    int16_t matA[16], matB[16], matC_cpu[16];
    for(int i=0; i<16; i++) {
        matA[i] = i;
        matB[i] = (i % 4 == (i / 4)) ? 2 : 0;
    }

    // 1. Prepare TX buffer with Interleaving (Systolic Array Format)
    int idx = 0;
    for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 4; col++) {
            for (int k = 0; k < 4; k++) {
                tx_buf[idx++] = matA[row * 4 + k];     // A element
                tx_buf[idx++] = matB[k * 4 + col];     // B element (column access)
            }
        }
    }

    printf("%-12s | %-15s | %-15s | %-10s\n", "Iterations", "CPU (us)", "FPGA (us)", "Winner");
    printf("-----------------------------------------------------------------\n");

    for (int n = 1; n <= iterations; n++) {
        // CPU BENCHMARK
        long long start_cpu = get_time_us();
        for (int i = 0; i < n; i++) {
            cpu_matmul(matA, matB, matC_cpu);
        }
        long long end_cpu = get_time_us();
        long long cpu_total = end_cpu - start_cpu;

        // FPGA BENCHMARK
        coproc_cmd_t cmd = { .n = 4, .m = 4, .type = MatMul };
        coproc_change_cmd(h, &cmd);

        long long start_fpga = get_time_us();
        // In a real burst mode, we would trigger N iterations. 
        // Here we simulate the command + wait loop for N iterations.
        for (int i = 0; i < n; i++) {
            coproc_async_write(h);
            while (coproc_check_completion(h) == 0) {
                usleep(10);
            }
        }
        long long end_fpga = get_time_us();
        long long fpga_total = end_fpga - start_fpga;

        const char* winner = (cpu_total < fpga_total) ? "CPU" : "FPGA";
        printf("%-12d | %-15lld | %-15lld | %-10s\n", n, cpu_total, fpga_total, winner);
    }

    return 0;
}
