################################################################################
#
# qceframe
#
################################################################################

QCEFFRAME_VERSION = main
QCEFFRAME_SITE = $(call github,JunJunHub,QCefFrame,$(QCEFFRAME_VERSION))
QCEFFRAME_LICENSE = LGPL-3.0+
QCEFFRAME_LICENSE_FILES = LICENSE

QCEFFRAME_DEPENDENCIES = \
	qt6base \
	host-cmake \
	curl \
	openssl

# CEF will be downloaded automatically by CMake

QCEFFRAME_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=Release \
	-DPROJECT_ARCH=arm64 \
	-DBUILD_DEMO=OFF \
	-DUSE_SANDBOX=OFF \
	-DBUILD_STATIC=OFF

# Define Qt6 paths for cross-compilation
QCEFFRAME_CONF_OPTS += \
	-DQt6_DIR=$(STAGING_DIR)/usr/lib/cmake/Qt6 \
	-DQt6Core_DIR=$(STAGING_DIR)/usr/lib/cmake/Qt6Core \
	-DQt6Gui_DIR=$(STAGING_DIR)/usr/lib/cmake/Qt6Gui \
	-DQt6Widgets_DIR=$(STAGING_DIR)/usr/lib/cmake/Qt6Widgets

# Define toolchain
QCEFFRAME_CONF_OPTS += \
	-DCMAKE_TOOLCHAIN_FILE=$(@D)/cmake/toolchain-linux-arm64.cmake

# Override toolchain file to use Buildroot sysroot
define QCEFFRAME_CONFIGURE_CMDS
	mkdir -p $(@D)/.build
	(cd $(@D)/.build; \
		$(HOST_DIR)/bin/cmake \
		-G "Unix Makefiles" \
		-DCMAKE_BUILD_TYPE=Release \
		-DPROJECT_ARCH=arm64 \
		-DBUILD_DEMO=OFF \
		-DUSE_SANDBOX=OFF \
		-DQt6_DIR=$(STAGING_DIR)/usr/lib/cmake/Qt6 \
		-DCMAKE_TOOLCHAIN_FILE=$(@D)/cmake/toolchain-linux-arm64.cmake \
		-DCMAKE_FIND_ROOT_PATH=$(STAGING_DIR) \
		-DCMAKE_SYSROOT=$(STAGING_DIR) \
		-DCMAKE_C_COMPILER=$(TARGET_CC) \
		-DCMAKE_CXX_COMPILER=$(TARGET_CXX) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		$(@D) \
	)
endef

define QCEFFRAME_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(HOST_DIR)/bin/cmake --build $(@D)/.build -- -j$(PARALLEL_JOBS)
endef

define QCEFFRAME_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(HOST_DIR)/bin/cmake --install $(@D)/.build --prefix $(STAGING_DIR)/usr
endef

define QCEFFRAME_INSTALL_TARGET_CMDS
	# Install library
	cp -a $(@D)/.build/output/Release/bin/libQCefView.so* $(TARGET_DIR)/usr/lib/

	# Install CEF binaries (required at runtime)
	cp -a $(@D)/.build/output/Release/bin/libcef.so $(TARGET_DIR)/usr/lib/
	cp -a $(@D)/.build/output/Release/bin/libEGL.so $(TARGET_DIR)/usr/lib/
	cp -a $(@D)/.build/output/Release/bin/libGLESv2.so $(TARGET_DIR)/usr/lib/
	cp -a $(@D)/.build/output/Release/bin/CefViewWing $(TARGET_DIR)/usr/bin/

	# Install CEF resources
	mkdir -p $(TARGET_DIR)/usr/share/cef
	cp -a $(@D)/.build/output/Release/bin/*.pak $(TARGET_DIR)/usr/share/cef/
	cp -a $(@D)/.build/output/Release/bin/icudtl.dat $(TARGET_DIR)/usr/share/cef/
	cp -a $(@D)/.build/output/Release/bin/locales $(TARGET_DIR)/usr/share/cef/
endef

$(eval $(cmake-package))
