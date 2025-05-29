# Aacgm

[![Build Status](https://github.com/Beforerr/Aacgm.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Beforerr/Aacgm.jl/actions/workflows/CI.yml?query=branch%3Amain)

A pure Julia implementation of the Altitude-Adjusted Corrected Geomagnetic (AACGM) coordinate system. Fast and accurate.

A Julia wrapper `LibAacgm` for the AACGM-v2 C library is also available in the [`LibAacgm`](./LibAacgm) directory, mainly used for testing and benchmarking.


```julia
using Aacgm
using Dates
# Convert geocentric to AACGM

dt = DateTime(2029, 3, 22, 3, 11)
glat, glon, height = 45.5, -23.5, 1000
mlat, mlon, r = geoc2aacgm(glat, glon, height, dt)

# Convert geodetic to AACGM
mlat, mlon, r = geod2aacgm(glat, glon, height, dt)
```

It is worth noting that setting the date time prior to performing the coordinate transformation can yield a slight improvement in performance, particularly when converting multiple locations (see example below). However, since our code is already highly optimized through the use of lazy operations, it is generally preferable to use the original interface, which offers better accuracy.

```julia
set_coefficients!(dt)
mlat, mlon, r = geoc2aacgm(glat, glon, height)
```

Benchmarks indicate that it performs faster than the equivalent C function for a single datetime and position. For multiple inputs with multiple datetimes, the performance gain is even more significant (thanks to lazy interpolation).