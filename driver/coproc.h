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
/******************************/

int coproc_spi_load(void);
void coproc_spi_unload(void);

#endif // !COPROCESSOR_DRIVER_H
