/**
  *  @file   main.c
  *  @author not-forest <sshkliaiev@gmail.com>
  *  @brief  Main NIOS V firmware entry point.
  *  
  *  @test   Tested on Cyclone IV with Intel Quartus Lite 24.1
  **/

#include <sys/alt_stdio.h>

int main() {
    alt_putchar("Hello world NIOS V!");

    for (;;);

    return 0;
}
