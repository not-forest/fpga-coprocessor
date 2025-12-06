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

#include "firmware.h"

static syscmd_t current_mode = { .type = Unknown };

/**
  * @brief SPI Interrupt Service Routine for handling communication.
  **/
static void spi_isr(void *ctx) {
    volatile spi_context_t *spi = ctx;
    uint8_t spi_word;
    uint32_t status = IORD_ALTERA_AVALON_SPI_STATUS(SPI_0_BASE);

    // Checking for upcoming data for read.
    if (status & ALTERA_AVALON_SPI_STATUS_RRDY_MSK) {
        if (spi->rx_empty) {        // Only read when buffer is not full
            spi_word = IORD_ALTERA_AVALON_SPI_RXDATA(SPI_0_BASE);
            spi->rx_buf[spi->rx_head++] = spi_word;
            spi->rx_empty--;
        }
    }

    // Writing when new data is ready.
    if (status & ALTERA_AVALON_SPI_STATUS_TRDY_MSK) {
        if (spi->tx_full) {         // Only writing when there is new Tx data to be sent.
            spi_word = spi->tx_buf[spi->tx_tail++];
            spi->tx_full--;
            IOWR_ALTERA_AVALON_SPI_TXDATA(SPI_0_BASE, spi_word);
        }
    }

    IOWR_ALTERA_AVALON_SPI_STATUS(SPI_0_BASE, 0); // Clears interrupt.
}

/**
  * @brief Main coprocessor firmware entry point.
  **/
int main() {
    /* Inner state machine for handling input and output data. */
    static enum {
        NonSync, Command, ReadData, ReadWeight, Write
    } inner_state = NonSync;
    spi_context_t spi = {0};

    /* 
     * SPI slave interrupt service routine is registered here and expects to obtain one byte on each
     * interrupt. While obtaining new data, slave is also responsible to send some data from it's Tx
     * buffer.
     */
    /* alt_ic_isr_register(
        SPI_0_IRQ_INTERRUPT_CONTROLLER_ID, 
        SPI_0_IRQ, 
        spi_isr, 
        &spi, 
        0
    ); */

    for (;;) {
        /* spi_isr(&spi);
        _CS(                                                            // Interrupting here causes undefined behavior.
            if (spi.rx_empty > 0 && spi.tx_full < BUFF_SIZE - 1) {      // Only reading from buffer when new data appears.
                spi.tx_buf[spi.tx_head++] = spi.rx_buf[spi.rx_tail++];
                spi.rx_empty++;
                spi.tx_full++;
            }
        ); */
        usleep(1 * 100);
    }

    return 0;
}
