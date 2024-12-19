#!/bin/bash

# Copyright 2024 Dmitry Arkhipov (grisumbras@yandex.ru)
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE.txt or copy at http://boost.org/LICENSE_1_0.txt)

set -e
export DRONE_BUILD_DIR=$(pwd)
export DRONE_BRANCH=${DRONE_BRANCH:-$(echo $GITHUB_REF | cut -d/ -f3-)}
export CC=${CC:-gcc}
export PATH=/.local/bin:$HOME/.local/bin:/usr/local/bin:$PATH

common_install () {
    export SELF=`basename $DRONE_REPO`
}

b2_job () {
    echo '==================================> INSTALL'

    common_install

    BOOST_BRANCH=develop && [ "$DRONE_BRANCH" == "master" ] && BOOST_BRANCH=master || true
    git clone -b $BOOST_BRANCH https://github.com/boostorg/build.git boost-build --depth 1
    pushd boost-build
    ./bootstrap.sh
    ./b2 install --prefix="$HOME/.local"
    popd

    echo '==================================> SCRIPT'

    echo "using gcc ;" > project-config.jam
    echo "using python : : python3 ;" >> project-config.jam
    echo "project : build-dir build ;" >> project-config.jam

    export B2_TARGETS=${B2_TARGETS:-"test example"}
    b2 ${B2_TARGETS} variant=debug warnings=extra warnings-as-errors=on ${B2_FLAGS}
}

cmake_variation () {
    : ${variation_link:-static}
    : ${target:-tests}
    build_dir=build/${variation_link}
    mkdir -p ${build_dir}
    pushd ${build_dir}

    BUILD_SHARED_LIBS=
    if [ "$variation_link" == "shared" ]; then
        BUILD_SHARED_LIBS="-DBUILD_SHARED_LIBS=ON"
    fi

    cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON ${BUILD_SHARED_LIBS} \
        "-DCMAKE_MODULE_PATH=$boost_debugger_utils" ${CMAKE_OPTIONS} ../..
    cmake --build . --target "${target}"
    ctest --output-on-failure
    popd
}

cmake_job () {
    echo '==================================> INSTALL'

    common_install

    echo '==================================> SCRIPT'

    export CXXFLAGS="-Wall -Wextra -Werror"
    variation_link=static boost_debugger_utils=$PWD cmake_variation
    variation_link=shared boost_debugger_utils=$PWD cmake_variation

    cd example
    variation_link=shared boost_debugger_utils=$PWD/.. target=all cmake_variation
    variation_link=static boost_debugger_utils=$PWD/.. target=all cmake_variation
}

if [ "$DRONE_JOB_BUILDTYPE" == "b2" ]; then
    b2_job
elif [ "$DRONE_JOB_BUILDTYPE" == "cmake" ]; then
    cmake_job
fi
