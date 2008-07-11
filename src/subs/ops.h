#ifndef OPS_H
#define OPS_H

#if defined __GNUC__ || defined __INTEL_COMPILER
#if !defined memset
#define memset(d,v,n) __builtin_memset(d,v,n)
#endif

#if !defined memcpy
#define memcpy(d,s,n) __builtin_memcpy(d,s,n)
#endif

#else
#define __attribute__(n)
#define inline
#endif

#undef min
#undef max


inline static int min(int a, int b)
{
    return a < b ? a : b;
}


inline static float minf(float a, float b)
{
    return a < b ? a : b;
}


inline static int max(int a, int b)
{
    return a > b ? a : b;
}


inline static float maxf(float a, float b)
{
    return a > b ? a : b;
}


inline static float sqr(float a)
{
    return a * a;
}


#endif
