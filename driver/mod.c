/* 
 *  File: mod.c
 *  Desc: Main driver initialization module. Defines all function related to driver's load, unload states and error handling.
 *
 *  Tested on Raspberry Pi 4 with Linux kernel 5.10  
 * */

#include<linux/kernel.h>
#include<linux/module.h>
#include<linux/device/class.h>

#include "coproc.h"

#define DEV_NAME    "fpga-coproc"
#define CLASS_NAME  "coproc"

dev_t dev = 0;

/* Device file operations. */
static struct file_operations fops = {
    .owner          = THIS_MODULE,
    .read           = fc_read,
    .write          = fc_write,
    .open           = fc_open,
    .release        = fc_release,
    .unlocked_ioctl = fc_ioctl,
};

/* Character device open. */
static int rc_open(struct inode *inode, struct file *file) {
    pr_debug("%s: Coprocessor file opened.\n", THIS_MODULE->name);
    return 0;
}

/* Character device closed. */
static long rc_release(struct inode *inode, struct file *file) {
    pr_debug("%s: Coprocessor file closed.\n", THIS_MODULE->name);
    return 0;
}

/* Initializes the driver while confirming that a proper connection between the Raspberry Pi and FPGA is made. */
static int __init __driver_init(void) {
    int ret;
    pr_debug("%s: Entering the loader function.\n", THIS_MODULE->name);

    /* Tries to acquire the 20-pin GPIO header to initialize it as a parallel bus. */
    if(ret = acquire_parallel_bus(dev) < 0) {
        pr_err("%s: ERROR: while acquiring communication parallel bus: %d\n", THIS_MODULE->name, ret);
        goto _free_pbus;
    }

    /* Initializing a character device region. */
    if(ret = alloc_chrdev_region(&dev, 0, 1, DEV_NAME) < 0) {
        pr_err("%s: ERROR: Unable to allocate major number, aborting...\n", THIS_MODULE->name);
        goto _unreg;
    }

    /* Initializing the character driver.  */
    if(ret = cdev_add(&fc_cdev, dev, 1) < 0) {
        pr_err("%s: ERROR: Unable to add the character device for raspberry pi fan.\n", THIS_MODULE->name);
        goto _cdev;
    }

    /* FPGA Coprocessor class definition. */
    if(IS_ERR(dev_class = class_create(THIS_MODULE, CLASS_NAME))) {
        pr_err("%s: ERROR: Unable to create the structure class.\n", THIS_MODULE->name);
        ret = PTR_ERR(dev_class);
        goto _class;
    }
    
    /* Creating the device itself. */
    if(IS_ERR(fc_dev = device_create(dev_class, NULL, dev, NULL, DEV_NAME))) {
        pr_err("%s: ERROR: Unable to create the device.\n", THIS_MODULE->name);
        ret = PTR_ERR(fc_dev);
        goto _dev;
    }

    pr_debug("%s: Driver loaded successfully.\n", THIS_MODULE->name);
    return 0;

_dev:
    device_destroy(dev_class, dev);
_class:
    class_destroy(dev_class);
_cdev:
    cdev_del(&fc_cdev);
_unreg:
    unregister_chrdev_region(dev, 1);
_free_pbus:
    free_parallel_bus(dev);

    return ret;
}

/* Clears driver's resources, while also putting the FPGA coprocessor in sleep mode. */
static void __exit __driver_exit(void) {
    pr_debug("%s: Unloading FPGA Coprocessor driver.\n", THIS_MODULE->name);

    device_destroy(dev_class, dev);
    class_destroy(dev_class);
    cdev_del(&fc_cdev);
    unregister_chrdev_region(dev, 1);
    free_parallel_bus(dev);

    pr_debug("%s: Driver was unloaded successfully.\n", THIS_MODULE->name);
}

module_init(__driver_init);
module_exit(__driver_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("notforest <sshkliaiev@gmail.com>");
MODULE_DESCRIPTION("Driver for communicating with FPGA coprocessor unit.");
MODULE_VERSION("0.1.0");
