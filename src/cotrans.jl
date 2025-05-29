function check_height(height)
    height < 0 && @warn "Coordinate transformations are not intended for altitudes < 0 km: $height"
    height > MAXALT && @error "Coefficients are not valid for altitudes above $MAXALT km: $height"
end

"""
    geoc2aacgm(lat, lon, height, time, ...) -> (mlat, mlon, r)
    geoc2aacgm(lat, lon, height, coefs=geo2aacgm_coefs[], ...) -> (mlat, mlon, r)

Convert between geocentric `(lat, lon, height [km])` and AACGM coordinates `(mlat, mlon, r)`
using spherical harmonic expansion.

Similar to the C function `convert_geo_coord_v2`.
"""
function geoc2aacgm(lat, lon, height, coefs=geo2aacgm_coefs[], order=SHORDER)
    check_height(height)
    # Prepare input coordinates
    T = promote_type(typeof(lat), typeof(lon), typeof(height))
    lon_rad = deg2rad(lon)
    colat_rad = deg2rad(90 - lat)

    Yₗₘ = compute_harmonics!(S_cached, colat_rad, lon_rad, order)
    alt_var = height / MAXALT
    alt_powers = (one(alt_var), alt_var, alt_var^2, alt_var^3, alt_var^4)

    r = MVector{3,T}(undef)
    @tullio r[i] = Yₗₘ[k] * coefs[k, i, j] * alt_powers[j]
    x, y, z = r

    fac = x^2 + y^2
    if fac > 1
        error("Fac > 1, we are in the forbidden region where solution is undefined")
        return NaN, NaN
    end
    ztmp = sqrt(1 - fac)

    # Calculate longitude and latitude
    colat_out = acosd(z < 0 ? -ztmp : ztmp)
    lon_out = atand(y, x)
    lat_out = 90 - colat_out
    return lat_out, lon_out, (height + RE) / RE
end


function geoc2aacgm(lat, lon, height, time::AbstractTime, order=SHORDER)
    g2a, _ = get_coefficients(time)
    return geoc2aacgm(lat, lon, height, g2a, order)
end

"""
    geod2aacgm(lat, lon, height)

Convert geodetic coordinates to AACGM coordinates.

Similar to the C function `AACGM_v2_Convert`.
"""
function geod2aacgm(lat, lon, height, time...)
    r_RE, colat, lon = geod2geoc(lat, lon, height)
    return geoc2aacgm(90 - colat, lon, (r_RE - 1) * RE, time...)
end


"""
    geod2geoc(lat, lon, alt)

Convert geodetic coordinates to geocentric coordinates.
"""
function geod2geoc(lat, lon, alt)
    θ = (90 - lat)
    st = sind(θ)
    ct = cosd(θ)

    st2 = st * st
    ct2 = ct * ct
    one = EARTH_A2 * st2
    two = EARTH_B2 * ct2
    three = one + two

    # Calculate radius terms
    rho = sqrt(three)
    r = sqrt(alt * (alt + 2 * rho) + (EARTH_A2 * one + EARTH_B2 * two) / three)

    # Calculate direction cosines
    cd = (alt + rho) / r
    sd = EARTH_A2_B2_DIFF / rho * ct * st / r

    r_RE = r / RE
    colat = acosd(ct * cd - st * sd)
    return r_RE, colat, lon
end


"""
    geoc2geod(lat_geoc, lon, r)

Convert geocentric coordinates to geodetic coordinates.
This is part of the coordinate transformation pipeline in AACGM-v2.

# Arguments
- `lat_geoc::Float64`: Geocentric latitude in degrees
- `lon::Float64`: Longitude in degrees
- `r::Float64`: Geocentric radius in Earth radii

# Returns
- `(lat_geod, lon, height)`: Geodetic coordinates (latitude in degrees, longitude in degrees, height in km)
"""
function geoc2geod(lat_geoc::Float64, lon::Float64, r::Float64)
    # WGS84 ellipsoid parameters
    a = 6378.137  # semi-major axis in km
    f = 1 / 298.257223563  # flattening
    e2 = f * (2 - f)  # first eccentricity squared

    lat_rad = deg2rad(lat_geoc)
    lon_rad = deg2rad(lon)

    # Convert from spherical to Cartesian
    r_km = r * RE
    x = r_km * cos(lat_rad) * cos(lon_rad)
    y = r_km * cos(lat_rad) * sin(lon_rad)
    z = r_km * sin(lat_rad)

    # Iterative conversion to geodetic
    p = sqrt(x^2 + y^2)
    lat_geod = atan(z / p)  # initial guess

    for _ in 1:10  # iterate to convergence
        N = a / sqrt(1 - e2 * sin(lat_geod)^2)
        height = p / cos(lat_geod) - N
        lat_geod_new = atan(z / (p * (1 - e2 * N / (N + height))))

        if abs(lat_geod_new - lat_geod) < 1e-12
            break
        end
        lat_geod = lat_geod_new
    end

    N = a / sqrt(1 - e2 * sin(lat_geod)^2)
    height = p / cos(lat_geod) - N

    return (rad2deg(lat_geod), lon, height)
end
