/* 
 *  File: mod.c
 *  Desc: Main driver initialization module. Defines all function related to driver's load, unload states and error handling.
 *
 *  Tested with Linux raspberry pi 4, kernel built with buildroot: 6.1.61-v8  
 * */

#include<linux/kernel.h>
#include<linux/module.h>
#include<linux/device.h>

dev_t dev = 0;

/* Initializes the driver while confirming that a proper connection between the Raspberry Pi and FPGA is made. */
static int __init driver_init(void) {
    pr_debug("%s: Entering the loader function.", THIS_MODULE->name);



    pr_debug("%s: Driver loaded successfully.", THIS_MODULE->name);
    return 0;


}

/* Clears driver's resources, while also putting the FPGA coprocessor in sleep mode. */
static void __exit driver_exit(void) {
    pr_debug("%s: Unloading FPGA Coprocessor driver.", THIS_MODULE->name);



    pr_debug("%s: Driver was unloaded successfully.", THIS_MODULE->name);
}

MODULE_LICENSE("GPL");
MODULE_AUTHOR("notforest <sshkliaiev@gmail.com>");
MODULE_DESCRIPTION("Driver for communicating with FPGA coprocessor unit.");
MODULE_VERSION("0.1.0");
