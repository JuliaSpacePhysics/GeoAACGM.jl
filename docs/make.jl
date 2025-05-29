using Documenter
using Aacgm

DocMeta.setdocmeta!(Aacgm, :DocTestSetup, :(using Aacgm; using PrettyPrinting); recursive=true)

makedocs(
    sitename="Aacgm.jl",
    format=Documenter.HTML(),
    modules=[Aacgm],
    pages=[
        "Home" => "index.md",
    ],
    checkdocs=:exports,
    doctest=true
)

deploydocs(
    repo="github.com/Beforerr/Aacgm.jl",
)
