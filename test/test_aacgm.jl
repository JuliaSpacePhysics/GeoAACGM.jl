@testitem "geo[c/d]2aacgm and aacgm2geo[c/d]" setup = [Share] begin
    lat = 45.5
    lon = -23.5
    hgt = 1135
    dt = DateTime(2029, 3, 22, 3, 11)

    # Geodetic and geocentric to AACGM
    mlat, mlon, r = geod2aacgm(lat, lon, hgt, dt)
    c_geod2aacgm_result = (47.402897, 56.6023, 1.177533)
    @test _approx((mlat, mlon, r), c_geod2aacgm_result, atol = 1.0e-4)
    @test _approx(geoc2aacgm(lat, lon, hgt, dt), (47.595365, 56.631654, 1.178145), atol = 1.0e-6)

    # AACGM to geodetic
    c_aacgm2geod_result = (45.439863, -23.477496, 1134.977555)
    @info aacgm2geod(mlat, mlon, r, dt)
    @test _approx(aacgm2geod(mlat, mlon, r, dt), c_aacgm2geod_result, atol = 1.0e-6)

    # Multiple points
    n = 10
    glats = 45 .+ rand(n)
    glons = -23 .+ rand(n)
    hights = 1000 .+ 10 * rand(n)
    dts = dt .+ Second.(rand(Int8, n))
    set_coefficients!(dt)
    res1 = geoc2aacgm.(glats, glons, hights, dts)
    res2 = geoc2aacgm.(glats, glons, hights)
    @test _approx(res1, res2)

    # Benchmark
    using Chairmarks
    verbose = true
    b1 = @b geoc2aacgm.($glats, $glons, $hights, $dts)
    b2 = @b (set_coefficients!($dt); geoc2aacgm.($glats, $glons, $hights))
    @test b1.allocs == b2.allocs
    verbose && @info "Benchmarks" b1, b2
end

@testitem "geod2geoc" setup = [Share] begin
    using LibAACGM
    lat = 45.5
    lon = -23.5
    hgt = 1135

    c_res = AACGM_v2_Convert(lat, lon, hgt, 0)
    @test _approx(
        c_res,
        (47.402897, 56.6023, 1.177533); atol = 1.0e-6
    )
    j_res = geod2aacgm(lat, lon, hgt)
    @test _approx(j_res, c_res, atol = 1.0e-4)
    println(@b geod2aacgm($lat, $lon, $hgt), AACGM_v2_Convert($lat, $lon, $hgt, 0))
end


@testitem "geoc2aacgm - Validation" setup = [Share] begin
    using LibAACGM
    lat = 45.5
    lon = -23.5
    hgt = 1000 + 10 * rand()
    AACGM_v2_SetDateTime(dt)

    j_res = geoc2aacgm(lat, lon, hgt)
    c_res = convert_geo_coord_v2(lat, lon, hgt)
    @test _approx(j_res[1:2], c_res, atol = 1.0e-4)
end
