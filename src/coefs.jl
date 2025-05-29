# Related C functions:
# AACGM_v2_LoadCoefFP
# AACGM_v2_LoadCoef
# AACGM_v2_LoadCoefs
export get_coefficients, set_coefficients!

const geo2aacgm_coefs = Ref{Array{Float64,3}}()
const aacgm2geo_coefs = Ref{Array{Float64,3}}()

"""
    get_coefficient_path(year)

Determine the path to the coefficient file for a given `year`.
AACGM coefficients are provided in 5-year epochs.
"""
function get_coefficient_path(year)
    epoch_year = (year ÷ 5) * 5
    filename = "aacgm_coeffs-14-$(epoch_year).asc"
    path = joinpath(@__DIR__, "../data/aacgm_coeffs-14", filename)
    isfile(path) || error("AACGM coefficient file not found: $path")
    return path
end

"""
    load_coefficients(year)

Load AACGM coefficient files for the specified `year` (1590-2025).

Coefficients are organized in 5-year epochs.
"""
function load_coefficients(year)
    path = get_coefficient_path(year)
    content = read(path, String)
    values = split(content)
    data = map(x -> parse(Float64, x), values)
    full_data = reshape(data, (AACGM_KMAX, NCOORD, POLYORD, 2))

    # Extract separate arrays for G2A and A2G conversions
    g2a_data = full_data[:, :, :, 1]
    a2g_data = full_data[:, :, :, 2]

    return g2a_data, a2g_data
end

const coefs_dict = dictionary(year => load_coefficients(year) for year in 1590:5:2030)

function set_coefficients!(year::Int)
    g2a, a2g = coefs_dict[year]
    geo2aacgm_coefs[] = g2a
    aacgm2geo_coefs[] = a2g
    return g2a, a2g
end

function get_coefficients(time::T) where T<:AbstractTime
    epoch_year = (year(time) ÷ 5) * 5
    next_epoch = epoch_year + 5
    g2a1, a2g1 = coefs_dict[epoch_year]
    g2a2, a2g2 = coefs_dict[next_epoch]
    t0, tf = T(epoch_year), T(next_epoch)
    ratio = (time - t0) / (tf - t0)
    return @~(g2a1 .+ (g2a2 .- g2a1) .* ratio), @~(a2g1 .+ (a2g2 .- a2g1) .* ratio)
end

function set_coefficients!(time::T) where T<:AbstractTime
    g2a, a2g = get_coefficients(time)
    geo2aacgm_coefs[] = Base.materialize(g2a)
    aacgm2geo_coefs[] = Base.materialize(a2g)
    return geo2aacgm_coefs[], aacgm2geo_coefs[]
end
