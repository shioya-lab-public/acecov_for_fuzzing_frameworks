#!/bin/bash
set -e

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env MAGMA: path to Magma support files
# - env OUT: path to directory where artifacts are stored
# - env CFLAGS and CXXFLAGS must be set to link against Magma instrumentation
##

export CC="$FUZZER/repo/afl-clang-fast"
export CXX="$FUZZER/repo/afl-clang-fast++"
export AFL_LLVM_INSTRUMENT="CLASSIC"
export EMBED_INFO_BASE="$OUT/embed"
export AS="llvm-as"

export LIBS="$LIBS -lc++ -lc++abi $FUZZER/repo/utils/aflpp_driver/libAFLDriver.a"

# AFL++'s driver is compiled against libc++
export CXXFLAGS="$CXXFLAGS -stdlib=libc++"

# Build the AFL-only instrumented version
(
    export EMBED_INFO_BASE="$OUT/afl/embed"
    export OUT="$OUT/afl"
    export LDFLAGS="$LDFLAGS -L$OUT"

    "$MAGMA/build.sh"
    "$TARGET/build.sh"
)

# Build the CmpLog instrumented version

(
    export EMBED_INFO_BASE="$OUT/cmplog/embed"
    export OUT="$OUT/cmplog"
    export LDFLAGS="$LDFLAGS -L$OUT"
    # export CFLAGS="$CFLAGS -DMAGMA_DISABLE_CANARIES"

    export AFL_LLVM_CMPLOG=1

    "$MAGMA/build.sh"
    "$TARGET/build.sh"
)
