/**  
  *  @file spi.c
  *  @brief SPI bus initialization and control module.
  *
  *  Double-buffering allows user to keep writing/reading data to Rx/Tx buffers, while 
  *
  *  @test Tested on Raspberry Pi 4 with Linux kernel 5.10  
  **/

#include "coproc.h"

#define SPI_WORD_BITS 8
#define BUF_SIZE 4096

extern struct file_operations fops;
extern dev_t dev;

/**
  * @brief SPI device wrapper for mutual exclusion between kernel calls.
  * 
  * Two buffers are being allocated during the initialization phase for both Tx and Rx.
  **/
struct spi_net {
    struct spi_device *spi;
    struct cdev cdev;
    double_buffer_t dbuff;

    struct mutex lock;
};

/** 
  * @brief Binds opened file from the user-space to SPI.
  **/
void bind_to_spi(struct inode *inode, struct file *file) {
    struct spi_net *net = container_of(inode->i_cdev, struct spi_net, cdev);
    file->private_data = net;   // Assuming that this function will never be called before SPI submodule initializes.
} 

/** 
  * @brief SPI bus probe function.
  *
  * Allocates kernel memory for SPI net structure and DMA buffers. For each SPI instance, 
  **/
static int coproc_spi_probe(struct spi_device *spi) {
    struct spi_net *net;
    double_buffer_t *buf;
    int i;
    dev_info(&spi->dev, "Probing FPGA Coprocessor SPI bus...\n");
    
    net = devm_kzalloc(&spi->dev, sizeof(struct spi_net), GFP_KERNEL);
    if (!net) {
        dev_err(&spi->dev, "Failed to allocate SPI net structure.\n");
        return -ENOMEM;
    }
    buf = &net->dbuff;

    net->spi = spi;
    mutex_init(&net->lock);

    spi_set_drvdata(spi, net);

    // Allocating doubled DMA Rx/Tx buffers.
    for (i = 0; i < 2; ++i) {
        buf->tx_buf[i] = dma_alloc_coherent(&spi->dev, BUF_SIZE, &buf->tx_dma[i], GFP_KERNEL);
        buf->rx_buf[i] = dma_alloc_coherent(&spi->dev, BUF_SIZE, &buf->rx_dma[i], GFP_KERNEL);

        if (!buf->tx_buf[i] || !buf->rx_buf[i]) {
            dev_err(&spi->dev, "Failed to allocate DMA buffers\n");
            return -ENOMEM;
        }
    }

    buf->buf_select = 0;

    cdev_init(&net->cdev, &fops);

    /* Initializing the character driver.  */
    if(cdev_add(&net->cdev, dev, 1) < 0) {
        pr_err("%s: ERROR: Unable to add the character device for raspberry pi fan.\n", THIS_MODULE->name);
        cdev_del(&net->cdev);
    }

    dev_info(&spi->dev, "SPI bus initialized and ready to be used.\n");

    return 0;
}

/** 
  * @brief SPI bus remove function.
  *
  * Frees SPI net structure and DMA buffers.
  **/
static int coproc_spi_remove(struct spi_device *spi) {
    struct spi_net *net;
    double_buffer_t *buf;
    int i;
    dev_info(&spi->dev, "FPGA Coprocessor SPI bus release...\n");

    net = spi_get_drvdata(spi);
    buf = &net->dbuff;
    
    for (i = 0; i < 2; ++i) {
        if (buf->tx_buf[i])
        dma_free_coherent(&spi->dev, BUF_SIZE, buf->tx_buf[i], buf->tx_dma[i]);
        if (buf->rx_buf[i])
            dma_free_coherent(&spi->dev, BUF_SIZE, buf->rx_buf[i], buf->rx_dma[i]);
    }

    return 0;
}

static const struct of_device_id coproc_spi_dt_ids[] = {
    { .compatible = "brightlight,coproc-spi" },
    { /* Sentinel */ }
};

static struct spi_driver coproc_spi_driver = {
    .driver = {
        .name = "coproc-spi",
        .of_match_table = coproc_spi_dt_ids,
    },
    .probe = coproc_spi_probe,
    .remove = coproc_spi_remove,
};

int coproc_spi_load(void) {
    return spi_register_driver(&coproc_spi_driver);
}

void coproc_spi_unload(void) {
    spi_unregister_driver(&coproc_spi_driver);
}