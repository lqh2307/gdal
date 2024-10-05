#!/bin/sh

set -eu

if [ "${GDAL_VERSION}" = "master" ]; then
  export GDAL_VERSION=$(curl -Ls https://api.github.com/repos/${GDAL_REPOSITORY}/commits/HEAD -H "Accept: application/vnd.github.VERSION.sha")
  export GDAL_RELEASE_DATE=$(date "+%Y%m%d")
fi

if [ -z "${GDAL_BUILD_IS_RELEASE:-}" ]; then
  export GDAL_SHA1SUM=${GDAL_VERSION}
fi

wget -q https://github.com/${GDAL_REPOSITORY}/archive/${GDAL_VERSION}.tar.gz && tar xzf ${GDAL_VERSION}.tar.gz

cd gdal-${GDAL_VERSION}

export CFLAGS="-DPROJ_RENAME_SYMBOLS -O2 -g"
# -Wno-psabi avoid 'note: parameter passing for argument of type 'std::pair<double, double>' when C++17 is enabled changed to match C++14 in GCC 10.1' on arm64
export CXXFLAGS="-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2 -g -Wno-psabi"

# GDAL_USE_TIFF_INTERNAL=ON to use JXL
export GDAL_CMAKE_EXTRA_OPTS=""
if test "${GCC_ARCH}" != "x86_64"; then
  export GDAL_CMAKE_EXTRA_OPTS="${GDAL_CMAKE_EXTRA_OPTS} -DPDFIUM_INCLUDE_DIR="
fi

export JAVA_ARCH=""
if test "${GCC_ARCH}" = "x86_64"; then
  export JAVA_ARCH="amd64";
elif test "${GCC_ARCH}" = "aarch64"; then
  export JAVA_ARCH="arm64";
fi

if test "${JAVA_ARCH:-}" != ""; then
  export GDAL_CMAKE_EXTRA_OPTS="${GDAL_CMAKE_EXTRA_OPTS} -DBUILD_JAVA_BINDINGS=ON -DJAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-${JAVA_ARCH}"
fi

ln -s /usr/local/FileGDB_API/lib/libFileGDBAPI.so /usr/lib/x86_64-linux-gnu
export GDAL_CMAKE_EXTRA_OPTS="${GDAL_CMAKE_EXTRA_OPTS} -DFileGDB_ROOT:PATH=/usr/local/FileGDB_API -DFileGDB_LIBRARY:FILEPATH=/usr/lib/x86_64-linux-gnu/libFileGDBAPI.so"
export LD_LIBRARY_PATH=/usr/local/FileGDB_API/lib:${LD_LIBRARY_PATH:-}

mkdir -p build && cd build

cmake .. \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DGDAL_FIND_PACKAGE_PROJ_MODE=MODULE \
  -DPROJ_INCLUDE_DIR=/build/usr/local/include \
  -DPROJ_LIBRARY=/build/usr/local/lib/libinternalproj.so \
  -DGDAL_ENABLE_PLUGINS=ON \
  -DGDAL_USE_TIFF_INTERNAL=ON \
  -DBUILD_PYTHON_BINDINGS=ON \
  -DGDAL_USE_GEOTIFF_INTERNAL=ON ${GDAL_CMAKE_EXTRA_OPTS} \
  -DOpenDrive_DIR=/usr/lib/ \
  -DOGR_ENABLE_DRIVER_XODR_PLUGIN=TRUE
make "-j$(nproc)"
make install DESTDIR="/build"

cd ..

rm -rf gdal-${GDAL_VERSION} ${GDAL_VERSION}.tar.gz

mkdir -p /build_gdal_python/usr/lib /build_gdal_python/usr/bin /build_gdal_version_changing/usr/include
mv /build/usr/lib/python3            /build_gdal_python/usr/lib
mv /build/usr/lib                    /build_gdal_version_changing/usr
mv /build/usr/include/gdal_version.h /build_gdal_version_changing/usr/include
mv /build/usr/bin/*.py               /build_gdal_python/usr/bin
mv /build/usr/bin                    /build_gdal_version_changing/usr

for P in "/build_gdal_version_changing/usr/lib/${GCC_ARCH}-linux-gnu"/*; do ${GCC_ARCH}-linux-gnu-strip -s "$P" 2>/dev/null || /bin/true; done
for P in "/build_gdal_version_changing/usr/lib/${GCC_ARCH}-linux-gnu"/gdalplugins/*; do ${GCC_ARCH}-linux-gnu-strip -s "$P" 2>/dev/null || /bin/true; done
for P in /build_gdal_python/usr/lib/python3/dist-packages/osgeo/*.so; do ${GCC_ARCH}-linux-gnu-strip -s "$P" 2>/dev/null || /bin/true; done
for P in /build_gdal_version_changing/usr/bin/*; do ${GCC_ARCH}-linux-gnu-strip -s "$P" 2>/dev/null || /bin/true; done
