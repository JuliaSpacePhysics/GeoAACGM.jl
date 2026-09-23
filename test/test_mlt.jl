@testitem "aacgm_mlt" begin
    using Dates, GeoCotrans
    t = DateTime(2021, 4, 20, 0, 56)
    # subsolar point at 700 km is noon by definition; antipode is midnight
    s = 7071.2 .* gei2geo(GeoCotrans.calc_sun_gei(t), t)
    @test aacgm_mlt(s, t) ≈ 12 atol = 1e-6
    midnight = aacgm_mlt(-s, t)
    @test min(midnight, 24 - midnight) < 0.05
    # ELFIN-A position (GEO, km) at 2021-04-20 00:56 UT, L≈7.2 nightside:
    # AACGM MLT ≈ 3.3 matches SPEDAS mlt_v2 for this pass.
    r = [1359.9, 2960.5, -5988.8]
    @test 3.1 < aacgm_mlt(r, t) < 3.5
    # MLT is model-dependent: dipole MLT is over an hour later here.
    @test get_mlt(r, t) - aacgm_mlt(r, t) ≈ 1.1 atol = 0.05
    @test aacgm_mlt(45.0, t) ≈ aacgm_mlt(30.0, t) + 1
end
