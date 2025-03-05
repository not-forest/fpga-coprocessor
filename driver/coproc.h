/* 
 * File: coproc.h
 * Desc: Defines all functions used within this module space. In general driver is based on using DMA for MHz-level
 * GPIO bit-banging. FPGA is waken up from the 
 * */

#pragma once

#ifndef COPROCESSOR_DRIVER_H
#define COPROCESSOR_DRIVER_H

#include<linux/module.h>
#include<linux/kernel.h>
#include<linux/cdev.h>

/* Driver initialization data */
static struct class *dev_class;
static struct cdev fc_cdev;

// Holds all configuration data related to the current state of the coprocessor.
static struct {

} CoprocessorConfig = { 0 };
/******************************/

static int __init driver_init(void);
static void __exit driver_exit(void);


#endif // !COPROCESSOR_DRIVER_H
