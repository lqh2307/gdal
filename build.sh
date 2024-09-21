#!/bin/bash

# set -e  # Exit immediately if a command exits with a non-zero status

# Set proxy
# http_proxy=http://10.55.123.98:3333
# https_proxy=http://10.55.123.98:3333

# Set env
export TARGET_ARCH=""
export JAVA_VERSION="17"
export GCC_ARCH="amd64"
export KEA_VERSION="1.5.2"
export MONGO_C_DRIVER_VERSION="1.24.4"
export MONGOCXX_VERSION="3.8.1"
export TILEDB_VERSION="2.23.0"
export OPENJPEG_VERSION=""
export OPENDRIVE_VERSION="0.6.0-gdal"
export WITH_FILEGDB=""
export WITH_PDFIUM="yes"
export ARROW_VERSION="16.1.0-1"
export ARROW_SOVERSION="1600"
export PROJ_INSTALL_PREFIX="/usr/local"
export PROJ_VERSION="master"
export GDAL_VERSION="master"
export GDAL_REPOSITORY="OSGeo/gdal"
export WITH_DEBUG_SYMBOLS="no"

./docker/ubuntu-full/bh-set-envvars.sh

if [ -n "${TARGET_ARCH}" ]; then
  rm -rf /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources
  echo "deb [arch=amd64] http://us.archive.ubuntu.com/ubuntu/ noble main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=amd64] http://us.archive.ubuntu.com/ubuntu/ noble-updates main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=amd64] http://us.archive.ubuntu.com/ubuntu/ noble-backports main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu noble-security main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=${TARGET_ARCH}] http://ports.ubuntu.com/ubuntu-ports/ noble main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=${TARGET_ARCH}] http://ports.ubuntu.com/ubuntu-ports/ noble-updates main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=${TARGET_ARCH}] http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe" >> /etc/apt/sources.list
  dpkg --add-architecture ${TARGET_ARCH}
  apt-get update -y && apt-get install -y \
    g++-13-${GCC_ARCH}-linux-gnu
  ln -s ${GCC_ARCH}-linux-gnu-gcc-13 /usr/bin/${GCC_ARCH}-linux-gnu-gcc
  ln -s ${GCC_ARCH}-linux-gnu-g++-13 /usr/bin/${GCC_ARCH}-linux-gnu-g++
fi

# Setup build env for PROJ & GDAL
apt-get update -y && apt-get install -y \
  libopenjp2-7-dev${APT_ARCH_SUFFIX} \
  libcairo2-dev${APT_ARCH_SUFFIX} \
  python3-dev${APT_ARCH_SUFFIX} \
  python3-numpy${APT_ARCH_SUFFIX} \
  python3-setuptools${APT_ARCH_SUFFIX} \
  libpng-dev${APT_ARCH_SUFFIX} \
  libjpeg-dev${APT_ARCH_SUFFIX} \
  libgif-dev${APT_ARCH_SUFFIX} \
  liblzma-dev${APT_ARCH_SUFFIX} \
  libgeos-dev${APT_ARCH_SUFFIX} \
  curl libxml2-dev${APT_ARCH_SUFFIX} \
  libexpat-dev${APT_ARCH_SUFFIX} \
  libxerces-c-dev${APT_ARCH_SUFFIX} \
  libnetcdf-dev${APT_ARCH_SUFFIX} \
  libpoppler-dev${APT_ARCH_SUFFIX} \
  libpoppler-private-dev${APT_ARCH_SUFFIX} \
  libspatialite-dev${APT_ARCH_SUFFIX} \
  librasterlite2-dev${APT_ARCH_SUFFIX} \
  libhdf4-alt-dev${APT_ARCH_SUFFIX} \
  libhdf5-serial-dev${APT_ARCH_SUFFIX} \
  libfreexl-dev${APT_ARCH_SUFFIX} \
  unixodbc-dev${APT_ARCH_SUFFIX} \
  mdbtools-dev${APT_ARCH_SUFFIX} \
  libwebp-dev${APT_ARCH_SUFFIX} \
  libpcre3-dev${APT_ARCH_SUFFIX} \
  libcrypto++-dev${APT_ARCH_SUFFIX} \
  libfyba-dev${APT_ARCH_SUFFIX} \
  libkml-dev${APT_ARCH_SUFFIX} \
  libmysqlclient-dev${APT_ARCH_SUFFIX} \
  libogdi-dev${APT_ARCH_SUFFIX} \
  libcfitsio-dev${APT_ARCH_SUFFIX} \
  openjdk-"$JAVA_VERSION"-jdk${APT_ARCH_SUFFIX} \
  libzstd-dev${APT_ARCH_SUFFIX} \
  libpq-dev${APT_ARCH_SUFFIX} \
  libssl-dev${APT_ARCH_SUFFIX} \
  libboost-dev${APT_ARCH_SUFFIX} \
  libarmadillo-dev${APT_ARCH_SUFFIX} \
  libopenexr-dev${APT_ARCH_SUFFIX} \
  libheif-dev${APT_ARCH_SUFFIX} \
  libdeflate-dev${APT_ARCH_SUFFIX} \
  libblosc-dev${APT_ARCH_SUFFIX} \
  liblz4-dev${APT_ARCH_SUFFIX} \
  libbz2-dev${APT_ARCH_SUFFIX} \
  libbrotli-dev${APT_ARCH_SUFFIX} \
  libarchive-dev${APT_ARCH_SUFFIX} \
  libaec-dev${APT_ARCH_SUFFIX} \
  libavif-dev${APT_ARCH_SUFFIX} \
  libspdlog-dev${APT_ARCH_SUFFIX} \
  libmagic-dev${APT_ARCH_SUFFIX} \
  zlib1g-dev${APT_ARCH_SUFFIX} \
  libsqlite3-dev${APT_ARCH_SUFFIX} \
  libcurl4-openssl-dev${APT_ARCH_SUFFIX} \
  libtiff-dev${APT_ARCH_SUFFIX} \
  libgflags-dev${APT_ARCH_SUFFIX} \
  swig ant liblcms2-2 \
  autoconf automake bash-completion \
  build-essential ca-certificates lsb-release \
  pkg-config sqlite3 git cmake \
  wget unzip libtool rsync ccache

# Build likbkea
wget -q https://github.com/ubarsc/kealib/archive/kealib-${KEA_VERSION}.zip
unzip -q kealib-${KEA_VERSION}.zip
cd kealib-kealib-${KEA_VERSION}
cmake . -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DHDF5_INCLUDE_DIR=/usr/include/hdf5/serial \
  -DHDF5_LIB_PATH=/usr/lib/${GCC_ARCH}-linux-gnu/hdf5/serial \
  -DLIBKEA_WITH_GDAL=OFF
make -j$(nproc)
make install
cd ..
rm -rf kealib-kealib-${KEA_VERSION} kealib-${KEA_VERSION}.zip
for i in /build_thirdparty/usr/lib/*; do strip -s $i 2>/dev/null || /bin/true; done
for i in /build_thirdparty/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

# Build mongo-c-driver
wget -q https://github.com/mongodb/mongo-c-driver/releases/download/${MONGO_C_DRIVER_VERSION}/mongo-c-driver-${MONGO_C_DRIVER_VERSION}.tar.gz
tar xzf mongo-c-driver-${MONGO_C_DRIVER_VERSION}.tar.gz
cd mongo-c-driver-${MONGO_C_DRIVER_VERSION}
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DENABLE_TESTS=NO
make -j$(nproc)
make install DESTDIR=/build_thirdparty
make install
cd ../..
rm -rf mongo-c-driver-${MONGO_C_DRIVER_VERSION} mongo-c-driver-${MONGO_C_DRIVER_VERSION}.tar.gz /build_thirdparty/usr/lib/${GCC_ARCH}-linux-gnu/*.a
for i in /build_thirdparty/usr/lib/${GCC_ARCH}-linux-gnu/*; do strip -s $i 2>/dev/null || /bin/true; done
for i in /build_thirdparty/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

# Build mongocxx
wget -q https://github.com/mongodb/mongo-cxx-driver/archive/r${MONGOCXX_VERSION}.tar.gz
tar xzf r${MONGOCXX_VERSION}.tar.gz
cd mongo-cxx-driver-r${MONGOCXX_VERSION}
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DBSONCXX_POLY_USE_BOOST=ON \
  -DENABLE_TESTS=OFF \
  -DMONGOCXX_ENABLE_SLOW_TESTS=NO \
  -DBUILD_VERSION=${MONGOCXX_VERSION}
make -j$(nproc)
make install DESTDIR=/build_thirdparty
make install
cd ../..
rm -rf mongo-cxx-driver-r${MONGOCXX_VERSION} r${MONGOCXX_VERSION}.tar.gz
for i in /build_thirdparty/usr/lib/${GCC_ARCH}-linux-gnu/*; do strip -s $i 2>/dev/null || /bin/true; done
for i in /build_thirdparty/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

# Build tiledb
wget -q https://github.com/TileDB-Inc/TileDB/archive/${TILEDB_VERSION}.tar.gz
tar xzf ${TILEDB_VERSION}.tar.gz
cd TileDB-${TILEDB_VERSION}
patch -p0 < ../docker/ubuntu-full/tiledb-FindLZ4_EP.cmake.patch
patch -p0 < ../docker/ubuntu-full/tiledb-FindOpenSSL_EP.cmake.patch
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DTILEDB_WERROR=OFF \
  -DTILEDB_SUPERBUILD=OFF \
  -DTILEDB_TESTS=OFF \
  -DCOMPILER_SUPPORTS_AVX2=FALSE \
  -DOPENSSL_INCLUDE_DIR=/usr/include \
  -DOPENSSL_CRYPTO_LIBRARY=/usr/lib/${GCC_ARCH}-linux-gnu/libcrypto.so \
  -DOPENSSL_SSL_LIBRARY=/usr/lib/${GCC_ARCH}-linux-gnu/libssl.so
make -j$(nproc)
make -j$(nproc) install DESTDIR=/build_thirdparty
make -j$(nproc) install
cd ../..
rm -rf TileDB-${TILEDB_VERSION} ${TILEDB_VERSION}.tar.gz
for i in /build_thirdparty/usr/lib/${GCC_ARCH}-linux-gnu/*; do strip -s $i 2>/dev/null || /bin/true; done
for i in /build_thirdparty/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

# Build openjpeg
if [ -n "${OPENJPEG_VERSION}" ]; then
  wget -q https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz
  tar xzf v${OPENJPEG_VERSION}.tar.gz
  cd openjpeg-${OPENJPEG_VERSION}
  cmake . -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=/usr
  make -j$(nproc)
  make install
  mkdir -p /build_thirdparty/usr/lib/${GCC_ARCH}-linux-gnu
  rm -rf /usr/lib/${GCC_ARCH}-linux-gnu/libopenjp2.so*
  mv -f /usr/lib/libopenjp2.so* /usr/lib/${GCC_ARCH}-linux-gnu
  cp -P -rf /usr/lib/${GCC_ARCH}-linux-gnu/libopenjp2.so* /build_thirdparty/usr/lib/${GCC_ARCH}-linux-gnu
  for i in /build_thirdparty/usr/lib/${GCC_ARCH}-linux-gnu/*; do strip -s $i 2>/dev/null || /bin/true; done
  cd ..
  rm -rf openjpeg-${OPENJPEG_VERSION} v${OPENJPEG_VERSION}.tar.gz
fi

# Build libOpenDRIVE
if [ -n "${OPENDRIVE_VERSION}" ]; then
  wget -q https://github.com/DLR-TS/libOpenDRIVE/archive/refs/tags/${OPENDRIVE_VERSION}.tar.gz
  tar xzf ${OPENDRIVE_VERSION}.tar.gz
  cd libOpenDRIVE-${OPENDRIVE_VERSION}
  cmake . -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/
  make -j$(nproc)
  make install
  mkdir -p /build_thirdparty/usr/lib
  cp -P -rf /usr/lib/libOpenDrive*.so* /build_thirdparty/usr/lib
  for i in /build_thirdparty/usr/lib/*; do strip -s $i 2>/dev/null || /bin/true; done
  cd ..
  rm -rf libOpenDRIVE-${OPENDRIVE_VERSION} ${OPENDRIVE_VERSION}.tar.gz
fi

# Build File Geodatabase
if echo "${WITH_FILEGDB}" | grep -Eiq "^(y(es)?|1|true)$"; then
  wget -q https://github.com/Esri/file-geodatabase-api/raw/master/FileGDB_API_1.5.2/FileGDB_API-RHEL7-64gcc83.tar.gz
  tar xzf FileGDB_API-RHEL7-64gcc83.tar.gz
  mv -f FileGDB_API-RHEL7-64gcc83 /usr/local/FileGDB_API
  rm -rf /usr/local/FileGDB_API/lib/libstdc++*
  cp -rf /usr/local/FileGDB_API/lib/* /usr/lib/x86_64-linux-gnu
  cp -rf /usr/local/FileGDB_API/include/* /usr/include
  rm -rf FileGDB_API-RHEL7-64gcc83.tar.gz
fi

# Build libqb3
git clone https://github.com/lucianpls/QB3.git --recursive
cd QB3/QB3lib
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release \
  ${CMAKE_EXTRA_ARGS} \
  -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make -j$(nproc) install
make install DESTDIR=/build_thirdparty
cd ../../..
rm -rf QB3

# Build PDFium
if echo "${WITH_PDFIUM}" | grep -Eiq "^(y(es)?|1|true)$"; then
  wget -q https://github.com/rouault/pdfium_build_gdal_3_10/releases/download/pdfium_6677_v1/install-ubuntu2004-rev6677.tar.gz
  tar xzf install-ubuntu2004-rev6677.tar.gz
  rsync install/lib/ /usr/lib/
  rsync install/include/ /usr/include/
  rm -rf install install-ubuntu2004-rev6677.tar.gz
  apt-get install -y \
    liblcms2-dev${APT_ARCH_SUFFIX}
fi

# Build libjxl
git clone https://github.com/libjxl/libjxl.git --recursive
cd libjxl
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DJPEGXL_ENABLE_JPEGLI_LIBJPEG=OFF \
  -DBUILD_TESTING=OFF \
  -DJPEGXL_ENABLE_TOOLS=OFF \
  -DJPEGXL_ENABLE_BENCHMARK=OFF
make -j$(nproc)
make -j$(nproc) install
make install DESTDIR=/build_thirdparty
cd ../..
rm -rf libjxl /lib/${GCC_ARCH}-linux-gnu/libjxl*.a /build_thirdparty/lib/${GCC_ARCH}-linux-gnu/libjxl*.a

# Install Arrow C++
wget https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
dpkg -i \
  apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
apt-get update && apt-get install -y \
  libarrow${ARROW_SOVERSION}${APT_ARCH_SUFFIX} \
  libparquet${ARROW_SOVERSION}${APT_ARCH_SUFFIX} \
  libarrow-dataset${ARROW_SOVERSION}${APT_ARCH_SUFFIX} \
  libarrow-dev${APT_ARCH_SUFFIX}=${ARROW_VERSION} \
  libparquet-dev${APT_ARCH_SUFFIX}=${ARROW_VERSION} \
  libarrow-acero-dev${APT_ARCH_SUFFIX}=${ARROW_VERSION} \
  libarrow-dataset-dev${APT_ARCH_SUFFIX}=${ARROW_VERSION}
rm -rf apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb

# Install proj_grids & proj
mkdir -p /tmp/proj_grids_build
DESTDIR="/tmp/proj_grids_build" ./docker/ubuntu-full/bh-proj.sh
LD_LIBRARY_PATH="/tmp/proj_grids_build" /tmp/proj_grids_build/usr/local/bin/projsync --target-dir /tmp/proj_grids --all
rm -rf /tmp/proj_grids_build
./docker/ubuntu-full/bh-proj.sh

# Install gdal
./docker/ubuntu-full/bh-gdal.sh

cp -rf /build_thirdparty/usr/ /usr/

cp -rf /tmp/proj_grids/* ${PROJ_INSTALL_PREFIX}/share/proj/

cp -rf /build${PROJ_INSTALL_PREFIX}/share/proj/ ${PROJ_INSTALL_PREFIX}/share/proj/
cp -rf /build${PROJ_INSTALL_PREFIX}/include/ ${PROJ_INSTALL_PREFIX}/include/
cp -rf /build${PROJ_INSTALL_PREFIX}/bin/ ${PROJ_INSTALL_PREFIX}/bin/
cp -rf /build${PROJ_INSTALL_PREFIX}/lib/ ${PROJ_INSTALL_PREFIX}/lib/

cp -rf /build/usr/share/java /usr/share/java
cp -rf /build/usr/share/gdal/ /usr/share/gdal/
cp -rf /build/usr/include/ /usr/include/
cp -rf /build_gdal_python/usr/ /usr/
cp -rf /build_gdal_version_changing/usr/ /usr/

apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ldconfig
