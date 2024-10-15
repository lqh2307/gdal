ARG BASE_IMAGE=ubuntu:24.04
ARG TARGET_BASE_IMAGE=ubuntu:24.04

FROM ${BASE_IMAGE} AS builder

ARG DEBIAN_FRONTEND=noninteractive

# set proxy
ARG http_proxy=http://10.55.123.98:3333
ARG https_proxy=http://10.55.123.98:3333

# Setup build env for PROJ, GDAL, tileDB, PDFium, libjxl
ARG JAVA_VERSION=17
RUN apt-get update -y && apt-get upgrade -y \
  && apt-get install -y --fix-missing --no-install-recommends \
    build-essential ca-certificates ccache git ninja-build cmake wget unzip libtool automake patchelf lsb-release \
    zlib1g-dev libsqlite3-dev pkg-config sqlite3 libcurl4-openssl-dev \
    libtiff-dev libopenjp2-7-dev libcairo2-dev \
    python3-dev python3-numpy python3-setuptools \
    libpng-dev libjpeg-dev libgif-dev liblzma-dev libgeos-dev \
    curl libxml2-dev libexpat-dev libxerces-c-dev \
    libnetcdf-dev libpoppler-dev libpoppler-private-dev \
    libspatialite-dev librasterlite2-dev swig ant libhdf4-alt-dev libhdf5-serial-dev \
    libfreexl-dev unixodbc-dev mdbtools-dev libwebp-dev \
    liblcms2-2 libpcre3-dev libcrypto++-dev libfyba-dev \
    libkml-dev libmysqlclient-dev libogdi-dev \
    libcfitsio-dev openjdk-${JAVA_VERSION}-jdk libzstd-dev \
    libpq-dev libssl-dev libboost-dev \
    autoconf bash-completion libarmadillo-dev \
    libopenexr-dev libheif-dev \
    libdeflate-dev libblosc-dev liblz4-dev libbz2-dev \
    libbrotli-dev libarchive-dev libaec-dev libavif-dev \
    libspdlog-dev libmagic-dev liblcms2-dev libgflags-dev

# Build libkea
ARG KEA_VERSION=1.5.2
RUN curl -LO -fsS https://github.com/ubarsc/kealib/archive/kealib-${KEA_VERSION}.zip \
  && unzip -q kealib-${KEA_VERSION}.zip \
  && cd kealib-kealib-${KEA_VERSION} \
  && cmake . -G Ninja -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr -DHDF5_INCLUDE_DIR=/usr/include/hdf5/serial \
    -DHDF5_LIB_PATH=/usr/lib/x86_64-linux-gnu/hdf5/serial -DLIBKEA_WITH_GDAL=OFF \
  && ninja \
  && DESTDIR="/build_thirdparty" ninja install \
  && ninja install \
  && cd .. \
  && rm -rf kealib-kealib-${KEA_VERSION} kealib-${KEA_VERSION}.zip \
  && for i in /build_thirdparty/usr/lib/*; do strip -s ${i} 2>/dev/null || /bin/true; done \
  && for i in /build_thirdparty/usr/bin/*; do strip -s ${i} 2>/dev/null || /bin/true; done

# Build mongo-c-driver
ARG MONGO_C_DRIVER_VERSION=1.24.4
RUN mkdir -p mongo-c-driver \
  && curl -L -fsS https://github.com/mongodb/mongo-c-driver/releases/download/${MONGO_C_DRIVER_VERSION}/mongo-c-driver-${MONGO_C_DRIVER_VERSION}.tar.gz | tar xz -C mongo-c-driver --strip-components=1 \
  && cd mongo-c-driver \
  && mkdir -p build_cmake \
  && cd build_cmake \
  && cmake .. -G Ninja -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_TESTS=NO -DCMAKE_BUILD_TYPE=Release \
  && ninja \
  && DESTDIR="/build_thirdparty" ninja install \
  && ninja install \
  && cd ../.. \
  && rm -rf mongo-c-driver /build_thirdparty/usr/lib/x86_64-linux-gnu/*.a \
  && for i in /build_thirdparty/usr/lib/x86_64-linux-gnu/*; do strip -s ${i} 2>/dev/null || /bin/true; done \
  && for i in /build_thirdparty/usr/bin/*; do strip -s ${i} 2>/dev/null || /bin/true; done

# Build mongocxx
ARG MONGOCXX_VERSION=3.8.1
RUN mkdir -p mongocxx \
  && curl -L -fsS https://github.com/mongodb/mongo-cxx-driver/archive/r${MONGOCXX_VERSION}.tar.gz | tar xz -C mongocxx --strip-components=1 \
  && cd mongocxx \
  && mkdir -p build_cmake \
  && cd build_cmake \
  && cmake .. -G Ninja -DCMAKE_INSTALL_PREFIX=/usr -DBSONCXX_POLY_USE_BOOST=ON -DENABLE_TESTS=OFF -DMONGOCXX_ENABLE_SLOW_TESTS=NO -DCMAKE_BUILD_TYPE=Release -DBUILD_VERSION=${MONGOCXX_VERSION} \
  && ninja \
  && DESTDIR="/build_thirdparty" ninja install \
  && ninja install \
  && cd ../.. \
  && rm -rf mongocxx \
  && for i in /build_thirdparty/usr/lib/x86_64-linux-gnu/*; do strip -s ${i} 2>/dev/null || /bin/true; done \
  && for i in /build_thirdparty/usr/bin/*; do strip -s ${i} 2>/dev/null || /bin/true; done

# Build tiledb
ARG TILEDB_VERSION=2.23.0
COPY tiledb-FindLZ4_EP.cmake.patch /buildscripts/tiledb-FindLZ4_EP.cmake.patch
COPY tiledb-FindOpenSSL_EP.cmake.patch /buildscripts/tiledb-FindOpenSSL_EP.cmake.patch
COPY tiledb-cmake-ccache.patch /buildscripts/tiledb-cmake-ccache.patch
RUN mkdir -p tiledb \
  && curl -L -fsS https://github.com/TileDB-Inc/TileDB/archive/${TILEDB_VERSION}.tar.gz | tar xz -C tiledb --strip-components=1 \
  && cd tiledb \
  && patch -p0 < /buildscripts/tiledb-FindLZ4_EP.cmake.patch \
  && patch -p0 < /buildscripts/tiledb-FindOpenSSL_EP.cmake.patch \
  && patch -p1 < /buildscripts/tiledb-cmake-ccache.patch \
  && mkdir -p build_cmake \
  && cd build_cmake \
  && cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DTILEDB_WERROR=OFF -DTILEDB_SUPERBUILD=OFF -DTILEDB_TESTS=OFF -DCOMPILER_SUPPORTS_AVX2=FALSE -DOPENSSL_INCLUDE_DIR=/usr/include \
  && ninja \
  && DESTDIR="/build_thirdparty" ninja install \
  && ninja install \
  && cd ../.. \
  && rm -rf tiledb \
  && for i in /build_thirdparty/usr/lib/x86_64-linux-gnu/*; do strip -s ${i} 2>/dev/null || /bin/true; done \
  && for i in /build_thirdparty/usr/bin/*; do strip -s ${i} 2>/dev/null || /bin/true; done

# Build libOpenDRIVE
ARG OPENDRIVE_VERSION=0.6.0-gdal
RUN curl -LO -fsS https://github.com/DLR-TS/libOpenDRIVE/archive/refs/tags/${OPENDRIVE_VERSION}.tar.gz \
  && tar xzf ${OPENDRIVE_VERSION}.tar.gz \
  && cd libOpenDRIVE-${OPENDRIVE_VERSION} \
  && cmake . -G Ninja -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/ \
  && ninja \
  && ninja install \
  && mkdir -p /build_thirdparty/usr/lib \
  && cp -P /usr/lib/libOpenDrive*.so* /build_thirdparty/usr/lib \
  && for i in /build_thirdparty/usr/lib/*; do strip -s ${i} 2>/dev/null || /bin/true; done \
  && cd .. \
  && rm -rf libOpenDRIVE-${OPENDRIVE_VERSION} ${OPENDRIVE_VERSION}.tar.gz

# Build file-geodatabase
RUN curl -LO -fsS https://github.com/Esri/file-geodatabase-api/raw/master/FileGDB_API_1.5.2/FileGDB_API-RHEL7-64gcc83.tar.gz \
  && tar xzf FileGDB_API-RHEL7-64gcc83.tar.gz \
  && mv FileGDB_API-RHEL7-64gcc83 /usr/local/FileGDB_API \
  && rm -rf /usr/local/FileGDB_API/lib/libstdc++* \
  && cp /usr/local/FileGDB_API/lib/* /build_thirdparty/usr/lib/x86_64-linux-gnu \
  && cp /usr/local/FileGDB_API/include/* /usr/include \
  && rm -rf FileGDB_API-RHEL7-64gcc83.tar.gz

# Build libqb3
RUN git clone https://github.com/lucianpls/QB3.git \
  && cd QB3/QB3lib \
  && mkdir -p build \
  && cd build \
  && cmake .. -G Ninja -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release \
  && ninja \
  && ninja install \
  && DESTDIR="/build_thirdparty" ninja install \
  && cd ../../.. \
  && rm -rf QB3

# Build pdfium
RUN curl -LO -fsS https://github.com/rouault/pdfium_build_gdal_3_10/releases/download/pdfium_6677_v1/install-ubuntu2004-rev6677.tar.gz \
  && tar xzf install-ubuntu2004-rev6677.tar.gz \
  && mv install/lib/* /usr/lib/ \
  && mv install/include/* /usr/include/ \
  && rm -rf install-ubuntu2004-rev6677.tar.gz install

# Build libjxl
RUN git clone https://github.com/libjxl/libjxl.git --recursive \
  && cd libjxl \
  && mkdir -p build \
  && cd build \
  && cmake -G Ninja -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DJPEGXL_ENABLE_JPEGLI_LIBJPEG=OFF -DBUILD_TESTING=OFF -DJPEGXL_ENABLE_TOOLS=OFF -DJPEGXL_ENABLE_BENCHMARK=OFF .. \
  && ninja \
  && ninja install \
  && DESTDIR="/build_thirdparty" ninja install \
  && cd ../.. \
  && rm -rf libjxl /lib/x86_64-linux-gnu/libjxl*.a /build_thirdparty/lib/x86_64-linux-gnu/libjxl*.a

# Install Arrow C++
ARG ARROW_VERSION=16.1.0-1
ARG ARROW_SOVERSION=1600
RUN curl -LO -fsS https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
  && apt-get install -y \
    ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
  && apt-get update -y && apt-get upgrade -y \
  && apt-get install -y \
    libarrow${ARROW_SOVERSION} \
    libparquet${ARROW_SOVERSION} \
    libarrow-dataset${ARROW_SOVERSION} \
    libarrow-dev=${ARROW_VERSION} \
    libparquet-dev=${ARROW_VERSION} \
    libarrow-acero-dev=${ARROW_VERSION} \
    libarrow-dataset-dev=${ARROW_VERSION} \
  && rm -rf ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb

# Refresh grids
COPY bh-proj.sh /buildscripts/bh-proj.sh
RUN DESTDIR=/build_tmp_proj /buildscripts/bh-proj.sh \
  && LD_LIBRARY_PATH=/build_tmp_proj/usr/local/lib /build_tmp_proj/usr/local/bin/projsync --target-dir /tmp/proj_grids --all \
  && rm -rf /build_tmp_proj

# Build PROJ
RUN /buildscripts/bh-proj.sh

# Build GDAL
ARG GDAL_VERSION=1.0.0
ARG GDAL_REPOSITORY=lqh2307/gdal

COPY bh-gdal.sh /buildscripts/bh-gdal.sh
RUN /buildscripts/bh-gdal.sh


# Build final image
FROM ${TARGET_BASE_IMAGE} AS runner

ARG DEBIAN_FRONTEND=noninteractive

# set proxy
ARG http_proxy=http://10.55.123.98:3333
ARG https_proxy=http://10.55.123.98:3333

# Update distro
ARG JAVA_VERSION=17
ARG ARROW_SOVERSION=1600
RUN apt-get update -y && apt-get upgrade -y \
  && apt-get install -y \
  # PROJ dependencies
    libsqlite3-0 libtiff6 libcurl4 \
    wget curl unzip ca-certificates lsb-release \
  # GDAL dependencies
    libopenjp2-7 libcairo2 python3-numpy libpng16-16 libjpeg-turbo8 libgif7 liblzma5 libgeos3.12.1 libgeos-c1v5 \
    libxml2 libexpat1 libxerces-c3.2 libnetcdf-c++4-1 netcdf-bin libpoppler134 libspatialite8 librasterlite2-1 gpsbabel \
    libhdf4-0-alt libhdf5-103-1 libhdf5-cpp-103-1 poppler-utils libfreexl1 unixodbc mdbtools libwebp7 \
    liblcms2-2 libpcre3 libcrypto++8 libfyba0 libkmlbase1 libkmlconvenience1 libkmldom1 libkmlengine1 libkmlregionator1 libkmlxsd1 \
    libmysqlclient21 libogdi4.1 libcfitsio10 libzstd1 bash bash-completion libpq5 libarmadillo12 libpython3.12 libopenexr-3-1-30 libheif1 \
    libdeflate0 libblosc1 liblz4-1 libbrotli1 libarchive13 libaec0 libavif16 libspdlog1.12 libmagic1t64 \
    python-is-python3 python3-pil \
  && apt-get install -y --no-install-recommends \
    openjdk-${JAVA_VERSION}-jre \
  # Worksround OGDI packaging bug for Ubuntu 24.04
  && ln -s /usr/lib/$(uname -p)-linux-gnu/ogdi/4.1/libvrf.so /usr/lib/$(uname -p)-linux-gnu \
  # Install Arrow C++
  && curl -LO -fsS https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
  && apt-get install -y \
    ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
  && apt-get update -y && apt-get upgrade -y \
  && apt-get install -y \
    libarrow${ARROW_SOVERSION} \
    libparquet${ARROW_SOVERSION} \
    libarrow-dataset${ARROW_SOVERSION} \
  && apt-get -y --purge autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb

COPY --from=builder  /build_thirdparty/usr/ /usr/
COPY --from=builder  /tmp/proj_grids/* /usr/local/share/proj/
COPY --from=builder  /build/usr/local/share/proj/ /usr/local/share/proj/
COPY --from=builder  /build/usr/local/include/ /usr/local/include/
COPY --from=builder  /build/usr/local/bin/ /usr/local/bin/
COPY --from=builder  /build/usr/local/lib/ /usr/local/lib/
COPY --from=builder  /build/usr/share/java /usr/share/java
COPY --from=builder  /build/usr/share/gdal/ /usr/share/gdal/
COPY --from=builder  /build/usr/include/ /usr/include/
COPY --from=builder  /build_gdal_python/usr/ /usr/
COPY --from=builder  /build_gdal_version_changing/usr/ /usr/

RUN ldconfig
