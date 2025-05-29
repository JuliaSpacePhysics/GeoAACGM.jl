"""
References:
- [FastTransforms](https://mikaelslevinsky.github.io/FastTransforms/index.html)
- [SphericalHarmonics.jl](https://github.com/jishnub/SphericalHarmonics.jl)
- [HarmonicOrthogonalPolynomials](https://github.com/JuliaApproximation/HarmonicOrthogonalPolynomials.jl?tab=readme-ov-file)
"""

using SphericalHarmonics
using SphericalHarmonics: RealHarmonics

const S_cached = SphericalHarmonics.cache(SHORDER, RealHarmonics())

function apply_aacgm_normalization!(Yₗₘ, order)
    for l in 0:order
        k0 = l * (l + 1) + 1
        for m in -l:-1
            sign_factor = ifelse(isodd(-m), 1, -1)
            @inbounds Yₗₘ[k0+m] *= sign_factor / sqrt(2)
        end
        for m in 1:l
            @inbounds Yₗₘ[k0+m] /= sqrt(2)
        end
    end
    Yₗₘ
end

"""
    compute_harmonics!(S, colat, lon, order)

Compute spherical harmonic function values Y_lm(`colat`, `lon`) up to given `order`.
This is equivalent to the C function `AACGM_v2_Rylm`.

Return a vector of spherical harmonic values with indexing ``k = l*(l+1) + m + 1``.
"""
function compute_harmonics!(S, colat, lon, order)
    computePlmcostheta!(S, colat, order)
    computeYlm!(S, colat, lon, order)
    apply_aacgm_normalization!(S.Y, order)
end


function compute_harmonics(colat, lon, order)
    # Get spherical harmonics from the library
    SHType = SphericalHarmonics.RealHarmonics()
    Ylms = computeYlm(colat, lon, lmax=order, SHType=SHType)
    apply_aacgm_normalization!(Ylms, order)
    return Ylms
end
