# Pause uses DartNative without changing the developer's global Flutter setup.
# Override DN or DART for a different local DartNative SDK location.
DN ?= /Users/kiishidavid/zero/bin/dn
DART ?= /Users/kiishidavid/zero/bin/dart

.PHONY: get analyze run ios android run-hosted

# Local iOS simulator: localhost is the default.
# Hosted: make run-hosted API_URL=https://api.example.com
API_URL ?=

get:
	$(DN) pub get

analyze:
	$(DART) format lib test
	$(DN) analyze

run:
	$(DN) run $(if $(API_URL),--dart-define=PAUSE_API_BASE_URL=$(API_URL))

run-hosted:
	@test -n "$(API_URL)" || (echo "Set API_URL=https://your-host.example" && exit 1)
	$(DN) run --dart-define=PAUSE_API_BASE_URL=$(API_URL)

ios:
	$(DN) run -d ios

android:
	$(DN) run -d android
