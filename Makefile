INSTALL_TARGET_PROCESSES = MobileSMS Preferences

TARGET = iphone:clang:13.0:11.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Pinnie

Pinnie_FILES = Tweak.x $(wildcard *.m)
Pinnie_CFLAGS = -fobjc-arc
Pinnie_PRIVATE_FRAMEWORKS = ChatKit Contacts IMCore

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += pinnieprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
