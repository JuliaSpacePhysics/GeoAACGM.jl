# GeoAACGM

[![DOI](https://zenodo.org/badge/992753544.svg)](https://doi.org/10.5281/zenodo.15588522)
[![Coverage](https://codecov.io/gh/JuliaSpacePhysics/GeoAACGM.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSpacePhysics/GeoAACGM.jl)

Pure Julia implementation of Altitude-Adjusted Corrected Geomagnetic (AACGM) coordinate system. Useful for organizing ionospheric and magnetospheric phenomena by magnetic connectivity.

## Quick Start

```julia
using Pkg; Pkg.add("LibAACGM")
using GeoAACGM
using Dates

dt = DateTime(2029, 3, 22, 3, 11)
glat, glon, height = 45.5, -23.5, 1000

# Convert geocentric / geodetic to AACGM
mlat, mlon, r = geoc2aacgm(glat, glon, height, dt)
mlat, mlon, r = geod2aacgm(glat, glon, height, dt)
```

## Magnetic local time

MLT depends on the magnetic coordinate system, not just on position and time:

```julia
using GeoCotrans: get_mlt

t = DateTime(2021, 4, 20, 0, 56)
r = [1359.9, 2960.5, -5988.8]  # GEO [km], L≈7.2 nightside

aacgm_mlt(r, t)  # 3.29 h, AACGM
get_mlt(r, t)    # 4.39 h, centered dipole
```

## What is AACGM?

AACGM labels positions by magnetic field lines. Its reference definition traces field lines to dipole magnetic equator and uses corresponding dipole field-line label as magnetic latitude and longitude.

GeoAACGM implements fast Shepherd (2014) spherical harmonic coefficient approximation, intended mainly below about 2000 km and outside the forbidden/undefined regions.

## Notes

Check [`shepherd2014_comparison.jl`](docs/examples/shepherd2014_comparison.jl) for Shepherd-style comparison plots between coefficient approximation and direct `GeoCotrans.trace` field-line tracing.

Full API map `@doc(GeoAACGM)` or [documentation](https://juliaspacephysics.github.io/GeoAACGM.jl). 
A Julia wrapper `LibAACGM` for the [AACGM-v2 C library](https://superdarn.thayer.dartmouth.edu/aacgm.html) is available under the [`LibAACGM`](./LibAACGM) directory.
