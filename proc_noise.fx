// from https://en.wikipedia.org/wiki/Simplex_noise

#ifndef PROC_NOISE_FX
#define PROC_NOISE_FX

#define PROC_NOISE_PERLIN(v, noise_factor1, noise_factor2, noise_factor3)   \
x = dot(float2(noise_factor1, noise_factor2));                              \
y = dot(float2(noise_factor2, noise_factor3));                              \
gradient=float2(x,y);                                                       \
gradient=sin(gradient);                                                     \
gradient*=143758;                                                           \
gradient*=
    #endif