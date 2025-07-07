/* 
 *  File: spi.c
 *  Desc: SPI bus initialization module. 
 *
 *  Tested on Raspberry Pi 4 with Linux kernel 5.10  
 * */

#include <linux/module.h>
#include <linux/spi/spi.h>

#include "coproc.h"

static int coproc_spi_probe(struct spi_device *spi) {
    return 0;
}

static int coproc_spi_remove(struct spi_device *spi) {
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
    .probe = coproc_spi_prob,
    .remove = coproc_spi_remove,
};

int coproc_spi_load(void) {
    return spi_register_driver(&coproc_spi_driver);
}

void coproc_spi_unload(void) {
    spi_unregister_driver(&coproc_spi_driver);
}