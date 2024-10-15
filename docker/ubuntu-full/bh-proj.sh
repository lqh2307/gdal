#!/bin/sh

set -eu

mkdir -p proj

curl -L -fsS https://github.com/OSGeo/PROJ/archive/master.tar.gz | tar xz -C proj --strip-components=1

cd proj

export CFLAGS="-DPROJ_RENAME_SYMBOLS -O2 -g"
export CXXFLAGS="-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2 -g"

cmake . \
    -G Ninja \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_TESTING=OFF
ninja
DESTDIR=${DESTDIR} ninja install

rm -rf proj

if test "${DESTDIR}" = "/build_tmp_proj"; then
    exit 0
fi

PROJ_SO=$(readlink -f ${DESTDIR}/usr/local/lib/libproj.so | awk 'BEGIN {FS="libproj.so."} {print ${2}}')
PROJ_SO_FIRST=$(echo ${PROJ_SO} | awk 'BEGIN {FS="."} {print ${1}}')
PROJ_SO_DEST=${DESTDIR}/usr/local/lib/libinternalproj.so.${PROJ_SO}

mv ${DESTDIR}/usr/local/lib/libproj.so.${PROJ_SO} ${PROJ_SO_DEST}

ln -s libinternalproj.so.${PROJ_SO} ${DESTDIR}/usr/local/lib/libinternalproj.so.${PROJ_SO_FIRST}
ln -s libinternalproj.so.${PROJ_SO} ${DESTDIR}/usr/local/lib/libinternalproj.so

rm -rf ${DESTDIR}/usr/local/lib/libproj.*

x86_64-linux-gnu-strip -s ${PROJ_SO_DEST}
for P in ${DESTDIR}/usr/local/bin/*; do
    x86_64-linux-gnu-strip -s ${P} 2>/dev/null || /bin/true;
done;

patchelf --set-soname libinternalproj.so.${PROJ_SO_FIRST} ${DESTDIR}/usr/local/lib/libinternalproj.so.${PROJ_SO}
for i in ${DESTDIR}/usr/local/bin/*; do
  patchelf --replace-needed libproj.so.${PROJ_SO_FIRST} libinternalproj.so.${PROJ_SO_FIRST} ${i};
done
