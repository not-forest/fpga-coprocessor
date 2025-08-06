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
#define BUF_SIZE 4096

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
    struct mutex lock;
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

/** 
  * @brief Obtains pointer to doubled buffer data.
  **/
double_buffer_t* unwrap_buffer_from_file(struct file *file);

/** 
  * @brief Initiates asynchronous SPI DMA transfer.
  *
  * @note Function expects data to exist within the mmap region of SPI's DMA Tx buffer.
  **/
void coproc_spi_async(struct file *file, size_t len);

#endif // !COPROCESSOR_DRIVER_H
