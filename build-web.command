#!/bin/bash
# Builds the VMS Flutter web app. Double-click in Finder, or run ./build-web.command
# Output: build/web   ·   Log: build-web.log
cd "$(dirname "$0")" || exit 1
LOG="$PWD/build-web.log"
# API address baked into the build: VMS_API_BASE_URL from .env (e.g. the Render
# API for a Netlify deploy), else /api (same-origin, as in the Docker image).
[ -f .env ] && { set -a; . ./.env; set +a; }
API_URL="${VMS_API_BASE_URL:-/api}"
{
  echo "== $(date)"
  echo "== flutter: $(command -v flutter || echo 'NOT FOUND')"
  flutter --version
  echo "== flutter pub get"
  flutter pub get || exit 1
  echo "== dart format"
  dart format lib packages test
  echo "== flutter analyze"
  flutter analyze --no-fatal-infos
  echo "== flutter build web (API: $API_URL)"
  flutter build web --release --dart-define=VMS_API_BASE_URL="$API_URL" && echo "== BUILD OK: build/web"
} 2>&1 | tee "$LOG"
echo
echo "Done. Log saved to build-web.log — you can close this window."
