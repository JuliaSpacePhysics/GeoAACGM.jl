function check_height(height)
    height < 0 && @warn "Coordinate transformations are not intended for altitudes < 0 km: $height"
    height > MAXALT && @error "Coefficients are not valid for altitudes above $MAXALT km: $height"
    return
end

"""
    geoc2aacgm(lat, lon, height, time, ...) -> (mlat, mlon, r)
    geoc2aacgm(lat, lon, height, coefs=geo2aacgm_coefs[], ...) -> (mlat, mlon, r)

Convert between geocentric `(lat [deg], lon [deg], height [km])` and AACGM coordinates
`(mlat [deg], mlon [deg], r [Earth radii])` using spherical harmonic expansion.

Similar to the C function `convert_geo_coord_v2`.
"""
function geoc2aacgm(lat, lon, height, coefs = geo2aacgm_coefs[]; order = nothing, verbose = false)
    order = something(order, SHORDER)
    check_height(height)
    # Prepare input coordinates
    T = promote_type(typeof(lat), typeof(lon), typeof(height))
    lon_rad = deg2rad(lon)
    colat_rad = deg2rad(90 - lat)

    Yₗₘ = compute_harmonics!(S_cached, colat_rad, lon_rad, order)
    alt_var = height / MAXALT
    alt_powers = (one(alt_var), alt_var, alt_var^2, alt_var^3, alt_var^4)

    x, y, z = @no_escape begin
        𝐫 = @alloc(T, 3)
        @tullio 𝐫[i] = Yₗₘ[k] * coefs[k, i, j] * alt_powers[j] threads = false
        𝐫[1], 𝐫[2], 𝐫[3]
    end

    fac = x^2 + y^2
    if fac > 1
        verbose && @warn "Fac > 1, we are in the forbidden region where solution is undefined"
        return T(NaN), T(NaN), T(NaN)
    end
    ztmp = sqrt(1 - fac)

    # Calculate longitude and latitude
    colat_out = acosd(z < 0 ? -ztmp : ztmp)
    lon_out = atand(y, x)
    lat_out = 90 - colat_out
    return lat_out, lon_out, (height + RE) / RE
end


function geoc2aacgm(lat, lon, height, time::AbstractTime, args...; kws...)
    g2a = get_coefficients(time)[1]
    return geoc2aacgm(lat, lon, height, g2a, args...; kws...)
end

"""
    aacgm2alt(hgt, lat)

Transformation from AACGM to so-called 'at-altitude' coordinates.

The purpose of this function is to scale the latitudes in such a way that there is no gap.
The problem is that for non-zero altitudes (h) are range of latitudes near the equator
    lie on dipole field lines that near reach the altitude h, and are therefore not accessible.
This mapping closes the gap.

    cos (lat_at-alt) = sqrt( (Re + h)/Re ) cos (lat_aacgm)

Similar to the C function `AACGM_v2_CGM2Alt`.
"""
function aacgm2alt(hgt, lat)
    r1 = cosd(lat)
    ra = (hgt / RE + one(hgt)) * (r1 * r1)
    ra = min(ra, one(hgt))
    r1 = acos(sqrt(ra))
    return sign(lat) * sign(r1) * rad2deg(r1)
end


"""
    aacgm2geoc(mlat, mlon, r, time / coefs, order)

Convert AACGM coordinates `(mlat [deg], mlon [deg], r [Earth radii])`
to geocentric coordinates `(lat [deg], lon [deg], height [km])`.
"""
function aacgm2geoc(mlat, mlon, r, coefs = aacgm2geo_coefs[]; order = nothing)
    order = @something(order, SHORDER)
    T = promote_type(typeof(mlat), typeof(mlon), typeof(r))

    height = (r - 1) * RE
    lon_rad = deg2rad(mlon)
    lat_adj = aacgm2alt(height, mlat)
    colat_rad = deg2rad(90. - lat_adj)

    Yₗₘ = compute_harmonics!(S_cached, colat_rad, lon_rad, order)
    alt_var = height / MAXALT
    alt_powers = (one(alt_var), alt_var, alt_var^2, alt_var^3, alt_var^4)

    x, y, z = @no_escape begin
        𝐫 = @alloc(T, 3)
        @tullio 𝐫[i] = Yₗₘ[k] * coefs[k, i, j] * alt_powers[j] threads = false
        normalize!(𝐫)
        𝐫[1], 𝐫[2], 𝐫[3]
    end

    colat_out = acosd(z)
    lat_out = 90 - colat_out
    lon_out = atand(y, x)

    return lat_out, lon_out, height
end

function aacgm2geoc(mlat, mlon, r, time::AbstractTime, args...; kws...)
    a2g_coefs = get_coefficients(time)[2]
    return aacgm2geoc(mlat, mlon, r, a2g_coefs, args...; kws...)
end

"""
    aacgm2geod(mlat, mlon, r, time / coefs)

Convert AACGM coordinates `(mlat [deg], mlon [deg], r [Earth radii])`
to geodetic coordinates `(lat [deg], lon [deg], height [km])`.
"""
function aacgm2geod(mlat, mlon, r, args...; kws...)
    return geoc2geod(aacgm2geoc(mlat, mlon, r, args...; kws...)...)
end

"""
    geod2aacgm(lat, lon, height, time / coefs)

Convert geodetic coordinates `(lat [deg], lon [deg], height [km])`
to AACGM coordinates `(mlat [deg], mlon [deg], r [Earth radii])`.

Similar to the C function `AACGM_v2_Convert`.
"""
function geod2aacgm(lat, lon, height, time...)
    return geoc2aacgm(geod2geoc(lat, lon, height)..., time...)
end

"""
    geod2geo(lat, lon, height)

Convert geodetic coordinates `(lat [deg], lon [deg], height [km])` 
to geocentric geographic Cartesian coordinates `(x [km], y [km], z [km])`.
"""
geod2geo(lat, lon, height) = geoc2geo(geod2geoc(lat, lon, height)...)

sph2geoc(sph) = (90 - rad2deg(sph[2]), rad2deg(sph[3]), sph[1] * R🜨 - R🜨)

geoc2geo(lat, lon, alt) = sphd2car(alt + RE, 90 - lat, lon)

"""
    geod2geoc(lat, lon, alt)

Convert geodetic coordinates to geocentric coordinates.
"""
geod2geoc(lat, lon, alt) = sph2geoc(gdz2sph(lat, lon, alt))

"""
    geo2aacgm(x, y, z, time)

Convert `(x [km], y [km], z [km])` in **geocentric geographic** (cartesian) coordinates to
`(mlat [deg], mlon [deg], r [Earth radii])` in AACGM coordinate.
"""
function geo2aacgm(x, y, z, time)
    r, lati, longi = car2sphd(x, y, z)
    return geoc2aacgm(90 - lati, longi, r - RE, time)
end

geo2aacgm(𝐫, time) = geo2aacgm(𝐫[1], 𝐫[2], 𝐫[3], time)
geo2aacgm(𝐫::AbstractVector, time) = SVector{3}(geo2aacgm(𝐫[1], 𝐫[2], 𝐫[3], time))


"""
    geoc2geod(lat, lon, r)

Convert geocentric coordinates to geodetic coordinates 
`(lat_geod [deg], lon [deg], height [km])`.
"""
geoc2geod(lat, lon, hgt) = car2gdz(geoc2geo(lat, lon, hgt); scale = 1.0)
