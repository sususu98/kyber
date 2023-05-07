#!/bin/sh -e

ARCH="${ARCH:-amd64}"
ARCH="${TRAVIS_CPU_ARCH:-$ARCH}"

if [ "$ARCH" = "amd64" -a "$TRAVIS_OS_NAME" != "osx" ]; then
  DIRS="ref avx2"
else
  DIRS="ref"
fi

if [ "$ARCH" = "amd64" -o "$ARCH" = "arm64" ]; then
  export CFLAGS="-fsanitize=address,undefined ${CFLAGS}"
fi

for dir in $DIRS; do
  make -j$(nproc) -C $dir
  for alg in 512 768 1024; do
    #valgrind --vex-guest-max-insns=25 ./$dir/test_kyber$alg
    ./$dir/test/test_kyber$alg &
    PID1=$!
    ./$dir/test/test_vectors$alg > tvecs$alg &
    PID2=$!
    wait $PID1 $PID2
  done
  shasum -a256 -c SHA256SUMS
done

exit 0
