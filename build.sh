#!/usr/bin/env bash
set -euo pipefail

mkdir -p build/classes_set build/classes_keep

# 1. Build Android DEX helpers
javac --release 11 -d build/classes_set java/Set4KHDR.java
d8 --output build/classes_set build/classes_set/Set4KHDR.class
mv build/classes_set/classes.dex build/set_4k_hdr.dex

javac --release 11 -d build/classes_keep java/Keep4KHDR.java
d8 --output build/classes_keep build/classes_keep/Keep4KHDR.class
mv build/classes_keep/classes.dex build/keep_4k_hdr.dex

# 2. Build out-of-tree DisplayPort InfoFrame kernel modules (Tensor G3 / Android 6.1 GKI)
CFLAGS=(
  --target=aarch64-linux-gnu
  -O2
  -mcmodel=large
  -fno-PIC
  -ffreestanding
  -fno-stack-protector
  -fno-asynchronous-unwind-tables
  -mno-outline-atomics
  -mbranch-protection=pac-ret
)

clang "${CFLAGS[@]}" -c kernel/dp_hdr_hlg.c -o build/dp_hdr_hlg.ko
clang "${CFLAGS[@]}" -c kernel/dp_hdr_sdr.c -o build/dp_hdr_sdr.ko

echo "Build complete in ./build/:"
ls -lh build/*.dex build/*.ko
