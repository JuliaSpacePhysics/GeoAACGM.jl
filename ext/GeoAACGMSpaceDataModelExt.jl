module GeoAACGMSpaceDataModelExt
using GeoAACGM
using SpaceDataModel: unwrap, getdim, tdimnum
import GeoAACGM: geo2aacgm

function GeoAACGM.geo2aacgm(x; dim = nothing)
    out = similar(x)
    dim = @something dim tdimnum(x)
    times = unwrap(getdim(x, dim))
    map!(
        GeoAACGM.geo2aacgm,
        eachslice(out; dims = dim),
        eachslice(x; dims = dim),
        times,
    )
    return out
end
end
