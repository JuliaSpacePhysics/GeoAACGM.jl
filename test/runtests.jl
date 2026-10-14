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
    using GeoAACGM: compute_harmonics
    using LibAACGM: AACGM_v2_Rylm, AACGM_v2_Rylm!
    using Chairmarks

    for colat in (0.0, deg2rad(35), π / 2, π), lon in (-π, deg2rad(30), 3.0), order in (3, 10)
        n = (order + 1)^2
        Y = compute_harmonics(colat, lon, order)
        @test Y[1:n] ≈ AACGM_v2_Rylm(colat, lon, order)[1:n] atol = 1.0e-14
        @test all(iszero, Y[(n + 1):end])
    end
    colat, lon, order = deg2rad(35), deg2rad(30), 10
    c_results = AACGM_v2_Rylm(colat, lon, order)
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
