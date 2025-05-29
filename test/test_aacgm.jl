@testitem "geoc2aacgm" setup = [Share] begin
    lat = 45.5
    lon = -23.5
    hgt = 1135
    dt = DateTime(2029, 3, 22, 3, 11)

    @test _approx(geod2aacgm(lat, lon, hgt, dt), (47.402897, 56.602300, 1.177533), atol=1e-4)
    @test _approx(geoc2aacgm(lat, lon, hgt, dt), (47.595365, 56.631654, 1.178145), atol=1e-6)

    n = 10
    glats = 45 .+ rand(n)
    glons = -23 .+ rand(n)
    hights = 1000 .+ 10 * rand(n)
    dts = dt .+ Second.(rand(Int8, n))
    @test all(_approx.(geoc2aacgm.(glats, glons, hights, dts), geoc2aacgm.(glats, glons, hights)))

    @b geoc2aacgm.(glats, glons, hights, dts)
    @b (set_coefficients!(dt); geoc2aacgm.(glats, glons, hights))
end

@testitem "geod2geoc" setup = [Share] begin
    using LibAacgm
    lat = 45.5
    lon = -23.5
    hgt = 1135

    c_res = AACGM_v2_Convert(lat, lon, hgt, 0)
    @test _approx(
        c_res,
        (47.402897, 56.602300, 1.177533); atol=1e-6
    )
    j_res = geod2aacgm(lat, lon, hgt)
    @test _approx(j_res, c_res, atol=1e-4)
    println(@b geod2aacgm($lat, $lon, $hgt), AACGM_v2_Convert($lat, $lon, $hgt, 0))
end



@testitem "geoc2aacgm - Validation" setup = [Share] begin
    using LibAacgm
    lat = 45.5
    lon = -23.5
    hgt = 1000 + 10 * rand()
    AACGM_v2_SetDateTime(dt)

    j_res = geoc2aacgm(lat, lon, hgt)
    c_res = convert_geo_coord_v2(lat, lon, hgt)
    @test _approx(j_res[1:2], c_res, atol=1e-4)
end
