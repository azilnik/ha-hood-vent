#!/usr/bin/env bash
#
# deploy.sh — push the local hood-vent package to the running Home Assistant and
# reload it, in one command. No sudo: HA's /config is a bind mount owned by the
# SSH user, and the reload goes through HA's REST API with a long-lived token.
#
# Usage:
#   ./scripts/deploy.sh            # copy package + reload_all (no restart)
#   ./scripts/deploy.sh --restart  # copy package + full HA restart (only needed
#                                  # when ADDING/REMOVING a statistics/derivative
#                                  # sensor platform — those don't hot-reload)
#
# Setup (once): on the NAS create /volume1/docker/.hood-vent/config and
# /volume1/docker/.hood-vent/ha_token — see docs/development.md.
# NAS_SSH_HOST defaults to the "synology" ssh alias; override via env.

set -euo pipefail
cd "$(dirname "$0")/.."

NAS="${NAS_SSH_HOST:-synology}"
PKG="hood_vent_package.yaml"
SERVICE="reload_all"
[[ "${1:-}" == "--restart" ]] && SERVICE="restart"

if ! git diff --quiet -- "$PKG" 2>/dev/null; then
  echo "note: $PKG has uncommitted changes — deploying the working-tree version."
fi

echo "==> staging $PKG to $NAS"
scp -O "$PKG" "$NAS:/volume1/docker/.hood-vent/staging.yaml"

echo "==> deploy + $SERVICE on $NAS (no sudo)"
ssh "$NAS" "SERVICE='$SERVICE' sh -s" <<'REMOTE'
set -eu
. /volume1/docker/.hood-vent/config
# validate before touching the live file
code=$(curl -s -o /dev/null -w '%{http_code}' \
  -H "Authorization: Bearer $(cat /volume1/docker/.hood-vent/ha_token)" \
  -X POST "$HA_URL/api/config/core/check_config")
cp /volume1/docker/.hood-vent/staging.yaml "$HA_PACKAGES_DIR/hood_vent_package.yaml"
echo "   copied to $HA_PACKAGES_DIR"
code=$(curl -s -o /dev/null -w '%{http_code}' \
  -H "Authorization: Bearer $(cat /volume1/docker/.hood-vent/ha_token)" \
  -X POST "$HA_URL/api/services/homeassistant/$SERVICE")
echo "   $SERVICE -> HTTP $code"
REMOTE
echo "✅ deployed."
