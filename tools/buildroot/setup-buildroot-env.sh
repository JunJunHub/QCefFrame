#!/bin/bash
# setup-buildroot-env.sh
# Setup cross-compilation environment from Buildroot
#
# Usage:
#   source tools/buildroot/setup-buildroot-env.sh /path/to/buildroot
#   source tools/buildroot/setup-buildroot-env.sh /path/to/buildroot/output
#
# This script sets:
#   - ARM64_SYSROOT: target sysroot path
#   - Qt6_DIR: Qt6 cmake path
#   - PATH: adds toolchain to PATH
#   - CC, CXX: cross-compiler (optional)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_error "This script must be sourced, not executed directly."
    echo "Usage: source $0 [buildroot_path]"
    exit 1
fi

# Determine Buildroot path
if [ -n "$1" ]; then
    BUILDROOT_PATH="$1"
else
    # Try common locations
    for loc in \
        "$HOME/buildroot" \
        "$HOME/project/buildroot" \
        "/opt/buildroot" \
        "$PWD/../buildroot"
    do
        if [ -d "$loc/output" ]; then
            BUILDROOT_PATH="$loc"
            break
        fi
    done
fi

if [ -z "$BUILDROOT_PATH" ]; then
    print_error "Buildroot path not specified and not found in common locations."
    echo "Usage: source $0 /path/to/buildroot"
    return 1
fi

# Find Buildroot output directory
if [ -d "$BUILDROOT_PATH/output/host" ]; then
    # Standard Buildroot layout
    BR_OUTPUT="$BUILDROOT_PATH/output"
elif [ -d "$BUILDROOT_PATH/host" ]; then
    # Already pointing to output directory
    BR_OUTPUT="$BUILDROOT_PATH"
else
    print_error "Buildroot output directory not found at: $BUILDROOT_PATH"
    return 1
fi

print_info "Using Buildroot output: $BR_OUTPUT"

# Detect target architecture
BR_HOST_DIR="$BR_OUTPUT/host"
BR_IMAGES_DIR="$BR_OUTPUT/images"

# Find sysroot (try multiple patterns)
for pattern in \
    "$BR_HOST_DIR"/*-buildroot-linux-gnu/sysroot \
    "$BR_HOST_DIR"/aarch64-buildroot-linux-gnu/sysroot \
    "$BR_HOST_DIR"/arm-buildroot-linux-gnueabihf/sysroot
do
    if [ -d "$pattern" ]; then
        ARM64_SYSROOT="$pattern"
        break
    fi
done

if [ -z "$ARM64_SYSROOT" ] || [ ! -d "$ARM64_SYSROOT" ]; then
    print_warn "Sysroot not found, using host directory"
    ARM64_SYSROOT="$BR_HOST_DIR"
fi

print_info "Sysroot: $ARM64_SYSROOT"

# Find toolchain
TOOLCHAIN_BIN="$BR_HOST_DIR/bin"
if [ -d "$TOOLCHAIN_BIN" ]; then
    # Add to PATH
    export PATH="$TOOLCHAIN_BIN:$PATH"
    print_info "Toolchain added to PATH: $TOOLCHAIN_BIN"

    # Detect compiler prefix
    for cc in "$TOOLCHAIN_BIN"/*-gcc; do
        if [ -x "$cc" ]; then
            CC_PREFIX=$(basename "$cc" | sed 's/-gcc$//')
            print_info "Compiler prefix: $CC_PREFIX"

            # Optionally set CC/CXX
            export CC="${CC_PREFIX}-gcc"
            export CXX="${CC_PREFIX}-g++"
            export AR="${CC_PREFIX}-ar"
            export STRIP="${CC_PREFIX}-strip"
            break
        fi
    done
else
    print_warn "Toolchain bin directory not found"
fi

# Find Qt6
QT_SEARCH_PATHS=(
    "$ARM64_SYSROOT/usr/lib/cmake/Qt6"
    "$BR_OUTPUT/build/qt6base-*/"
)

for qt_path in "${QT_SEARCH_PATHS[@]}"; do
    # Handle glob patterns
    for expanded in $qt_path; do
        if [ -d "$expanded" ]; then
            if [ -f "$expanded/Qt6Config.cmake" ] || [ -f "$expanded/Qt6Config.cmake" ] 2>/dev/null; then
                Qt6_DIR="$expanded"
                break 2
            fi
        fi
    done
done

if [ -n "$Qt6_DIR" ] && [ -d "$Qt6_DIR" ]; then
    export Qt6_DIR
    print_info "Qt6 found: $Qt6_DIR"
else
    print_warn "Qt6 not found in sysroot. Please ensure qt6base is enabled in Buildroot."
    print_warn "Run: make menuconfig -> Target packages -> Graphic libraries and applications -> Qt6"
fi

# Set sysroot for CMake
export ARM64_SYSROOT
print_info "ARM64_SYSROOT: $ARM64_SYSROOT"

# Print summary
echo ""
echo "============================================"
echo "Buildroot Environment Configured"
echo "============================================"
echo "  SYSROOT:     $ARM64_SYSROOT"
echo "  Qt6_DIR:     ${Qt6_DIR:-NOT FOUND}"
echo "  CC:          ${CC:-not set}"
echo "  CXX:         ${CXX:-not set}"
echo "============================================"
echo ""

# Provide hint for building
if [ -n "$Qt6_DIR" ]; then
    echo "You can now build QCefView with:"
    echo "  ./generate-linux-arm64.sh"
fi
