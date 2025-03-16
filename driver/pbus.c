/* 
 *  File: pbus.c
 *  Desc: Contains initialization part for the parallel bus between the target soc and FPGA coprocessor.
 *  The parallel bus is driven via 20-pin GPIO header, using custom communication protocol.
 *
 *  Tested on Raspberry Pi 4 with Linux kernel 5.10  
 * */

#include<linux/module.h>
#include<linux/mod_devicetable.h>
#include<linux/property.h>
#include<linux/of_device.h>

#include<linux/gpio/machine.h>
#include<linux/gpio/driver.h>
#include<linux/gpio/consumer.h>

#include "coproc.h"

#define PLATFORM_DRIVER_NAME "coproc-pbus"
#define PLATFORM_DRIVER_PBUS_COMPAT "fpga-coproc-pbus"

#define DIN "DIN" 
#define DOUT "DOUT" 
#define CSTATUS "CSTATUS"
#define CMD "CMD" 

/* Lookup table of GPIO used for parallel bus communication. */
struct gpiod_lookup_table gpios_table = {
    .dev_id = "parallel_bus.0",
    .table = {
        GPIO_LOOKUP_IDX("gpio.0", D_IN0, DIN, 0, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_IN1, DIN, 1, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_IN2, DIN, 2, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_IN3, DIN, 3, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_IN4, DIN, 4, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_IN5, DIN, 5, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_IN6, DIN, 6, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_IN7, DIN, 7, GPIO_ACTIVE_HIGH),

        GPIO_LOOKUP_IDX("gpio.0", D_OUT0, DOUT, 0, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_OUT1, DOUT, 1, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_OUT2, DOUT, 2, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_OUT3, DOUT, 3, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_OUT4, DOUT, 4, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_OUT5, DOUT, 5, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_OUT6, DOUT, 6, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", D_OUT7, DOUT, 7, GPIO_ACTIVE_HIGH),

        GPIO_LOOKUP_IDX("gpio.0", C_STATUS0, CSTATUS, 0, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", C_STATUS1, CSTATUS, 1, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", C_STATUS2, CSTATUS, 2, GPIO_ACTIVE_HIGH),

        GPIO_LOOKUP("gpio.0", C_CMD, CMD, GPIO_ACTIVE_HIGH),

        { /* Sentinel */ },
    },
};

struct gpio_desc *d_in[8], *d_out[8], *c_status[8], *c_cmd; 

static int pbus_probe(struct platform_device *pdev);
static int pbus_remove(struct platform_device *pdev);

/* Device tree match table for the parallel bus. */
static struct of_device_id pbus_gpios_ids[] = {
    {
        .compatible = PLATFORM_DRIVER_PBUS_COMPAT,
    }, 
    { /* Sentinel */ }
};

/* Parallel bus platform driver probes 20 GPIO pins for future use. */
static struct platform_driver pbus_platform_driver = {
    .probe = pbus_probe,
    .remove = pbus_remove,
    .driver = {
        .name = PLATFORM_DRIVER_NAME,
        .owner = THIS_MODULE,
        .of_match_table = pbus_gpios_ids,
    },
};

/* Obtains parallel bus for communication between the driver and FPGA. */
int acquire_parallel_bus(dev_t) {
    if (platform_driver_register(&pbus_platform_driver)) {
        pr_err("%s: Unable to register platform driver for the parallel bus communication protocol.", THIS_MODULE->name);
        return -EPROBE_DEFER;
    } 

    return 0;
}

/* Frees the bus. */
void free_parallel_bus(dev_t) {
    platform_driver_unregister(&pbus_platform_driver);
}

static int pbus_probe(struct platform_device *pdev) {
    uint8_t i, ret; struct gpio_desc *gd;
    struct device *dev = &pdev->dev;

    pr_info("%s: Probing GPIOs for parallel bus communication...", PLATFORM_DRIVER_NAME);

    if(!device_property_present(dev, "label")) { // This prevents segfault.
        pr_err("%s: No device label present.", PLATFORM_DRIVER_NAME);
        return -ENODEV;
    }

    if(device_property_match_string(dev, "label", PLATFORM_DRIVER_PBUS_COMPAT) < 0) {
        pr_err("%s: Device label does not match.", PLATFORM_DRIVER_NAME);
        return -ENODEV;
    }

    // Obtaining the GPIO descriptors. 
    for (i = 0; i < 8; ++i) {
        if(IS_ERR(d_in[i] = gd = gpiod_get_index(dev, DIN, i, GPIOD_IN)))
            goto _gpiod_fail;
        pr_debug("%s: Acquired GPIO%d as DIN%d", PLATFORM_DRIVER_NAME, desc_to_gpio(gd), i);
    }
    for (i = 0; i < 3; ++i) {
        if(IS_ERR(c_status[i] = gd = gpiod_get_index(dev, CSTATUS, i, GPIOD_IN)))
            goto _gpiod_fail;
        pr_debug("%s: Acquired GPIO%d as CSTATUS%d", PLATFORM_DRIVER_NAME, desc_to_gpio(gd), i);
    }

    // Output pins are set HIGH to provide the init command to FPGA.
    for (i = 0; i < 8; ++i) {
        if(IS_ERR(d_out[i] = gd = gpiod_get_index(dev, DOUT, i, GPIOD_OUT_HIGH)))
            goto _gpiod_fail;
        pr_debug("%s: Acquired GPIO%d as DOUT%d", PLATFORM_DRIVER_NAME, desc_to_gpio(gd), i);
    }

    if(IS_ERR(c_cmd = gd = gpiod_get_index(dev, CMD, i, GPIOD_OUT_HIGH)))
        goto _gpiod_fail;
    pr_debug("%s: Acquired GPIO%d as CMD%d", PLATFORM_DRIVER_NAME, desc_to_gpio(gd), i);
    c_cmd = gpiod_get(dev, CMD, GPIOD_OUT_HIGH);

    return 0;

_gpiod_fail:
    pr_err("%s: Unable to acquire GPIO descriptor. Error %d", PLATFORM_DRIVER_NAME, PTR_ERR(gd));
    return gd;
}
