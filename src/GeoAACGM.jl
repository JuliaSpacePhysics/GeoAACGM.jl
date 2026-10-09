"""
    GeoAACGM

Altitude-Adjusted Corrected Geomagnetic (AACGM) coordinate system for fast magnetic field line tracing.

Coordinate transform between the following coordinate systems:

- **AACGM**: `(mlat [deg], mlon [deg], r [Earth radii])`,
    based on the [IGRF-14 model](https://www.ncei.noaa.gov/products/international-geomagnetic-reference-field) (1900-2030)
    and [GUFM1 model](https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2002RG000115) (1590-1900).

- **Geocentric**: `(lat [deg], lon [deg], height [km])`

- **Geodetic**: `(lat [deg], lon [deg], height [km])`, based on the WGS84 ellipsoid model of the Earth.

with [`geoc2aacgm`](@ref) / [`aacgm2geoc`](@ref), [`geod2aacgm`](@ref) / [`aacgm2geod`](@ref), [`geod2geoc`](@ref) / [`geoc2geod`](@ref) functions.

Other useful functions: [`geo2aacgm`](@ref), [`gei2aacgm`](@ref), [`aacgm_mlt`](@ref).

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
"""
module GeoAACGM
using Dates
using Dates: AbstractTime
using LinearAlgebra
using FixedSizeArrays
using StaticArrays: SA, SVector, MVector
using TimeseriesUtilities: mapsamples, tdimnum, times
using GeoCotrans: gdz2sph, car2gdz, car2sphd, sphd2car, R🜨
using GeoCotrans: gei2geo, LinearInterp, calc_sun_gei

include("constants.jl")
include("harmonics.jl")
include("cotrans.jl")
include("coefs.jl")
include("mlt.jl")

export geoc2aacgm, geod2aacgm
export geod2geoc, geoc2geod
export aacgm2geoc, aacgm2geod
export geo2aacgm, gei2aacgm
export aacgm_mlt

"""
    gei2aacgm(x, y, z, time)

Convert `(x [km], y [km], z [km])` in GEI (Geocentric Equatorial Inertial) coordinates to
`(mlat [deg], mlon [deg], r [Earth radii])` in AACGM coordinate.
"""
gei2aacgm(x, y, z, time) = geo2aacgm(gei2geo(SA[x, y, z], time)..., time)

for op in (:geo2aacgm, :gei2aacgm, :geod2aacgm, :aacgm2geoc, :aacgm2geod)
    @eval $op(𝐫::AbstractVector, time) = SVector{3}($op(𝐫[1], 𝐫[2], 𝐫[3], time))
    @eval $op(A::AbstractMatrix; dim = nothing) = $op(A, times(A, dim); dim)
    @eval $op(A::AbstractMatrix, times; dim = nothing) = mapsamples($op, A, times; dim = _sampledim(A, dim))
end

# plain matrices stack samples as columns; keyed containers (e.g. DimArray) declare their time dimension
_sampledim(A, dim) = @something dim tdimnum(A) 2

include("workload.jl")

end

## References

# Python library: https://github.com/aburrell/aacgmv2 and https://aacgmv2.readthedocs.io/en/latest