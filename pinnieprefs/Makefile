include $(THEOS)/makefiles/common.mk

ARCHS = arm64 arm64e

BUNDLE_NAME = PinniePrefs

PinniePrefs_FILES = PNERootListController.m
PinniePrefs_INSTALL_PATH = /Library/PreferenceBundles
PinniePrefs_FRAMEWORKS = UIKit
PinniePrefs_PRIVATE_FRAMEWORKS = Preferences
PinniePrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PinniePrefs.plist$(ECHO_END)
