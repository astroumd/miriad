#ifndef SAFE_ALLOC
#define SAFE_ALLOC

#include <stdlib.h>

void *safe_malloc(size_t);
void safe_free(void *);

#endif
