# Aacgm.jl

```@docs
Aacgm
```

# API Reference

## Exported functions

```@autodocs
Modules = [Aacgm]
Private = false
Order = [:function]
```

## Private functions

```@autodocs
Modules = [Aacgm]
Public = false
Order = [:function]
```


# Validation and Benchmark

!!! note

    It is preferable to use the `geo2aacgm.(glats, glons, hights, times)` interface compared to manually setting the coefficients with `set_coefficients!` and then using `geo2aacgm(glat, glon, hight)`. The former is simpler and ensures accuracy with negligible performance loss due to lazy interpolation.

## Single Time Conversion

```@example share
using Aacgm, LibAacgm
using Dates
using Test, Chairmarks

# Helper function to compare element-wise
is_approx_v(x, y; kw...) = length(x) == 1 ? isapprox(x, y; kw...) : all(is_approx_v.(x, y; kw...))

lat, lon, hgt = 45.5, -23.5, 1135
dt = DateTime(2029, 3, 22, 3, 11)

LibAacgm.AACGM_v2_SetDateTime(dt)
c_result = LibAacgm.AACGM_v2_Convert(lat, lon, hgt, 0)
set_coefficients!(dt)
jl_result = geod2aacgm(lat, lon, hgt, dt)

# Validation
@assert is_approx_v(jl_result, c_result, atol=1e-4)
# Benchmark
@b geod2aacgm(lat, lon, hgt, dt), geod2aacgm(lat, lon, hgt), LibAacgm.AACGM_v2_Convert(lat, lon, hgt, 0)
```

The Julia implementation yields results comparable to the C implementation but runs approximately twice as fast (for preset coefficients). 
The slight discrepancy in the output arises from Julia’s use of a more precise interpolation of the coefficients compared to that used in the C version.

## Multiple Time Conversion

When times are close to each other, it may be faster to set the time just once and perform the coordinate transformation multiple times.


```@example share
n = 10
glats = 45 .+ rand(n)
glons = -23 .+ rand(n)
hights = 1000 .+ 10 * rand(n)
dts = dt .+ Second.(rand(Int8, n))

set_coefficients!(dt)
res1 = geoc2aacgm.(glats, glons, hights, dts)
res2 = geoc2aacgm.(glats, glons, hights)

@assert is_approx_v(res1, res2; atol=1e-6)
@b geoc2aacgm.(glats, glons, hights, dts), geoc2aacgm.(glats, glons, hights)
```

However, for far-apart times, it is better to use the exact time for each conversion.
And lazy interpolation provides a performance boost.

```@example share
dts = dt .+ Second.(rand(Int16, n))

res1 = geoc2aacgm.(glats, glons, hights, dts)
res2 = geoc2aacgm.(glats, glons, hights)

# Results are not the same, it is better to set the datetime for each conversion
@test !is_approx_v(res1, res2) 

slow_geoc2aacgm(glat, glon, hight, dt) = begin
    set_coefficients!(dt)
    geoc2aacgm(glat, glon, hight)
end

@assert is_approx_v(geoc2aacgm.(glats, glons, hights, dts), slow_geoc2aacgm.(glats, glons, hights, dts))
@b geoc2aacgm.(glats, glons, hights, dts), slow_geoc2aacgm.(glats, glons, hights, dts)
```
