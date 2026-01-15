/**  
  *  @file spi.c
  *  @brief SPI bus initialization and control module.
  *
  *
  *  @test Tested on Raspberry Pi 4 with Linux kernel 6.12 
  **/

#include "coproc.h"

#define SPI_WORD_BITS 8

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

    bool completion;
    int irq;

    struct mutex lock;
};

static irqreturn_t coproc_gpio_irq(int irq, void *data) {
    struct spi_net *net = data;

    if (!net->completion)
        net->completion = true;

    return IRQ_HANDLED;
}

/** 
  * @brief Checks SPI transfer completion.
  *
  * @return true if coprocessor command is fully completed. False otherwise.
  **/
bool coproc_spi_check_completion(struct file *file, size_t len) {
    struct spi_net *net = file->private_data;
    bool ret = false;
    mutex_lock(&net->lock);

    ret = net->completion;
    if (ret)
        net->completion = false;

    mutex_unlock(&net->lock);
    return ret;
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

    net->completion = false;
    net->spi = spi;
    mutex_init(&net->lock);

    spi_set_drvdata(spi, net);

    net->irq = spi->irq;
    if (net->irq <= 0) {
        dev_err(&spi->dev, "No IRQ provided from device tree\n");
        return -EINVAL;
    }

    if (devm_request_irq(&spi->dev,
                net->irq,
                coproc_gpio_irq,
                IRQF_TRIGGER_RISING,
                "coproc-gpio-irq",
                net)) {
        dev_err(&spi->dev, "Failed to request IRQ\n");
        return -EBUSY;
    }

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
    mutex_init(&buf->lock);

    cdev_init(&net->cdev, &fops);

    /* Initializing the character driver.  */
    if(cdev_add(&net->cdev, dev, 1) < 0) {
        pr_err("%s: ERROR: Unable to add the character device for coprocessor unit.\n", THIS_MODULE->name);
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
static void coproc_spi_remove(struct spi_device *spi) {
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

    cdev_del(&net->cdev);
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

/** 
  * @brief Binds opened file from the user-space to SPI.
  **/
void bind_to_spi(struct inode *inode, struct file *file) {
    // Assuming that this function will never be called before SPI submodule initializes.
    file->private_data = container_of(inode->i_cdev, struct spi_net, cdev);
} 

/** 
  * @brief Obtains pointer to doubled buffer data.
  **/
double_buffer_t* unwrap_buffer_from_file(struct file *file) {
    struct spi_net *net = file->private_data;
    return &net->dbuff;
}

/** 
  * @brief Initiates asynchronous SPI DMA transfer.
  *
  * @note Function expects data to exist within the mmap region of SPI's DMA Tx buffer.
  **/
void coproc_spi_async(struct file *file, size_t len) {
    struct spi_message m;
    struct spi_net *net = file->private_data;
    double_buffer_t *buf = &net->dbuff;

    mutex_lock(&buf->lock);
    int idx = buf->buf_select;

    struct spi_transfer t = {
        .tx_buf = buf->tx_buf[idx],
        .rx_buf = buf->rx_buf[idx],
        .len = len,
        .tx_dma = buf->tx_dma[idx],
        .rx_dma = buf->rx_dma[idx],
        .cs_change = 0,
        .speed_hz = net->spi->max_speed_hz,
        .bits_per_word = SPI_WORD_BITS,
    };

    buf->buf_select ^= 1;
    mutex_unlock(&buf->lock);

    spi_message_init(&m);
    spi_message_add_tail(&t, &m);

    spi_async(net->spi, &m);
}


/** 
  * @brief Sends command data before proceding to the next asynchronous write.
  *
  * @note The behavior of CMD write is blocking.
  **/
ssize_t coproc_spi_cmd(struct file *file,
                       const char __user *ubuf,
                       size_t len) {
    struct spi_net *net = file->private_data;
    u8 *kbuf;
    int ret;

    kbuf = memdup_user(ubuf, len);
    if (IS_ERR(kbuf))
        return PTR_ERR(kbuf);

    mutex_lock(&net->lock);
    ret = spi_write(net->spi, kbuf, len);
    mutex_unlock(&net->lock);

    kfree(kbuf);

    if (ret)
        return ret;

    return len;
}

int coproc_spi_load(void) {
    return spi_register_driver(&coproc_spi_driver);
}

void coproc_spi_unload(void) {
    spi_unregister_driver(&coproc_spi_driver);
}
