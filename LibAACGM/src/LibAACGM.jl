"""
Wrapper for the AACGM-v2 C library.
"""
module LibAACGM

using Dates
const SHORDER = 10

export AACGM_v2_SetDateTime, AACGM_v2_SetNow
export AACGM_v2_Convert, AACGM_v2_Rylm, AACGM_v2_Rylm!
export convert_geo_coord_v2

function set_env()
    AACGM_v2_DAT_PREFIX = joinpath(@__DIR__, "../../data/aacgm_coeffs-14/aacgm_coeffs-14-")
    ENV["AACGM_v2_DAT_PREFIX"] = AACGM_v2_DAT_PREFIX
    ENV["IGRF_COEFFS"] = joinpath(@__DIR__, "../../data/magmodel_1590-2025.txt")
end

# Find the library path
function find_library(name="aacgmlib")
    search_paths = (
        dirname(@__DIR__),
        "/usr/local/lib",
        "/usr/lib"
    )

    # Try to find the library
    for path in search_paths
        aacgmlib = joinpath(path, "$name.so")
        isfile(aacgmlib) && return aacgmlib
    end
    # if not try to install it
    @info "AACGM library not found, trying to install" run(`just install`)
    for path in search_paths
        aacgmlib = joinpath(path, "$name.so")
        isfile(aacgmlib) && return aacgmlib
    end
    error("AACGM library not found")
end

const aacgmlib = find_library()

__init__() = set_env()

AACGM_v2_SetNow() = @ccall aacgmlib.AACGM_v2_SetNow()::Int
AACGM_v2_SetDateTime(yr, mo, dy, hr, mt, sc) =
    @ccall aacgmlib.AACGM_v2_SetDateTime(
        yr::Int, mo::Int, dy::Int, hr::Int, mt::Int, sc::Int
    )::Int

AACGM_v2_SetDateTime(dt) = AACGM_v2_SetDateTime(
    year(dt), month(dt), day(dt), hour(dt), minute(dt), second(dt)
)

"""
err = AACGM_v2_Convert(in_lat, in_lon, height, out_lat, out_lon, r, code);
"""
function AACGM_v2_Convert(lat, lon, height, code)
    out_lat = Ref{Float64}(0.0)
    out_lon = Ref{Float64}(0.0)
    r = Ref{Float64}(0.0)
    @ccall aacgmlib.AACGM_v2_Convert(
        lat::Float64, lon::Float64, height::Float64,
        out_lat::Ptr{Float64}, out_lon::Ptr{Float64}, r::Ptr{Float64}, code::Int
    )::Int
    return out_lat[], out_lon[], r[]
end

"""
Second-level function used to determine the lat/lon of the input coordinates.
"""
convert_geo_coord_v2!(in_lat, in_lon, height, out_lat, out_lon, code, order) =
    @ccall aacgmlib.convert_geo_coord_v2(
        in_lat::Float64, in_lon::Float64, height::Float64,
        out_lat::Ptr{Float64}, out_lon::Ptr{Float64}, code::Int, order::Int
    )::Int

function convert_geo_coord_v2(in_lat, in_lon, height, code=0, order=SHORDER)
    out_lat = Ref{Float64}(0.0)
    out_lon = Ref{Float64}(0.0)
    convert_geo_coord_v2!(in_lat, in_lon, height, out_lat, out_lon, code, order)
    return out_lat[], out_lon[]
end

function AACGM_v2_Rylm!(ylmval, colat, lon, order)
    @ccall aacgmlib.AACGM_v2_Rylm(
        colat::Float64, lon::Float64, order::Int, ylmval::Ptr{Float64}
    )::Int
    return ylmval
end

AACGM_v2_Rylm(colat, lon, order) = AACGM_v2_Rylm!(
    zeros((order + 1)^2), colat, lon, order
)
end
