ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:8.0
	ARCHS = x86_64 i386
else
	TARGET = iphone:clang:latest:7.0
	ARCHS = armv7 arm64
endif

PACKAGE_VERSION = 1.0.7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZEmojiDarkStyle
$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_USE_SUBSTRATE = 1

include $(THEOS_MAKE_PATH)/tweak.mk

setup:: clean all
ifeq ($(SIMULATOR),1)
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject
endif
