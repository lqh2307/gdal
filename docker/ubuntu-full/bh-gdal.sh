#!/bin/sh

set -eu

git clone --recurse-submodules --single-branch -b ${GDAL_VERSION} https://github.com/${GDAL_REPOSITORY}.git

cd gdal

export CFLAGS="-DPROJ_RENAME_SYMBOLS -O2 -g"
export CXXFLAGS="-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2 -g -Wno-psabi"

mkdir -p build && cd build

export GDAL_CMAKE_EXTRA_OPTS="-DBUILD_JAVA_BINDINGS=ON -DJAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64"

if echo ${WITH_FILEGDB} | grep -Eiq "^(y(es)?|1|true)$" ; then
    ln -s /usr/local/FileGDB_API/lib/libFileGDBAPI.so /usr/lib/x86_64-linux-gnu
    export GDAL_CMAKE_EXTRA_OPTS="${GDAL_CMAKE_EXTRA_OPTS} -DFileGDB_ROOT:PATH=/usr/local/FileGDB_API -DFileGDB_LIBRARY:FILEPATH=/usr/lib/x86_64-linux-gnu/libFileGDBAPI.so"
    export LD_LIBRARY_PATH=/usr/local/FileGDB_API/lib:${LD_LIBRARY_PATH:-}
fi

cmake .. \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DGDAL_FIND_PACKAGE_PROJ_MODE=MODULE \
    -DBUILD_TESTING=OFF \
    -DPROJ_INCLUDE_DIR=/build/usr/local/include \
    -DPROJ_LIBRARY=/build/usr/local/lib/libinternalproj.so \
    -DGDAL_ENABLE_PLUGINS=ON \
    -DGDAL_USE_TIFF_INTERNAL=ON \
    -DBUILD_PYTHON_BINDINGS=ON \
    -DGDAL_USE_GEOTIFF_INTERNAL=ON ${GDAL_CMAKE_EXTRA_OPTS} \
    -DOpenDrive_DIR=/usr/lib/ \
    -DOGR_ENABLE_DRIVER_XODR_PLUGIN=TRUE \
ninja
DESTDIR=/build ninja install

cd ..

rm -rf gdal

mkdir -p /build_gdal_python/usr/lib /build_gdal_python/usr/bin /build_gdal_version_changing/usr/include

mv /build/usr/lib/python3            /build_gdal_python/usr/lib
mv /build/usr/lib                    /build_gdal_version_changing/usr
mv /build/usr/include/gdal_version.h /build_gdal_version_changing/usr/include
mv /build/usr/bin/*.py               /build_gdal_python/usr/bin
mv /build/usr/bin                    /build_gdal_version_changing/usr

for P in /build_gdal_version_changing/usr/lib/x86_64-linux-gnu/*; do x86_64-linux-gnu-strip -s ${P} 2>/dev/null || /bin/true; done
for P in /build_gdal_version_changing/usr/lib/x86_64-linux-gnu/gdalplugins/*; do x86_64-linux-gnu-strip -s ${P} 2>/dev/null || /bin/true; done
for P in /build_gdal_python/usr/lib/python3/dist-packages/osgeo/*.so; do x86_64-linux-gnu-strip -s ${P} 2>/dev/null || /bin/true; done
for P in /build_gdal_version_changing/usr/bin/*; do x86_64-linux-gnu-strip -s ${P} 2>/dev/null || /bin/true; done
