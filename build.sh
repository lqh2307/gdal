#!/bin/bash

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
export PROJ_DATUMGRID_LATEST_LAST_MODIFIED=""
export PROJ_INSTALL_PREFIX="/usr/local"
export PROJ_VERSION="master"
export GDAL_VERSION="master"
export GDAL_RELEASE_DATE=""
export GDAL_BUILD_IS_RELEASE=""
export GDAL_REPOSITORY="OSGeo/gdal"
export WITH_DEBUG_SYMBOLS="no"
export RSYNC_REMOTE=""
export WITH_PDFIUM="yes"
export DEBIAN_FRONTEND="noninteractive"

/home/ubuntu/gdal/docker/ubuntu-full/bh-set-envvars.sh

# Nếu TARGET_ARCH không rỗng, cập nhật danh sách sources
if [ -n "$TARGET_ARCH" ]; then
  rm -f /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources
  echo "deb [arch=amd64] http://us.archive.ubuntu.com/ubuntu/ noble main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=amd64] http://us.archive.ubuntu.com/ubuntu/ noble-updates main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=amd64] http://us.archive.ubuntu.com/ubuntu/ noble-backports main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu noble-security main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=${TARGET_ARCH}] http://ports.ubuntu.com/ubuntu-ports/ noble main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=${TARGET_ARCH}] http://ports.ubuntu.com/ubuntu-ports/ noble-updates main restricted universe" >> /etc/apt/sources.list
  echo "deb [arch=${TARGET_ARCH}] http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe" >> /etc/apt/sources.list
  dpkg --add-architecture ${TARGET_ARCH}
  apt-get update -y
  apt-get install -y g++-13-${GCC_ARCH}-linux-gnu
  ln -s ${GCC_ARCH}-linux-gnu-gcc-13 /usr/bin/${GCC_ARCH}-linux-gnu-gcc
  ln -s ${GCC_ARCH}-linux-gnu-g++-13 /usr/bin/${GCC_ARCH}-linux-gnu-g++
fi

# Setup build env for PROJ
apt-get update -y
apt-get install -y --fix-missing --no-install-recommends \
  build-essential ca-certificates \
  git make cmake wget unzip libtool automake \
  zlib1g-dev${APT_ARCH_SUFFIX} libsqlite3-dev${APT_ARCH_SUFFIX} \
  pkg-config sqlite3 libcurl4-openssl-dev${APT_ARCH_SUFFIX} \
  libtiff-dev${APT_ARCH_SUFFIX}

# Setup build env for GDAL
apt-get install -y --fix-missing --no-install-recommends \
  libopenjp2-7-dev libcairo2-dev python3-dev python3-numpy python3-setuptools \
  libpng-dev libjpeg-dev libgif-dev liblzma-dev libgeos-dev \
  libxml2-dev libexpat-dev libxerces-c-dev libnetcdf-dev libpoppler-dev \
  libspatialite-dev librasterlite2-dev swig ant libhdf4-alt-dev libhdf5-serial-dev \
  libfreexl-dev unixodbc-dev mdbtools-dev libwebp-dev \
  liblcms2-2 libpcre3-dev libcrypto++-dev libfyba-dev \
  libkml-dev libmysqlclient-dev libogdi-dev \
  libcfitsio-dev openjdk-${JAVA_VERSION}-jdk libzstd-dev \
  libpq-dev libssl-dev libboost-dev autoconf automake bash-completion \
  libarmadillo-dev libopenexr-dev libheif-dev libdeflate-dev libblosc-dev \
  liblz4-dev libbz2-dev libbrotli-dev libarchive-dev libaec-dev libavif-dev

# Tải và cài đặt KEA
wget -q https://github.com/ubarsc/kealib/archive/kealib-${KEA_VERSION}.zip
unzip -q kealib-${KEA_VERSION}.zip
rm -f kealib-${KEA_VERSION}.zip
cd kealib-kealib-${KEA_VERSION}
cmake . -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DHDF5_INCLUDE_DIR=/usr/include/hdf5/serial
make -j$(nproc)
make install
cd ..
rm -rf kealib-kealib-${KEA_VERSION}
for i in /build_thirdparty/usr/lib/*; do strip -s $i 2>/dev/null || /bin/true; done
for i in /build_thirdparty/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

# Tải và cài đặt Mongo C Driver
mkdir -p mongo-c-driver mongo-c-driver/build_cmake
wget -q https://github.com/mongodb/mongo-c-driver/releases/download/${MONGO_C_DRIVER_VERSION}/mongo-c-driver-${MONGO_C_DRIVER_VERSION}.tar.gz -O - | tar xz -C mongo-c-driver --strip-components=1
cd mongo-c-driver/build_cmake
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_TESTS=NO -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
make install DESTDIR=/build_thirdparty
make install
cd ../..
rm -rf mongo-c-driver /build_thirdparty/usr/lib/${GCC_ARCH}-linux-gnu/*.a
for i in /build_thirdparty/usr/lib/${GCC_ARCH}-linux-gnu/*; do strip -s $i 2>/dev/null || /bin/true; done
for i in /build_thirdparty/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

# Tải và cài đặt mongocxx
mkdir -p mongocxx mongocxx/build_cmake
wget -q https://github.com/mongodb/mongo-cxx-driver/archive/r${MONGOCXX_VERSION}.tar. -O - | tar xz -C mongocxx --strip-components=1
cd mongocxx/build_cmake
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DBSONCXX_POLY_USE_BOOST=ON -DENABLE_TESTS=OFF -DMONGOCXX_ENABLE_SLOW_TESTS=NO -DCMAKE_BUILD_TYPE=Release -DBUILD_VERSION=${MONGOCXX_VERSION}
make -j$(nproc)
make install DESTDIR=/build_thirdparty
make install
cd ../..
rm -rf mongocxx
for i in /build_thirdparty/usr/lib/${GCC_ARCH}-linux-gnu/*; do strip -s $i 2>/dev/null || /bin/true; done
for i in /build_thirdparty/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

# Tải và cài đặt TileDB
mkdir -p tiledb
wget -q https://github.com/TileDB-Inc/TileDB/archive/${TILEDB_VERSION}.tar.gz
tar xz -C tiledb --strip-components=1
cd tiledb/build_cmake
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make install
cd ../..

# Tải và cài đặt libOpenDRIVE
if [ -n "$OPENDRIVE_VERSION" ]; then
    wget -q https://github.com/DLR-TS/libOpenDRIVE/archive/refs/tags/${OPENDRIVE_VERSION}.tar.gz
    tar xzf ${OPENDRIVE_VERSION}.tar.gz
    rm -f ${OPENDRIVE_VERSION}.tar.gz
    cd libOpenDRIVE-${OPENDRIVE_VERSION}
    cmake . -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/
    make -j$(nproc)
    make install
    cd ..
fi

# Nếu cần, cài đặt File Geodatabase API
if echo "$WITH_FILEGDB" | grep -Eiq "^(y(es)?|1|true)$"; then
    wget -q https://github.com/Esri/file-geodatabase-api/raw/master/FileGDB_API_1.5.2/FileGDB_API-RHEL7-64gcc83.tar.gz
    tar -xzf FileGDB_API-RHEL7-64gcc83.tar.gz
    mv FileGDB_API-RHEL7-64gcc83 /usr/local/FileGDB_API
    rm -rf /usr/local/FileGDB_API/lib/libstdc++*
    cp /usr/local/FileGDB_API/lib/* /usr/lib/x86_64-linux-gnu
    cp /usr/local/FileGDB_API/include/* /usr/include
    rm -rf FileGDB_API-RHEL7-64gcc83.tar.gz
fi

# Cài đặt PDFium nếu cần
if echo "$WITH_PDFIUM" | grep -Eiq "^(y(es)?|1|true)$"; then
  wget -q https://github.com/rouault/pdfium_build_gdal_3_10/releases/download/pdfium_6677_v1/install-ubuntu2004-rev6677.tar.gz
  tar -xzf install-ubuntu2004-rev6677.tar.gz
  mv install/lib/* /usr/lib/
  mv install/include/* /usr/include/
  rm -rf install-ubuntu2004-rev6677.tar.gz install
  apt-get update -y
  apt-get install -y --fix-missing --no-install-recommends liblcms2-dev${APT_ARCH_SUFFIX}
fi

# Cài đặt libjxl
apt-get install -y libgflags-dev
git clone https://github.com/libjxl/libjxl.git --recursive
cd libjxl/build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DJPEGXL_ENABLE_JPEGLI_LIBJPEG=OFF -DBUILD_TESTING=OFF -DJPEGXL_ENABLE_TOOLS=OFF -DJPEGXL_ENABLE_BENCHMARK=OFF ..
make -j$(nproc)
make install
cd ../..

# Cài đặt Apache Arrow
apt-get install -y lsb-release ca-certificates
wget https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
dpkg -i apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
apt-get update
apt-get install -y libarrow${ARROW_SOVERSION} libparquet${ARROW_SOVERSION} libarrow-dataset${ARROW_SOVERSION} libarrow-dev=${ARROW_VERSION} libparquet-dev=${ARROW_VERSION} libarrow-acero-dev=${ARROW_VERSION} libarrow-dataset-dev=${ARROW_VERSION}

apt-get install -y libsqlite3-0 libtiff6 libcurl4 wget unzip ca-certificates

/home/ubuntu/gdal/docker/ubuntu-full/bh-proj.sh

/home/ubuntu/gdal/docker/ubuntu-full/bh-gdal.sh

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
