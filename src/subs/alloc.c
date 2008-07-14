#include "alloc.h"

#include <stdio.h>
#include <stdlib.h>


// Wrapper for malloc/free that:
// 1) checks whether malloc succeeds; otherwise aborts
// 2) aligns data to 16 bytes (needed for FFTW).

#if (defined __GNUC__ || defined __INTEL_COMPILER) && (defined __i386 || defined __x86_64)
#define ALIGN_16
#endif


void *safe_malloc(size_t amount)
{
#if defined ALIGN_16
    amount += 16;
#endif

    char *address = malloc(amount);

    if (address == 0) {
	fprintf(stderr, "out of memory\n");
	exit(1);
    }

#if defined ALIGN_16
    int skip = ((size_t) address & 0xF) != 0 ? 8 : 16;

    address += skip;
    address[-8] = skip;	// remember what we have to subtract in safe_free()
#endif

    return address;
}


void safe_free(void *address)
{
    char *addr = address;

#if defined ALIGN_16
    addr -= addr[-8];	// compute the original address given by malloc()
#endif

    free(addr);
}


#if 0
static size_t align(size_t n)
{
#if defined ALIGN_16
    n += 15, n &= ~15;
#endif

    return n;
}


void *alloc_matrix(size_t height, size_t width, int item_size)
{
    size_t width_in_bytes = align(width * item_size);
    size_t vector_size    = align(height * sizeof(void *));
    size_t total_size	  = vector_size + height * width_in_bytes;
    void   **matrix	  = safe_malloc(total_size);
    char   *user_data	  = (char *) matrix + vector_size;

    for (size_t i = 0; i < height; i ++)
	matrix[i] = user_data + i * width_in_bytes;

    return matrix;
}
#endif
