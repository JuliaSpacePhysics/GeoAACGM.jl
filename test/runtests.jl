using Pkg
# LibAACGM is unregistered and `[sources]` needs Julia 1.11+
Pkg.develop(PackageSpec(path = joinpath(@__DIR__, "..", "LibAACGM")))
# prereleases often have no installable JET.
const RUN_JET_TESTS = isempty(VERSION.prerelease)
RUN_JET_TESTS && Pkg.add("JET")

using TestItems, TestItemRunner

@run_package_tests filter = ti -> !(:skipci in ti.tags) && (RUN_JET_TESTS || !(:jet in ti.tags))

@testsnippet Share begin
    using Dates
    using Chairmarks
    using LibAACGM

    yr, mo, dy, hr, mt, sc = 2029, 3, 22, 3, 11, 0
    dt = DateTime(yr, mo, dy, hr, mt, sc)
    AACGM_v2_SetDateTime(dt)
    set_coefficients!(dt)

    # Helper function to compare element-wise
    _approx(a, b; kw...) = length(a) == 1 ? isapprox(a, b; kw...) : all(_approx.(a, b; kw...))
end

@testitem "AACGM_v2_Rylm Comparison" setup = [Share] begin
    using GeoAACGM: compute_harmonics!, compute_harmonics
    using GeoAACGM.SphericalHarmonics
    using LibAACGM: AACGM_v2_Rylm, AACGM_v2_Rylm!
    using Chairmarks

    colat = deg2rad(35)  # 45 degrees in radians
    lon = deg2rad(30)    # 30 degrees in radians
    order = 10
    S = SphericalHarmonics.cache(order, SphericalHarmonics.RealHarmonics())

    # Call our Julia implementation
    julia_results = compute_harmonics!(S, colat, lon, order)
    c_results = AACGM_v2_Rylm(colat, lon, order)
    # Compare the results
    @test julia_results == compute_harmonics(colat, lon, order)
    @test julia_results ≈ c_results
    println.(
        @b compute_harmonics!($S, $colat, $lon, $order),
            compute_harmonics($colat, $lon, $order),
            AACGM_v2_Rylm!($c_results, $colat, $lon, $order)
    )
end


@testitem "Coefficient Loading" begin
    using Dates
    @info Base.summarysize(set_coefficients!(Date(2029))) |> Base.format_bytes
end

@testitem "JET static analysis" tags = [:jet] begin
    using JET
    @test_call GeoAACGM.workload()
end

@testitem "Aqua" begin
    using Aqua
    Aqua.test_all(GeoAACGM)
end
