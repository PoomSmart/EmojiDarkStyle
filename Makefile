ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:8.0
	ARCHS = x86_64 i386
else
	TARGET = iphone:clang:latest:7.0
endif

PACKAGE_VERSION = 1.0.4

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZEmojiDarkStyle
ZEmojiDarkStyle_FILES = Tweak.xm
ZEmojiDarkStyle_USE_SUBSTRATE = 1

include $(THEOS_MAKE_PATH)/tweak.mk

all::
ifeq ($(SIMULATOR),1)
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject
endif
