#!/bin/sh

set -e

if test "${PROJ_VERSION}" = ""; then
  PROJ_VERSION=master
fi

if test "${DESTDIR}" = ""; then
  DESTDIR=/build
fi

set -eu

wget -q https://github.com/OSGeo/PROJ/archive/${PROJ_VERSION}.tar.gz && tar xzf ${PROJ_VERSION}.tar.gz

cd PROJ-${PROJ_VERSION}

export CFLAGS="-DPROJ_RENAME_SYMBOLS -O2 -g"
export CXXFLAGS="-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2 -g"

mkdir -p build

cmake . \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DBUILD_TESTING=OFF
make "-j$(nproc)"
make install DESTDIR="${DESTDIR}"

cd ..

rm -rf PROJ-${PROJ_VERSION} ${PROJ_VERSION}.tar.gz

if test "${DESTDIR}" = "/build_tmp_proj"; then
  exit 0
fi

PROJ_SO=$(readlink -f "${DESTDIR}/usr/local/lib/libproj.so" | awk 'BEGIN {FS="libproj.so."} {print $2}')
PROJ_SO_FIRST=$(echo "$PROJ_SO" | awk 'BEGIN {FS="."} {print $1}')
PROJ_SO_DEST="${DESTDIR}/usr/local/lib/libinternalproj.so.${PROJ_SO}"

mv "${DESTDIR}/usr/local/lib/libproj.so.${PROJ_SO}" "${PROJ_SO_DEST}"

ln -s "libinternalproj.so.${PROJ_SO}" "${DESTDIR}/usr/local/lib/libinternalproj.so.${PROJ_SO_FIRST}"
ln -s "libinternalproj.so.${PROJ_SO}" "${DESTDIR}/usr/local/lib/libinternalproj.so"

rm "${DESTDIR}/usr/local/lib"/libproj.*

if [ "${WITH_DEBUG_SYMBOLS}" = "yes" ]; then
  # separate debug symbols
  mkdir -p "${DESTDIR}/usr/local/lib/.debug/" "${DESTDIR}/usr/local/bin/.debug/"

  DEBUG_SO="${DESTDIR}/usr/local/lib/.debug/libinternalproj.so.${PROJ_SO}.debug"
  ${GCC_ARCH}-linux-gnu-objcopy -v --only-keep-debug --compress-debug-sections "${PROJ_SO_DEST}" "${DEBUG_SO}"
  ${GCC_ARCH}-linux-gnu-strip --strip-debug --strip-unneeded "${PROJ_SO_DEST}"
  ${GCC_ARCH}-linux-gnu-objcopy --add-gnu-debuglink="${DEBUG_SO}" "${PROJ_SO_DEST}"

  for P in "${DESTDIR}/usr/local/bin"/*; do
    if file -h "$P" | grep -qi elf; then
      F=$(basename "$P")
      DEBUG_P="${DESTDIR}/usr/local/bin/.debug/${F}.debug"
      ${GCC_ARCH}-linux-gnu-objcopy -v --only-keep-debug --strip-unneeded "$P" "${DEBUG_P}"
      ${GCC_ARCH}-linux-gnu-strip --strip-debug --strip-unneeded "$P"
      ${GCC_ARCH}-linux-gnu-objcopy --add-gnu-debuglink="${DEBUG_P}" "$P"
    fi
  done
else
  ${GCC_ARCH}-linux-gnu-strip -s "${PROJ_SO_DEST}"
  for P in "${DESTDIR}/usr/local/bin"/*; do
    ${GCC_ARCH}-linux-gnu-strip -s "$P" 2>/dev/null || /bin/true;
  done;
fi

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y patchelf
rm -rf /var/lib/apt/lists/*
patchelf --set-soname libinternalproj.so.${PROJ_SO_FIRST} ${DESTDIR}/usr/local/lib/libinternalproj.so.${PROJ_SO}
for i in "${DESTDIR}/usr/local/bin"/*; do
  patchelf --replace-needed libproj.so.${PROJ_SO_FIRST} libinternalproj.so.${PROJ_SO_FIRST} $i;
done
