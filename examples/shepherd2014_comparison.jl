using CairoMakie
using Dates
using GeoAACGM
using GeoCotrans: Cartesian3, GEO, MAG, R🜨, sphd2car, trace, transform
using LinearAlgebra
using OrdinaryDiffEqTsit5: Tsit5

wrap180(λ) = mod(λ + 180, 360) - 180

function great_circle_error_km(lat1, lon1, lat2, lon2, r)
    any(isnan, (lat1, lon1, lat2, lon2)) && return NaN
    φ1, φ2 = deg2rad(lat1), deg2rad(lat2)
    Δφ = φ2 - φ1
    Δλ = deg2rad(wrap180(lon2 - lon1))
    a = sin(Δφ / 2)^2 + cos(φ1) * cos(φ2) * sin(Δλ / 2)^2
    return R🜨 * r * 2asin(sqrt(clamp(a, 0, 1)))
end

function dipole_equator_crossing(pos, time; solver = Tsit5(), kwargs...)
    in = (GEO(), Cartesian3())
    for dir in (-1, 1)
        sol = trace(
            pos, time, solver; dir, in, r0 = 0.2, rlim = 200.0, maxs = 2000.0,
            save_everystep = true, reltol = 1.0e-7, abstol = 1.0e-9, kwargs...
        )
        for i in 1:(length(sol.u) - 1)
            if norm(sol.u[i]) < 1 - 1.0e-4
                break
            end
            z0 = transform(MAG, GEO, sol.u[i], time)[3]
            z1 = transform(MAG, GEO, sol.u[i + 1], time)[3]
            z0 == 0 && return sol.u[i]
            if z0 * z1 <= 0
                α = abs(z0) / (abs(z0) + abs(z1))
                crossing = (1 - α) * sol.u[i] + α * sol.u[i + 1]
                norm(crossing) < 1 - 1.0e-4 && break
                return crossing
            end
        end
    end
    return nothing
end

function traced_aacgm(lat, lon, height, time; kwargs...)
    r = (R🜨 + height) / R🜨
    pos = sphd2car(r, 90 - lat, lon)
    crossing = dipole_equator_crossing(pos, time; kwargs...)
    isnothing(crossing) && return (NaN, NaN, r)
    mag0 = transform(MAG, GEO, pos, time)
    mag_eq = transform(MAG, GEO, crossing, time)
    L = norm(mag_eq)
    L < r && return (NaN, NaN, r)
    mlat = sign(iszero(mag0[3]) ? lat : mag0[3]) * acosd(sqrt(clamp(r / L, 0, 1)))
    mlon = wrap180(rad2deg(atan(mag_eq[2], mag_eq[1])))
    return (mlat, mlon, r)
end

function coefficient_tracing_error_grid(lats, lons, height, time; kwargs...)
    errors = Matrix{Float64}(undef, length(lons), length(lats))
    for (j, lat) in pairs(lats), (i, lon) in pairs(lons)
        coeff = geoc2aacgm(lat, lon, height, time)
        traced = traced_aacgm(lat, lon, height, time; kwargs...)
        errors[i, j] = great_circle_error_km(coeff[1], coeff[2], traced[1], traced[2], traced[3])
    end
    return errors
end

shepherd_colormap() = cgrad(
    [
        colorant"black", colorant"#2e0048", colorant"purple",
        colorant"blue", colorant"cyan", colorant"green",
        colorant"yellow", colorant"red",
    ]
)

function plot_coefficient_tracing_comparison(;
        times = (DateTime(2000, 1, 1), DateTime(2010, 1, 1)),
        height = 0.0,
        lats = -90:1:90,
        lons = -180:5:180,
        colorrange = (0, 10),
        colormap = shepherd_colormap(),
        kwargs...
    )
    fig = Figure(size = (560 * length(times) + 120, 480))
    hm = nothing
    for (k, time) in pairs(times)
        @info "Computing AACGM coefficient/tracing comparison" height time
        errors = coefficient_tracing_error_grid(lats, lons, height, time; kwargs...)
        ax = Axis(
            fig[1, k], xlabel = "Geographic longitude [deg]", ylabel = "Geographic latitude [deg]",
            title = "$(year(time)), h = $(round(height; digits = 1)) km",
            xticks = -180:30:180, yticks = -90:30:90,
        )
        hm = heatmap!(
            ax, collect(lons), collect(lats), errors;
            colormap, colorrange, highclip = :white, nan_color = :gray60,
        )
        xlims!(ax, extrema(lons))
        ylims!(ax, extrema(lats))
    end
    Colorbar(fig[1, length(times) + 1], hm, label = "surface error [km]")
    return fig
end
