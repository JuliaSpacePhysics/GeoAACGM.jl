"""
    GeoAACGM

A pure Julia implementation of the Altitude-Adjusted Corrected Geomagnetic (AACGM)
coordinate system.

Simple, fast, and accurate.

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
using StaticArrays: MVector
using Tullio: @tullio
using LazyArrays

include("constants.jl")
include("harmonics.jl")
include("cotrans.jl")
include("coefs.jl")
include("workload.jl")

export geoc2aacgm, geod2aacgm, geod2geoc
export geo2aacgm, cart2sph
end
