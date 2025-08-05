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
#include<linux/device/class.h>
#include<linux/device.h>
#include <linux/cdev.h>

#include <linux/spi/spi.h>
#include <linux/dma-mapping.h>
#include <linux/mutex.h>

#define PLATFORM_DRIVER_COMPAT "coproc"

/* Driver initialization data */
static struct class *dev_class;
static struct device *fc_dev;
/******************************/

/** 
  * @brief Shared doubled DMA Tx/Rx buffer structure. 
  **/
typedef struct {
    u8 *tx_buf[2], *rx_buf[2];
    dma_addr_t tx_dma[2], rx_dma[2];
    uint8_t buf_select;
} double_buffer_t;

/** 
  * @brief Loads SPI driver submodule.
  **/
int coproc_spi_load(void);
/** 
  * @brief Unloads SPI driver submodule.
  **/
void coproc_spi_unload(void);

/** 
  * @brief Binds opened file from the user-space to SPI.
  **/
void bind_to_spi(struct inode *inode, struct file *file); 

#endif // !COPROCESSOR_DRIVER_H
