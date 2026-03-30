download:
    #!/usr/bin/env sh
    wget https://superdarn.thayer.dartmouth.edu/aacgm/c_aacgm_v2.7.tar
    mkdir -p c_aacgm_v2.7
    tar -xf c_aacgm_v2.7.tar -C c_aacgm_v2.7
    rm c_aacgm_v2.7.tar

install: download
    #!/usr/bin/env sh
    export AACGM_v2_DAT_PREFIX="$(pwd)/data/aacgm_coeffs-14/aacgm_coeffs-14-"
    export IGRF_COEFFS="$(pwd)/c_aacgm_v2.7/magmodel_1590-2025.txt"
    cd c_aacgm_v2.7
    gcc -fPIC -shared -o aacgmlib.so aacgmlib_v2.c astalglib.c igrflib.c mlt_v2.c rtime.c -lm
    install aacgmlib.so ../LibAACGM/aacgmlib.so

test: install
    #!/usr/bin/env sh
    export AACGM_v2_DAT_PREFIX="$(pwd)/data/aacgm_coeffs-14/aacgm_coeffs-14-"
    export IGRF_COEFFS="$(pwd)/c_aacgm_v2.7/magmodel_1590-2025.txt"
    cd c_aacgm_v2.7
    gcc -o test_aacgm test_aacgm.c aacgmlib_v2.c igrflib.c astalglib.c mlt_v2.c rtime.c -lm
    
uninstall:
    rm /usr/local/lib/aacgmlib.so