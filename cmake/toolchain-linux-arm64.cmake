# cmake/toolchain-linux-arm64.cmake
# Cross-compilation toolchain for Linux ARM64 (aarch64)
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-linux-arm64.cmake ..
#
# Prerequisites (standalone):
#   sudo apt install g++-aarch64-linux-gnu
#
# For Buildroot environment:
#   source tools/buildroot/setup-buildroot-env.sh /path/to/buildroot
#   cmake -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-linux-arm64.cmake ..
#
# Or manually:
#   export ARM64_SYSROOT=/path/to/sysroot
#   export Qt6_DIR=/path/to/qt6/arm64/lib/cmake/Qt6

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# =============================================================================
# Compiler Configuration
# =============================================================================

# Use environment variables if set (from setup-buildroot-env.sh)
if(DEFINED ENV{CC} AND DEFINED ENV{CXX})
    set(CMAKE_C_COMPILER $ENV{CC})
    set(CMAKE_CXX_COMPILER $ENV{CXX})
    message(STATUS "Using compilers from environment: ${CMAKE_C_COMPILER}")
else()
    # Default to standard cross-compiler names
    set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
    set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
endif()

# Allow override from CMake command line
if(DEFINED CMAKE_C_COMPILER)
    # Already set above or from command line
elseif(DEFINED ENV{CROSS_COMPILE})
    set(CMAKE_C_COMPILER "$ENV{CROSS_COMPILE}gcc")
    set(CMAKE_CXX_COMPILER "$ENV{CROSS_COMPILE}g++")
endif()

# =============================================================================
# Sysroot Configuration
# =============================================================================

# Buildroot style: use STAGING_DIR if set
if(DEFINED ENV{ARM64_SYSROOT})
    set(CMAKE_SYSROOT $ENV{ARM64_SYSROOT})
    set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
    message(STATUS "Using ARM64_SYSROOT: ${CMAKE_SYSROOT}")
elseif(DEFINED ENV{STAGING_DIR})
    set(CMAKE_SYSROOT $ENV{STAGING_DIR})
    set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
    message(STATUS "Using STAGING_DIR: ${CMAKE_SYSROOT}")
elseif(EXISTS "/opt/buildroot/arm64/sysroot")
    set(CMAKE_SYSROOT "/opt/buildroot/arm64/sysroot")
    set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
    message(STATUS "Using default sysroot: ${CMAKE_SYSROOT}")
endif()

# =============================================================================
# Search Paths Configuration
# =============================================================================

# Search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Search for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# =============================================================================
# Qt6 Configuration
# =============================================================================

# Qt6 paths from environment
foreach(_qt_module Qt6 Qt6Core Qt6Gui Qt6Widgets Qt6Network)
    if(DEFINED ENV{${_qt_module}_DIR})
        set(${_qt_module}_DIR $ENV{${_qt_module}_DIR})
        message(STATUS "${_qt_module}_DIR: ${${_qt_module}_DIR}")
    endif()
endforeach()

# If sysroot is set, try to find Qt6 there
if(CMAKE_SYSROOT AND NOT DEFINED Qt6_DIR)
    set(_qt6_search_paths
        "${CMAKE_SYSROOT}/usr/lib/cmake/Qt6"
        "${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu/cmake/Qt6"
        "${CMAKE_SYSROOT}/opt/qt6/lib/cmake/Qt6"
    )
    foreach(_path ${_qt6_search_paths})
        if(EXISTS "${_path}/Qt6Config.cmake")
            set(Qt6_DIR "${_path}")
            message(STATUS "Found Qt6 in sysroot: ${Qt6_DIR}")
            break()
        endif()
    endforeach()
endif()

# =============================================================================
# Compiler Flags
# =============================================================================

# ARMv8-A baseline (Cortex-A53/A55/A72/A73 compatible)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv8-a" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8-a" CACHE STRING "" FORCE)

# Optional: optimize for specific CPU
# For RK3568 (Cortex-A55):
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mcpu=cortex-a55" CACHE STRING "" FORCE)
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=cortex-a55" CACHE STRING "" FORCE)

# =============================================================================
# Summary
# =============================================================================

message(STATUS "")
message(STATUS "=== ARM64 Cross-Compilation Toolchain ===")
message(STATUS "C Compiler:   ${CMAKE_C_COMPILER}")
message(STATUS "CXX Compiler: ${CMAKE_CXX_COMPILER}")
if(CMAKE_SYSROOT)
    message(STATUS "Sysroot:      ${CMAKE_SYSROOT}")
endif()
if(Qt6_DIR)
    message(STATUS "Qt6_DIR:      ${Qt6_DIR}")
else()
    message(STATUS "Qt6_DIR:      NOT SET (set Qt6_DIR env var)")
endif()
message(STATUS "===========================================")
message(STATUS "")
