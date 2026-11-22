#!/bin/bash
# Runs the VMS web app in Chrome on http://localhost:5173 (debug, hot reload).
# API: VMS_API_BASE_URL from .env, else the local backend (http://localhost:8080/api).
# Start the API first: run-backend.command in datavvy-vms-backend.
cd "$(dirname "$0")" || exit 1
[ -f .env ] && { set -a; . ./.env; set +a; }
API_URL="${VMS_API_BASE_URL:-http://localhost:8080/api}"
command -v flutter >/dev/null 2>&1 || { echo "!! Flutter not found — install it from flutter.dev"; read -n1; exit 1; }
echo "== API: $API_URL"
curl -s -m 3 "${API_URL%/api}/actuator/health" | grep -q '"UP"' || echo "!! The API isn't answering at ${API_URL%/api} — start it, or set VMS_API_BASE_URL in .env"
flutter pub get > web-run.log 2>&1 || { cat web-run.log; read -n1; exit 1; }
flutter run -d chrome --web-port=5173 --dart-define=VMS_API_BASE_URL="$API_URL" 2>&1 | tee -a web-run.log
