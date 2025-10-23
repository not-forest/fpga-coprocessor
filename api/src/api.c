/**
  * @file api.c
  * @author notforest <sshkliaiev@gmail.com>
  * @brief Coprocessor main API implementation source.
  *
  * @license
  *
  * BSD 2-Clause 
  *
  * Copyright (c) 2025, notforest.
  *
  * Redistribution and use in source and binary forms, with or without modification, are permitted 
  * provided that the following conditions are met:
  *
  *  1. Redistributions of source code must retain the above copyright notice, this list of conditions 
  * and the following disclaimer.
  *  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
  * and the following disclaimer in the documentation and/or other materials provided with the distribution.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
  * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
  * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
  * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
  * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN 
  * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  **/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <limits.h>
#include <dirent.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <errno.h>
#include <api.h>

#define DRIVER_PREFIX       "fpgacoproc"
#define DRIVER_PREFIX_LEN   ( sizeof ( DRIVER_PREFIX ) - 1 )

// Character device path helper.
static inline char *devpath(coproc_handle_t h) {
    _Thread_local static char path[64];
    if (snprintf(path, sizeof(path), "/dev/%s%d", DRIVER_PREFIX, h) >= sizeof(path)) {
        errno = ENAMETOOLONG;
        return NULL;
    }
    return path;
}

// MMAP helper.
static void *coproc_map(coproc_handle_t h, off_t off, size_t len, int prot) {
    char *path = devpath(h);
    if (!path) 
        return MAP_FAILED;

    int fd = open(path, (prot & PROT_WRITE) ? O_RDWR : O_RDONLY);
    if (fd < 0) 
        return MAP_FAILED;

    void *addr = mmap(NULL, len, prot, MAP_SHARED, fd, off);
    int e = errno;
    close(fd);
    errno = e;
    return addr;
}

int coproc_change_cmd(coproc_handle_t h, const coproc_cmd_t *cmd) {
    char *path = devpath(h);
    if (!path) return -1;

    int fd = open(path, O_WRONLY);
    if (fd < 0) return -1;

    ssize_t r = write(fd, cmd, sizeof(*cmd));
    int e = errno;
    close(fd);

    if (r < 0) { errno = e; return -1; }
    if ((size_t)r != sizeof(*cmd)) { errno = EIO; return -1; }

    return 0;
}

int coproc_async_write(coproc_handle_t h) {
    char c = 0;
    char *path = devpath(h);
    if (!path) 
        return -1;

    int fd = open(path, O_WRONLY);
    if (fd < 0) 
        return -1;

    ssize_t r = write(fd, &c, 1);
    int e = errno;
    close(fd);
    if (r < 0) 
        { errno = e; return -1; }
    return 0;
}

int coproc_check_completion(coproc_handle_t h) {
    char *path = devpath(h);
    if (!path) 
        return -1;

    int fd = open(path, O_RDONLY);
    if (fd < 0) 
        return -1;

    char c;
    ssize_t r = read(fd, &c, 1);
    int e = errno;
    close(fd);
    if (r < 0) 
        { errno = e; return -1; }
    return (r > 0 && (c == '1' || c == 1));
}

void *coproc_get_tx_buffer(coproc_handle_t h) {
    return coproc_map(h, 0, BUF_SIZE, PROT_READ | PROT_WRITE);
}

void *coproc_get_rx_buffer(coproc_handle_t h) {
    return coproc_map(h, BUF_SIZE, BUF_SIZE, PROT_READ);
}

coproc_handle_t coproc_get_max_handle(void) {
    DIR *d = opendir("/dev");
    if (!d) { errno = EIO; return -1; }
    struct dirent *e;
    int max = -1;

    while ((e = readdir(d))) {
        if (strncmp(e->d_name, DRIVER_PREFIX, DRIVER_PREFIX_LEN)) 
            continue;
        char *end;
        long v = strtol(e->d_name + DRIVER_PREFIX_LEN, &end, 10);
        if (*end == '\0' && v >= 0 && v <= INT_MAX && v > max) 
            max = (int)v;
    }
    closedir(d);
    return max;
}
