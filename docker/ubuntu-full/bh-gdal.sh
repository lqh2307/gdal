#!/bin/sh
set -eu

if [ "${GDAL_VERSION}" = "master" ]; then
    GDAL_VERSION=$(curl -Ls https://api.github.com/repos/${GDAL_REPOSITORY}/commits/HEAD -H "Accept: application/vnd.github.VERSION.sha")
    export GDAL_VERSION
    GDAL_RELEASE_DATE=$(date "+%Y%m%d")
    export GDAL_RELEASE_DATE
fi

if [ -z "${GDAL_BUILD_IS_RELEASE:-}" ]; then
    export GDAL_SHA1SUM=${GDAL_VERSION}
fi

mkdir gdal
curl -L -fsS "https://github.com/${GDAL_REPOSITORY}/archive/${GDAL_VERSION}.tar.gz" \
    | tar xz -C gdal --strip-components=1



(
    cd gdal

    if test "${RSYNC_REMOTE:-}" != ""; then
        echo "Downloading cache..."
        rsync -ra "${RSYNC_REMOTE}/gdal/x86_64/" "$HOME/.cache/"
        echo "Finished"
    fi
    if [ -n "${WITH_CCACHE:-}" ]; then
        # Little trick to avoid issues with Python bindings
        printf "#!/bin/sh\nccache %s-linux-gnu-gcc \$*" "x86_64" > ccache_gcc.sh
        chmod +x ccache_gcc.sh
        printf "#!/bin/sh\nccache %s-linux-gnu-g++ \$*" "x86_64" > ccache_g++.sh
        chmod +x ccache_g++.sh
        export CC=$PWD/ccache_gcc.sh
        export CXX=$PWD/ccache_g++.sh

        ccache -M 1G
    fi

    export CFLAGS="-DPROJ_RENAME_SYMBOLS -O2 -g"
    # -Wno-psabi avoid 'note: parameter passing for argument of type 'std::pair<double, double>' when C++17 is enabled changed to match C++14 in GCC 10.1' on arm64
    export CXXFLAGS="-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2 -g -Wno-psabi"

    mkdir build
    cd build

    export GDAL_CMAKE_EXTRA_OPTS="${GDAL_CMAKE_EXTRA_OPTS} -DBUILD_JAVA_BINDINGS=ON -DJAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64"

    if echo "$WITH_FILEGDB" | grep -Eiq "^(y(es)?|1|true)$" ; then
      ln -s /usr/local/FileGDB_API/lib/libFileGDBAPI.so /usr/lib/x86_64-linux-gnu
      export GDAL_CMAKE_EXTRA_OPTS="${GDAL_CMAKE_EXTRA_OPTS} -DFileGDB_ROOT:PATH=/usr/local/FileGDB_API -DFileGDB_LIBRARY:FILEPATH=/usr/lib/x86_64-linux-gnu/libFileGDBAPI.so"
      export LD_LIBRARY_PATH=/usr/local/FileGDB_API/lib:${LD_LIBRARY_PATH:-}
    fi

    cmake .. \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DGDAL_FIND_PACKAGE_PROJ_MODE=MODULE \
        -DBUILD_TESTING=OFF \
        -DPROJ_INCLUDE_DIR="/build${PROJ_INSTALL_PREFIX-/usr/local}/include" \
        -DPROJ_LIBRARY="/build${PROJ_INSTALL_PREFIX-/usr/local}/lib/libinternalproj.so" \
        -DGDAL_ENABLE_PLUGINS=ON \
        -DGDAL_USE_TIFF_INTERNAL=ON \
        -DBUILD_PYTHON_BINDINGS=ON \
        -DGDAL_USE_GEOTIFF_INTERNAL=ON ${GDAL_CMAKE_EXTRA_OPTS} \
        -DOpenDrive_DIR=/usr/lib/ \
        -DOGR_ENABLE_DRIVER_XODR_PLUGIN=TRUE \

    ninja
    DESTDIR="/build" ninja install

    cd ..

    if [ -n "${RSYNC_REMOTE:-}" ]; then
        echo "Uploading cache..."
        rsync -ra --delete "$HOME/.cache/" "${RSYNC_REMOTE}/gdal/x86_64/"
        echo "Finished"
    fi
    if [ -n "${WITH_CCACHE:-}" ]; then
        ccache -s
        unset CC
        unset CXX
    fi
)

rm -rf gdal
mkdir -p /build_gdal_python/usr/lib /build_gdal_python/usr/bin /build_gdal_version_changing/usr/include
mv /build/usr/lib/python3            /build_gdal_python/usr/lib
mv /build/usr/lib                    /build_gdal_version_changing/usr
mv /build/usr/include/gdal_version.h /build_gdal_version_changing/usr/include
mv /build/usr/bin/*.py               /build_gdal_python/usr/bin
mv /build/usr/bin                    /build_gdal_version_changing/usr

for P in "/build_gdal_version_changing/usr/lib/x86_64-linux-gnu"/*; do x86_64-linux-gnu-strip -s "$P" 2>/dev/null || /bin/true; done
for P in "/build_gdal_version_changing/usr/lib/x86_64-linux-gnu"/gdalplugins/*; do x86_64-linux-gnu-strip -s "$P" 2>/dev/null || /bin/true; done
for P in /build_gdal_python/usr/lib/python3/dist-packages/osgeo/*.so; do x86_64-linux-gnu-strip -s "$P" 2>/dev/null || /bin/true; done
for P in /build_gdal_version_changing/usr/bin/*; do x86_64-linux-gnu-strip -s "$P" 2>/dev/null || /bin/true; done
