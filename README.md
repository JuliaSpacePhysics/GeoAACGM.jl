# Aacgm

[![Build Status](https://github.com/Beforerr/Aacgm.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Beforerr/Aacgm.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://beforerr.github.io/Aacgm.jl/stable)

A pure Julia implementation of the Altitude-Adjusted Corrected Geomagnetic (AACGM) coordinate system. Fast and accurate.

A Julia wrapper `LibAacgm` for the AACGM-v2 C library is also available in the [`LibAacgm`](./LibAacgm) directory, mainly used for testing and benchmarking.

```julia
using Aacgm
using Dates

dt = DateTime(2029, 3, 22, 3, 11)
glat, glon, height = 45.5, -23.5, 1000

# Convert geocentric to AACGM
mlat, mlon, r = geoc2aacgm(glat, glon, height, dt)

# Convert geodetic to AACGM
mlat, mlon, r = geod2aacgm(glat, glon, height, dt)
```