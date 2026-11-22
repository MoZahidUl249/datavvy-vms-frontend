#!/usr/bin/env bash
# Netlify build for the Flutter web app (Netlify has no Flutter preinstalled).
# Needs VMS_API_BASE_URL in the Netlify site's environment, e.g.
#   https://vms-api.onrender.com/api
set -euo pipefail
: "${VMS_API_BASE_URL:?Set VMS_API_BASE_URL in Netlify → Site configuration → Environment variables}"
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_HOME="${NETLIFY_CACHE_DIR:-$HOME/.cache}/flutter-$FLUTTER_VERSION"
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --version
flutter config --no-analytics >/dev/null
flutter pub get
flutter build web --release --dart-define=VMS_API_BASE_URL="$VMS_API_BASE_URL"
