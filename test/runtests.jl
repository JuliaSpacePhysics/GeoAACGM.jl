using TestItems, TestItemRunner

@run_package_tests filter = ti -> !(:skipci in ti.tags)

@testsnippet Share begin
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
    using Aacgm: compute_harmonics!, compute_harmonics
    using Aacgm.SphericalHarmonics
    using LibAacgm: AACGM_v2_Rylm, AACGM_v2_Rylm!
    using Chairmarks

    colat = deg2rad(35)  # 45 degrees in radians
    lon = deg2rad(30)    # 30 degrees in radians
    order = 10
    S = SphericalHarmonics.cache(order, SphericalHarmonics.RealHarmonics())

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
    @info Base.summarysize(set_coefficients!(Date(2029))) |> Base.format_bytes
end

@testitem "JET" setup = [Share] begin
    using JET
    @test_call Aacgm.workload()
end

@testitem "Aqua" begin
    using Aqua
    Aqua.test_all(Aacgm)
end
