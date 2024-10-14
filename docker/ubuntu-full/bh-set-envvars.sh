#!/bin/sh

set -eu

if [ -n "${WITH_CCACHE:-}" ]; then
  CCACHE_PARAM="-DCMAKE_C_COMPILER_LAUNCHER=ccache"
  export CCACHE_PARAM="$CCACHE_PARAM -DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
else
  export CCACHE_PARAM=""
fi
