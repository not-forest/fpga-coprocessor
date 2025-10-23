/**
  * @file api.h
  * @author notforest <sshkliaiev@gmail.com>
  * @brief Coprocessor API main header.
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

#ifndef COPROC_API_H
#define COPROC_API_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/* Identical to definition in device driver implementation. */
#define BUF_SIZE 4096

/**
  * @brief Selected coprocessor handle.
  *
  * For systems with multiple coprocessors, this ID corresponds to the minor value
  * allocated by the kernel driver for each character device (e.g. /dev/fpga_coprocX).
  * For systems with only one coprocessor, this value is always equal to 0.
  **/
typedef int16_t coproc_handle_t;

/**
  * @brief Coprocessor command type.
  *
  * Defines the kind of operation mode for coprocessor to swap into and dimensions of
  * upcoming data types.
  **/
__attribute__((packed))
typedef struct {
    uint32_t n, m;
    enum {
        MatMul, Filter, Sleep
    } type;
} coproc_cmd_t;

/**
  * @brief Obtain pointer to the memory-mapped transmit (TX) DMA buffer.
  *
  * The returned pointer can be used to fill data that will be transferred
  * asynchronously to the coprocessor. The buffer is allocated and mapped
  * by the kernel driver.
  *
  * @param h Coprocessor handle.
  * @return Pointer to TX buffer on success, or NULL on failure.
  **/
void *coproc_get_tx_buffer(coproc_handle_t h);

/**
  * @brief Obtain pointer to the memory-mapped receive (RX) DMA buffer.
  *
  * The returned pointer can be used to read results produced by the coprocessor
  * after a completed computation. The buffer is owned by the driver.
  *
  * @param h Coprocessor handle.
  * @return Pointer to RX buffer on success, or NULL on failure.
  **/
void *coproc_get_rx_buffer(coproc_handle_t h);

/**
  * @brief Start asynchronous write operation to the coprocessor.
  *
  * Initiates a DMA transfer from the TX buffer to the coprocessor.
  * This function returns immediately; completion can be checked with
  * coproc_check_completion().
  *
  * @param h Coprocessor handle.
  * @return 0 on success, negative error code on failure.
  **/
int coproc_async_write(coproc_handle_t h);

/**
  * @brief Check whether the coprocessor operation has completed.
  *
  * This function polls the DMA or driver status and returns immediately.
  * For blocking wait semantics, a separate coproc_wait_for_completion()
  * function can be implemented.
  *
  * @param h Coprocessor handle.
  * @return 1 if transfer completed, 0 if still in progress, negative value on error.
  **/
int coproc_check_completion(coproc_handle_t h);

/**
  * @brief Get the highest available coprocessor handle.
  *
  * This function queries the system to determine the number of available
  * coprocessor devices. Handles can be safely used in the range 0 .. coproc_get_max_handle().
  *
  * @return Highest valid coprocessor handle (minor number), or negative value on error.
  * @note This function will always return 0 on systems with only one coprocessor available.
  * @note The total number of coprocessors is equal to coproc_get_max_handle() + 1.
  **/
coproc_handle_t coproc_get_max_handle(void);

#ifdef __cplusplus
}
#endif

#endif // COPROC_API_H

