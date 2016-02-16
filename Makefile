export ARCHS = armv7 arm64
export SDKVERSION = 9.2

include theos/makefiles/common.mk

TWEAK_NAME = syslogWindow
syslogWindow_FILES = Tweak.xm main.m
syslogWindow_FRAMEWORKS = CoreGraphics UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
