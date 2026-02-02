using BenchmarkTools
using GeoAACGM
using Dates

const SUITE = BenchmarkGroup()

lat, lon, hgt = 45.5, -23.5, 1135
dt = DateTime(2029, 3, 22, 3, 11)

SUITE["single"] = BenchmarkGroup()
SUITE["single"]["geod2aacgm_with_dt"] = @benchmarkable geod2aacgm($lat, $lon, $hgt, $dt)
SUITE["single"]["geod2aacgm_preset"] = @benchmarkable geod2aacgm($lat, $lon, $hgt) setup = (set_coefficients!($dt))
SUITE["single"]["geoc2aacgm_with_dt"] = @benchmarkable geoc2aacgm($lat, $lon, $hgt, $dt)
SUITE["single"]["geoc2aacgm_preset"] = @benchmarkable geoc2aacgm($lat, $lon, $hgt) setup = (set_coefficients!($dt))

n = 10
glats = 45 .+ rand(n)
glons = -23 .+ rand(n)
hights = 1000 .+ 10 * rand(n)
dts = dt .+ Second.(rand(Int8, n))

SUITE["multiple"] = BenchmarkGroup()
SUITE["multiple"]["geoc2aacgm_with_dts"] = @benchmarkable geoc2aacgm.($glats, $glons, $hights, $dts)
SUITE["multiple"]["geoc2aacgm_preset"] = @benchmarkable geoc2aacgm.($glats, $glons, $hights) setup = (set_coefficients!($dt))
