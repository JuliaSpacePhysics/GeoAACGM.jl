module GeoAACGMGeoCotransExt
using GeoAACGM
using GeoAACGM: geo2aacgm
using GeoCotrans: gei2geo
import GeoAACGM: gei2aacgm

GeoAACGM.gei2aacgm(x; dim = nothing) = geo2aacgm(gei2geo(x); dim)
end
