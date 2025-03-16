/* 
 * File: coproc.h
 * Desc: Defines all functions used within this module space. In general driver is based on using DMA for MHz-level
 * GPIO bit-banging.
 *
 *  Tested on Raspberry Pi 4 with Linux kernel 5.10  
 * */

#pragma once

#ifndef COPROCESSOR_DRIVER_H
#define COPROCESSOR_DRIVER_H

#include<linux/module.h>
#include<linux/kernel.h>
#include<linux/cdev.h>

#define PLATFORM_DRIVER_COMPAT "coproc"

/* Driver initialization data */
static struct class *dev_class;
static struct device *fc_dev;
static struct cdev fc_cdev;

// Holds all configuration data related to the current state of the coprocessor.
static struct {

} CoprocessorConfig;
/******************************/

static int __init __driver_init(void);
static void __exit __driver_exit(void);

static int fc_open(struct inode *inode, struct file *file);
static int fc_release(struct inode *inode, struct file *file);
static ssize_t fc_read(struct file *file, char __user *buf, size_t len, loff_t *off);
static ssize_t fc_write(struct file *file, const char *buf, size_t len, loff_t *off);
static long fc_ioctl(struct file *file, unsigned int cmd, unsigned long arg);

/* Obtains parallel bus for communication between the driver and FPGA. */
int acquire_parallel_bus(dev_t);
void free_parallel_bus(dev_t);

#endif // !COPROCESSOR_DRIVER_H
