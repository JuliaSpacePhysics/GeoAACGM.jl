using TestItems, TestItemRunner

@run_package_tests filter = ti -> !(:skipci in ti.tags)

@testsnippet Share begin
    using Pkg
    Pkg.develop(path="../LibAacgm")
    using LibAacgm
    using Dates
    using Chairmarks

    yr, mo, dy, hr, mt, sc = 2029, 3, 22, 3, 11, 0
    dt = DateTime(yr, mo, dy, hr, mt, sc)
    AACGM_v2_SetDateTime(dt)
    set_coefficients!(dt)

    _approx(a, b; kw...) = all(isapprox.(a, b; kw...))
end

@testitem "AACGM_v2_Rylm Comparison" begin
    # Test parameters - same as in the C test
    using Aacgm.SphericalHarmonics
    using LibAacgm
    using Chairmarks

    colat = deg2rad(35)  # 45 degrees in radians
    lon = deg2rad(30)    # 30 degrees in radians
    order = 10

    SHType = SphericalHarmonics.RealHarmonics()
    S = SphericalHarmonics.cache(order, SHType)

    # Call our Julia implementation
    julia_results = compute_harmonics!(S, colat, lon, order)
    c_results = AACGM_v2_Rylm(colat, lon, order)
    # Compare the results
    @test julia_results ≈ c_results
    println.(@b compute_harmonics!($S, $colat, $lon, $order),
    compute_harmonics($colat, $lon, $order),
    AACGM_v2_Rylm!($c_results, $colat, $lon, $order)
    )
end


@testitem "Coefficient Loading" begin
    @info Base.summarysize(load_coefficients!(2029)) |> Base.format_bytes
end

@testitem "JET" setup = [Share] begin
    using JET
    load_coefficients!(dt)
    @test_call geoc2aacgm(45.5, -23.5, 1000)
end

@testitem "Aqua" begin
    using Aqua
    Aqua.test_all(Aacgm)
end
