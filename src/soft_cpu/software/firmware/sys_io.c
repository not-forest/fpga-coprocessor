/**
  *  @file   sys_io.c
  *  @author not-forest <sshkliaiev@gmail.com>
  *  @brief  I/O implementation for communicating with internal systolic array component. 
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
#include "system.h"
#include <io.h>

#define BBAS 6
#define HBBAS (BBAS / 2)

void write_batch_word(int batch, uint8_t row, uint8_t col, sysword_t word) {
    // Writing word into internal matrix to prepare each batch for systolic array.
    IOWR_8DIRECT(batch, (row << HBBAS) | col, word);
}

void write_serializer(uint32_t iterations) {
    // Current Avalon-MM component is not addressable.
    IOWR_32DIRECT(SERIALIZER_0_BASE, 0xdeadbeef, iterations);
}

void read_serializer(sysword_t *buf, uint32_t iteration) {
    // Current Avalon-MM component is not addressable. A new word will always be presented after each read.
    uint32_t acc = IORD_32DIRECT(SERIALIZER_0_BASE, 0xdeadbeef);
}
