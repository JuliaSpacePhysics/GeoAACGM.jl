const RE = 6371.2  # Earth Radius in km
const MAXALT = 2000.  # maximum altitude in km
const NCOORD = 3  # xyz coordinates
const POLYORD = 5  # quartic polynomial fit in altitude
const SHORDER = 10  # order of Spherical Harmonic expansion
const AACGM_KMAX = (SHORDER + 1) * (SHORDER + 1)  # number of SH coefficients
