/* 
 *  File: pbus.c
 *  Desc: Contains initialization part for the parallel bus between the target soc and FPGA coprocessor.
 *  The parallel bus is driven via 20-pin GPIO header, using specified communication protocol.
 *
 *  Tested with Linux raspberry pi 4, kernel built with buildroot: 6.1.61-v8  
 * */

#include<linux/gpio.h>
#include<linux/module.h>

#include "coproc.h"

#define DIN 
#define DOUT 
#define CSTATUS 
#define CMD 

struct gpio_desc *d_in, *d_out, *c_status, *c_cmd; 

/* Obtains parallel bus for communication between the driver and FPGA. */
int acquire_parallel_bus(dev_t) {
    return 0;
}


void free_parallel_bus(dev_t) {

}
