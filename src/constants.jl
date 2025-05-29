const RE = 6371.2  # Earth Radius in km
const MAXALT = 2000.  # maximum altitude in km
const NCOORD = 3  # xyz coordinates
const POLYORD = 5  # quartic polynomial fit in altitude
const SHORDER = 10  # order of Spherical Harmonic expansion
const AACGM_KMAX = (SHORDER + 1) * (SHORDER + 1)  # number of SH coefficients

const EARTH_A = 6378.1370             # semi-major axis in km
const EARTH_F = 1.0 / 298.257223563     # flattening
const EARTH_B = EARTH_A * (1.0 - EARTH_F)  # semi-minor axis
const EARTH_A2 = EARTH_A * EARTH_A
const EARTH_B2 = EARTH_B * EARTH_B
const EARTH_A2_B2_DIFF = EARTH_A2 - EARTH_B2
