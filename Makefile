# Pause uses DartNative without changing the developer's global Flutter setup.
# Override DN or DART for a different local DartNative SDK location.
DN ?= /Users/kiishidavid/zero/bin/dn
DART ?= /Users/kiishidavid/zero/bin/dart

.PHONY: get analyze run ios android

get:
	$(DN) pub get

analyze:
	$(DART) format lib test
	$(DN) analyze

run:
	$(DN) run

ios:
	$(DN) run -d ios

android:
	$(DN) run -d android
