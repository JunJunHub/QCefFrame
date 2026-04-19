#!/bin/bash
# generate-linux-arm64.sh
# Generate CMake project for Linux ARM64 cross-compilation
#
# Usage:
#   ./generate-linux-arm64.sh              # Configure and build
#   ./generate-linux-arm64.sh -i           # Configure only (no build)
#
# For Buildroot environment:
#   source tools/buildroot/setup-buildroot-env.sh /path/to/buildroot
#   ./generate-linux-arm64.sh
#
# Standalone (requires Qt6 ARM64):
#   export Qt6_DIR=/path/to/qt6/arm64/lib/cmake/Qt6
#   ./generate-linux-arm64.sh

set -e

BUILD_PROJECT=1
BUILD_DIR="$(pwd)/.build/linux.arm64"
INSTALL_DIR="$(pwd)/out/linux.arm64"

while getopts ib:d: flag
do
    case "${flag}" in
        i) BUILD_PROJECT=0;;
        b) BUILD_DIR="${OPTARG}";;
        d) INSTALL_DIR="${OPTARG}";;
    esac
done

echo "============================================"
echo "QCefView - Linux ARM64 Cross-Compilation"
echo "============================================"
echo "Build Dir: ${BUILD_DIR}"
echo "Install Dir: ${INSTALL_DIR}"
echo "============================================"

# Check for Buildroot environment
if [ -n "$ARM64_SYSROOT" ]; then
    echo "[INFO] Buildroot environment detected"
    echo "  Sysroot: $ARM64_SYSROOT"
fi

# Check Qt6
if [ -z "$Qt6_DIR" ]; then
    echo ""
    echo "[WARN] Qt6_DIR is not set!"
    echo ""
    echo "For Buildroot environment, run:"
    echo "  source tools/buildroot/setup-buildroot-env.sh /path/to/buildroot"
    echo ""
    echo "For standalone toolchain, set Qt6_DIR:"
    echo "  export Qt6_DIR=/path/to/qt6/arm64/lib/cmake/Qt6"
    echo ""
    exit 1
fi

echo "[INFO] Qt6_DIR: $Qt6_DIR"
echo ""

# Check toolchain (only if not using Buildroot)
if [ -z "$CC" ] || [ -z "$CXX" ]; then
    if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
        echo "[ERROR] ARM64 cross-compiler not found!"
        echo ""
        echo "Install standalone toolchain:"
        echo "  sudo apt install g++-aarch64-linux-gnu"
        echo ""
        echo "Or use Buildroot environment:"
        echo "  source tools/buildroot/setup-buildroot-env.sh /path/to/buildroot"
        exit 1
    fi
    echo "[INFO] Using system toolchain: $(aarch64-linux-gnu-gcc --version | head -1)"
else
    echo "[INFO] Using toolchain from environment: $CC"
fi

echo ""

# CMake configuration
cmake -G "Unix Makefiles" \
    -S . \
    -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPROJECT_ARCH=arm64 \
    -DCMAKE_TOOLCHAIN_FILE="$(pwd)/cmake/toolchain-linux-arm64.cmake" \
    -DBUILD_DEMO=ON \
    -DUSE_SANDBOX=OFF \
    -DCMAKE_INSTALL_PREFIX:PATH="${INSTALL_DIR}" \
    $*

CMAKE_RESULT=$?

if [ ${CMAKE_RESULT} -ne 0 ]; then
    echo ""
    echo "[ERROR] CMake configuration failed!"
    exit ${CMAKE_RESULT}
fi

if [ ${BUILD_PROJECT} -eq 1 ]; then
    echo ""
    echo "============================================"
    echo "Building..."
    echo "============================================"
    cmake --build "${BUILD_DIR}" -- -j$(nproc)
    BUILD_RESULT=$?

    if [ ${BUILD_RESULT} -ne 0 ]; then
        echo "[ERROR] Build failed!"
        exit ${BUILD_RESULT}
    fi

    echo ""
    echo "============================================"
    echo "Build succeeded!"
    echo "Output: ${BUILD_DIR}/output/Release"
    echo "============================================"
    echo ""
    echo "To deploy to target device:"
    echo "  scp -r ${BUILD_DIR}/output/Release/bin/* root@device:/usr/lib/"
fi
