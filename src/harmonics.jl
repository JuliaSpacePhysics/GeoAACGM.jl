# (a, b) at (l, m), stored at l(l+1)/2 + m + 1, for the fully normalized recursion
# P̄ₗᵐ = a (cos θ P̄ₗ₋₁ᵐ - b P̄ₗ₋₂ᵐ), with a = √((4l² - 1) / (l² - m²)) and b = 1 / a at (l - 1, m).
const LEGENDRE_RECURRENCE = Tuple(
    l == m ? (NaN, NaN) : (sqrt((4l^2 - 1) / (l^2 - m^2)), sqrt(((l - 1)^2 - m^2) / (4(l - 1)^2 - 1)))
        for l in 0:SHORDER for m in 0:l
)

"""
    compute_harmonics(colat, lon, order = SHORDER)

Compute spherical harmonic function values Y_lm(`colat`, `lon`) up to given `order`.
This is equivalent to the C function `AACGM_v2_Rylm`.

Return a vector of spherical harmonic values with indexing ``k = l*(l+1) + m + 1``;
entries above `order` are zero.
"""
@inline function compute_harmonics(colat, lon, order = SHORDER)
    0 <= order <= SHORDER || throw(ArgumentError("order must be in 0:$SHORDER, got $order"))
    T = float(promote_type(typeof(colat), typeof(lon)))
    Y = zeros(MVector{AACGM_KMAX, T})
    sinθ, cosθ = sincos(colat)
    sinφ, cosφ = sincos(lon)
    cos_m, sin_m = one(T), zero(T)
    Pmm = T(inv(sqrt(4π)))
    @inbounds for m in 0:order
        # AACGM's sign convention: Yₗᵐ = (-1)ᵐ P̄ₗᵐ cos mφ, Yₗ₋ₘ = -P̄ₗᵐ sin mφ (P̄ without Condon–Shortley phase)
        Ycos, Ysin = isodd(m) ? -cos_m : cos_m, -sin_m
        P, P₋ = Pmm, zero(T)
        for l in m:order
            if l > m
                a, b = T.(LEGENDRE_RECURRENCE[l * (l + 1) ÷ 2 + m + 1])
                P, P₋ = a * muladd(cosθ, P, -b * P₋), P
            end
            k = l * (l + 1) + 1
            # At m = 0 both indices coincide; the cosine term is written last
            Y[k - m] = P * Ysin
            Y[k + m] = P * Ycos
        end
        cos_m, sin_m = cos_m * cosφ - sin_m * sinφ, sin_m * cosφ + cos_m * sinφ
        Pmm *= sqrt(T(2m + 3) / (2m + 2)) * sinθ
    end
    return Y
end
