# GeoAACGM

[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaspacephysics.github.io/GeoAACGM.jl)

[![Build Status](https://github.com/JuliaSpacePhysics/GeoAACGM.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaSpacePhysics/GeoAACGM.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Coverage](https://codecov.io/gh/JuliaSpacePhysics/GeoAACGM.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSpacePhysics/GeoAACGM.jl)

[![DOI](https://zenodo.org/badge/992753544.svg)](https://doi.org/10.5281/zenodo.15588522)

A pure Julia implementation of the Altitude-Adjusted Corrected Geomagnetic (AACGM) coordinate system. Fast and accurate.

A Julia wrapper `LibAACGM` for the AACGM-v2 C library is also available in the [`LibAACGM`](./LibAACGM) directory, mainly used for testing and benchmarking.

## Installation

```julia
using Pkg
Pkg.add("GeoAACGM")
```

## Usage

```julia
using GeoAACGM
using Dates

dt = DateTime(2029, 3, 22, 3, 11)
glat, glon, height = 45.5, -23.5, 1000

# Convert geocentric to AACGM
mlat, mlon, r = geoc2aacgm(glat, glon, height, dt)

# Convert geodetic to AACGM
mlat, mlon, r = geod2aacgm(glat, glon, height, dt)
```