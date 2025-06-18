using Documenter
using GeoAACGM

DocMeta.setdocmeta!(GeoAACGM, :DocTestSetup, :(using GeoAACGM; using PrettyPrinting); recursive = true)

makedocs(
    sitename = "GeoAACGM.jl",
    format = Documenter.HTML(),
    modules = [GeoAACGM],
    pages = [
        "Home" => "index.md",
    ],
    checkdocs = :exports,
    doctest = true
)

deploydocs(
    repo = "github.com/JuliaSpacePhysics/GeoAACGM.jl",
    push_preview = true
)
