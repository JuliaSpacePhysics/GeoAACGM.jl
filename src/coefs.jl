# Related C functions:
# AACGM_v2_LoadCoefFP, AACGM_v2_LoadCoef, AACGM_v2_LoadCoefs
export get_coefficients, set_coefficients!

const geo2aacgm_coefs = Ref{Array{Float64, 3}}()
const aacgm2geo_coefs = Ref{Array{Float64, 3}}()

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

# Epoch boundaries; `coefs_lookup[i]` interpolates over [COEF_EPOCHS[i], COEF_EPOCHS[i + 1])
const COEF_EPOCHS = DateTime.(1590:5:2030)

const coefs_lookup = let
    coefs = [load_coefficients(year(t)) for t in COEF_EPOCHS]
    geo2aacgm_coefs[] = copy(coefs[1][1])
    aacgm2geo_coefs[] = copy(coefs[1][2])
    [(coefs[i]..., (coefs[i + 1] .- coefs[i])...) for i in 1:(length(coefs) - 1)]
end

function get_coefficients(time::DateTime)
    i = searchsortedlast(COEF_EPOCHS, time)
    checkbounds(Bool, coefs_lookup, i) ||
        throw(DomainError(time, "AACGM coefficients cover [$(first(COEF_EPOCHS)), $(last(COEF_EPOCHS)))"))
    g2a0, a2g0, dg2a, da2g = @inbounds coefs_lookup[i]
    t0, tf = @inbounds COEF_EPOCHS[i], COEF_EPOCHS[i + 1]
    ratio = (time - t0) / (tf - t0)
    g2a = LinearInterp(g2a0, dg2a, ratio)
    a2g = LinearInterp(a2g0, da2g, ratio)
    return g2a, a2g
end

get_coefficients(time::AbstractTime) = get_coefficients(DateTime(time))

function set_coefficients!(time::T) where {T <: AbstractTime}
    g2a, a2g = get_coefficients(time)
    geo2aacgm_coefs[] .= g2a
    aacgm2geo_coefs[] .= a2g
    return geo2aacgm_coefs[], aacgm2geo_coefs[]
end
