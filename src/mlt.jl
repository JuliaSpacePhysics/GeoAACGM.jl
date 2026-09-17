# Reference: C function `MLTConvert_v2`; same convention as SPEDAS `mlt_v2` and `aacgmv2.convert_mlt`.

# AACGM longitude [deg] of the subsolar point, evaluated at 700 km: the coefficients are
# undefined near the equatorial surface, and AACGM longitude tends to centered-dipole
# longitude with altitude, approaching the reference recommended by Laundal & Richmond (2017).
function subsolar_mlon(time)
    s = gei2geo(calc_sun_gei(time), time)
    _, colat, lon = car2sphd(s[1], s[2], s[3])
    return geoc2aacgm(90 - colat, lon, 700.0, time)[2]
end

"""
    aacgm_mlt(mlon, time)
    aacgm_mlt(𝐫_geo, time)

AACGM magnetic local time [hours], measured from the AACGM longitude of the subsolar point.

Other conventions reference a different longitude (Laundal & Richmond, 2017).
"""
aacgm_mlt(mlon::Number, time) = mod(12 + (mlon - subsolar_mlon(time)) / 15, 24)
aacgm_mlt(𝐫::AbstractVector, time) = aacgm_mlt(geo2aacgm(𝐫, time)[2], time)
