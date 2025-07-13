/* 
 *  File: spi.c
 *  Desc: SPI bus initialization and control module. 
 *
 *  Tested on Raspberry Pi 4 with Linux kernel 5.10  
 * */

#include <linux/module.h>
#include <linux/spi/spi.h>
#include <linux/mutex.h>

#include "coproc.h"

#define SPI_WORD_BITS 8

/* SPI device wrapper for mutual exclusion between kernel calls. */
struct spi_net {
    struct spi_device *spi;
    struct mutex lock;
};

/* Writes word of data to the SPI bus.  */
static int coproc_send_word(struct spi_net *net, u8 *wr_buf) {
    int ret;

    mutex_lock(&net->lock);
    ret = spi_write(net->spi, wr_buf, SPI_WORD_BITS);
    mutex_unlock(&net->lock);
    return ret;
}

/* Reads word of data from the SPI bus.  */
static int coproc_read_word(struct spi_net *net, u8 *rd_buf) { 
    int ret;

    mutex_lock(&net->lock);
    ret = spi_read(net->spi, rd_buf, SPI_WORD_BITS);
    mutex_unlock(&net->lock);
    return ret;
}

/* Allocates memory for SPI device net. */
static int coproc_spi_probe(struct spi_device *spi) {
    struct spi_net *net;
    dev_info(&spi->dev, "Probing FPGA Coprocessor SPI bus...");

    net = kzalloc(sizeof(struct spi_net), GFP_KERNEL);
    if (!net)
        return -ENOMEM;

    net->spi = spi;
    mutex_init(&net->lock);

    spi_set_drvdata(spi, net);

    return 0;
}

static int coproc_spi_remove(struct spi_device *spi) {
    struct spi_net *net;
    dev_info(&spi->dev, "FPGA Coprocessor SPI bus release...");

    net = spi_get_drvdata(spi);
    kfree(net);

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