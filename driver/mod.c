/** 
  *  @file mod.c
  *  @brief Main driver initialization module. Defines all function related to driver's load, unload states and error handling.
  *
  *  @test Tested on Raspberry Pi 4 with Linux kernel 5.10  
  **/

#include "coproc.h"

#define CLASS_NAME  "coproc"

dev_t dev = 0;

/** 
  * @brief Character device open. 
  *
  * Binds file's private data pointer to SPI net structure.
  **/
static int fc_open(struct inode *inode, struct file *file) {
    bind_to_spi(inode, file);

    pr_debug("%s: Coprocessor file opened.\n", THIS_MODULE->name);
    return 0;
}

/** 
  * @brief Character device close. 
  **/
static int fc_release(struct inode *inode, struct file *file) {
    pr_debug("%s: Coprocessor file closed.\n", THIS_MODULE->name);
    return 0;
}

/** 
  * @brief Character device read. 
  *
  * @note Used to provide information about the competion of asynchronous writes.
  * Both read and write do not use user buffers in any way.
  **/
static ssize_t fc_read(struct file *file, char __user *buf, size_t size, loff_t *off) {
    return 0;
}

/** 
  * @brief Character device write. 
  *
  * @note Used to start asynchronous writes from the mmap DMA buffer to SPI.
  * Both read and write do not use user buffers in any way.
  **/
static ssize_t fc_write(struct file *file, const char *buf, size_t len, loff_t *off) {
    coproc_spi_async(file, len); 
    return len;
}

/** 
  * @brief Character device IOCTL. 
  **/
static long fc_ioctl(struct file *file, unsigned int cmd, unsigned long arg) {
    return 0;
}

/** 
  * @brief Memorry map handler for userspace API. 
  *
  * Driver shares it's DMA kernel buffers with userspace to provide zero-cost DMA operations
  * from the userspace and reduce copying time.
  *
  * @note Tx buffer is mapped with offset of 0. Rx buffer always comes just afterwads, which means it
  * shall have an offset of BUF_SIZE. Buffer swaps are seamless to the user.
  **/
static int coproc_mmap(struct file *file, struct vm_area_struct *vma) {
    dma_addr_t dma_handle;
    void *kbuf;
    double_buffer_t *dbuf = unwrap_buffer_from_file(file);
    size_t size = vma->vm_end - vma->vm_start, offset = vma->vm_pgoff << PAGE_SHIFT;
    mutex_lock(&dbuf->lock);
    int idx = dbuf->buf_select;

    switch (offset) {
        case 0:
            dma_handle = dbuf->tx_dma[idx]; 
            break;
        case BUF_SIZE:
            dma_handle = dbuf->rx_dma[idx]; 
            break;
        default:
            mutex_unlock(&dbuf->lock);
            return -EINVAL;
    }
    
    mutex_unlock(&dbuf->lock);

    if (remap_pfn_range(vma,
        vma->vm_start,
        dma_handle >> PAGE_SHIFT,
        size,
        vma->vm_page_prot
    )) {
        return -EAGAIN;
    }

    return 0;
}

/** 
  * @brief FPGA coprocessor device file operations. 
  **/
struct file_operations fops = {
    .owner          = THIS_MODULE,
    .read           = fc_read,
    .write          = fc_write,
    .open           = fc_open,
    .release        = fc_release,
    .unlocked_ioctl = fc_ioctl,
};

/** 
  * @brief FPGA coprocessor initialization. 
  **/
static int __init __driver_init(void) {
    int ret;
    pr_debug("%s: Entering the loader function.\n", THIS_MODULE->name);

    /* Initializing a character device region. */
    if((ret = alloc_chrdev_region(&dev, 0, 1, "fpga-coproc")) < 0) {
        pr_err("%s: ERROR: Unable to allocate major number, aborting...\n", THIS_MODULE->name);
        goto _unreg;
    }

    /* 
     * Trying to initialize SPI submodule for comminicating with coprocessor. 
     * This function will block until a proper initialization routine is done.
     */
    if((ret = coproc_spi_load()) < 0) {
        pr_err("%s: ERROR: Unable to load SPI submodule.\n", THIS_MODULE->name);
        goto _spi;
    }

    /* FPGA Coprocessor class definition. */
    if(IS_ERR(dev_class = class_create(THIS_MODULE, CLASS_NAME))) {
        pr_err("%s: ERROR: Unable to create the structure class.\n", THIS_MODULE->name);
        ret = PTR_ERR(dev_class);
        goto _class;
    }
    
    /* Creating the device itself. */
    if(IS_ERR(fc_dev = device_create(dev_class, NULL, dev, NULL, "fpga-coproc%d", MINOR(dev)))) {
        pr_err("%s: ERROR: Unable to create the device.\n", THIS_MODULE->name);
        ret = PTR_ERR(fc_dev);
        goto _dev;
    }

    pr_debug("%s: Driver loaded successfully.\n", THIS_MODULE->name);
    return 0;

_dev:
    device_destroy(dev_class, dev);
_class:
    class_destroy(dev_class);
_spi:
    coproc_spi_unload();
_unreg:
    unregister_chrdev_region(dev, 1);

    return ret;
}

/** 
  * @brief FPGA coprocessor release function.
  *
  * Frees all internal resources and puts the coprocessor to deep sleep mode.  
  **/
static void __exit __driver_exit(void) {
    pr_debug("%s: Unloading FPGA Coprocessor driver.\n", THIS_MODULE->name);

    device_destroy(dev_class, dev);
    class_destroy(dev_class);
    coproc_spi_unload();
    unregister_chrdev_region(dev, 1);

    pr_debug("%s: Driver was unloaded successfully.\n", THIS_MODULE->name);
}

module_init(__driver_init);
module_exit(__driver_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("notforest <sshkliaiev@gmail.com>");
MODULE_DESCRIPTION("Driver for communicating with FPGA coprocessor unit.");
MODULE_VERSION("0.1.0");
