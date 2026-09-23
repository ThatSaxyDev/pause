# Pause uses DartNative without changing the developer's global Flutter setup.
# Override DN or DART for a different local DartNative SDK location.
DN ?= /Users/kiishidavid/zero/bin/dn
DART ?= /Users/kiishidavid/zero/bin/dart

.PHONY: get analyze run ios android run-hosted ios-hosted android-hosted

# Local iOS simulator: localhost is the default.
# Hosted: make run-hosted (or override API_URL for another environment).
API_URL ?=
HOSTED_API_URL := https://pause-api.kiishi.space

get:
	$(DN) pub get

analyze:
	$(DART) format lib test
	$(DN) analyze

run:
	$(DN) run $(if $(API_URL),--dart-define=PAUSE_API_BASE_URL=$(API_URL))

run-hosted:
	$(DN) run --dart-define=PAUSE_API_BASE_URL=$(if $(API_URL),$(API_URL),$(HOSTED_API_URL))

ios-hosted:
	$(DN) run -d ios --dart-define=PAUSE_API_BASE_URL=$(if $(API_URL),$(API_URL),$(HOSTED_API_URL))

android-hosted:
	$(DN) run -d android --dart-define=PAUSE_API_BASE_URL=$(if $(API_URL),$(API_URL),$(HOSTED_API_URL))

ios:
	$(DN) run -d ios

android:
	$(DN) run -d android
