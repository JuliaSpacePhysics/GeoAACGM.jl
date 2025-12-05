"""
    GeoAACGM

A pure Julia implementation of the Altitude-Adjusted Corrected Geomagnetic (AACGM)
coordinate system to trace magnetic field lines for ionospheric and magnetospheric
research.

Simple, fast, and accurate.

We support coordinate transformations between the following coordinate systems:

- **AACGM**: `(mlat [deg], mlon [deg], r [Earth radii])`,
    based on the [IGRF-14 model](https://www.ncei.noaa.gov/products/international-geomagnetic-reference-field) (1900-2030)
    and [GUFM1 model](https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2002RG000115) (1590-1900).

- **Geocentric**: `(lat [deg], lon [deg], height [km])`

- **Geodetic**: `(lat [deg], lon [deg], height [km])`, based on the WGS84 ellipsoid model of the Earth.

with [`geoc2aacgm`](@ref), [`geod2aacgm`](@ref), [`geod2geoc`](@ref) functions.

## Examples

```julia
using GeoAACGM, Dates

dt = DateTime(2029, 3, 22, 3, 11);
glat, glon, height = 45.5, -23.5, 1135;

# Convert geocentric to AACGM
mlat, mlon, r = geoc2aacgm(glat, glon, height, dt)

# Convert geodetic to AACGM
mlat, mlon, r = geod2aacgm(glat, glon, height, dt)
```

## References

- [AACGM-V2](https://superdarn.thayer.dartmouth.edu/aacgm.html)
- [aacgmv2](https://aacgmv2.readthedocs.io/en/latest):
    Python library for AACGM-v2 magnetic coordinates [GitHub](https://github.com/aburrell/aacgmv2)
"""
module GeoAACGM
using Dates
using Dates: AbstractTime
using Dictionaries: dictionary
using LinearAlgebra
using FixedSizeArrays
using StaticArrays: SVector
using Bumper
using Tullio: @tullio
using LazyArrays

include("constants.jl")
include("harmonics.jl")
include("cotrans.jl")
include("coefs.jl")
include("workload.jl")

export geoc2aacgm, geod2aacgm
export geod2geoc, geoc2geod
export aacgm2geoc, aacgm2geod
export geo2aacgm
export gei2aacgm

function gei2aacgm end
end
