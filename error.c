#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "error.h"

void malloc_chk(void* ret, const char* func, const char* file, int line) {
    if (ret != NULL)
        return;
    fprintf(
        stderr,
        "[%s::ERROR]\033[1;31m Failed to allocate memory : "
        "%s.\033[0m\n[%s::DEBUG]\033[1;35m Error occured at %s:%d.\033[0m\n\n",
        __func__, strerror(errno), __func__, __FILE__, __LINE__);
    exit(EXIT_FAILURE);
}

void null_chk(void* ret, const char* func, const char* file, int line) {
    if (ret != NULL)
        return;
    fprintf(stderr,
            "[%s::ERROR]\033[1;31m %s.\033[0m\n[%s::DEBUG]\033[1;35m Error "
            "occured at %s:%d.\033[0m\n\n",
            __func__, strerror(errno), __func__, __FILE__, __LINE__);
    exit(EXIT_FAILURE);
}

void neg_chk(void* ret, const char* func, const char* file, int line) {
    if (ret >= 0)
        return;
    fprintf(stderr,
            "[%s::ERROR]\033[1;31m %s.\033[0m\n[%s::DEBUG]\033[1;35m Error "
            "occured at %s:%d.\033[0m\n\n",
            __func__, strerror(errno), __func__, __FILE__, __LINE__);
    exit(EXIT_FAILURE);
}