#!/bin/sh
#
# nas-sync.sh — hands-off GitOps. Pulls this repo on the NAS and syncs the
# package into Home Assistant whenever it changes, then reloads HA. Runs as your
# normal user — NO sudo, NO docker — because HA's /config is a bind mount you own
# and the reload goes through HA's REST API with a long-lived token.
#
# Schedule it via DSM > Control Panel > Task Scheduler (user: your account, every
# ~5 min): sh /volume1/docker/ha-hood-vent/scripts/nas-sync.sh
#
# Config (create once):
#   /volume1/docker/.hood-vent/config    REPO_DIR, HA_PACKAGES_DIR, HA_URL
#   /volume1/docker/.hood-vent/ha_token  long-lived token, chmod 600
# See docs/development.md.

set -eu

CONF="${HOOD_VENT_CONF:-/volume1/docker/.hood-vent/config}"
TOKEN_FILE="${HOOD_VENT_TOKEN:-/volume1/docker/.hood-vent/ha_token}"
[ -f "$CONF" ] && . "$CONF"
REPO_DIR="${REPO_DIR:-/volume1/docker/ha-hood-vent}"
HA_URL="${HA_URL:-http://localhost:8123}"
: "${HA_PACKAGES_DIR:?set HA_PACKAGES_DIR in $CONF}"
PKG="hood_vent_package.yaml"

cd "$REPO_DIR"
git fetch --quiet origin main
git reset --hard --quiet origin/main

# Act only when the deployed copy differs from the repo (covers new commits and
# any manual drift). Quiet no-op otherwise, so it's cheap to run often.
if cmp -s "$REPO_DIR/$PKG" "$HA_PACKAGES_DIR/$PKG"; then
  exit 0
fi

echo "$(date '+%F %T') $PKG changed -> deploying $(git rev-parse --short HEAD)"
cp "$REPO_DIR/$PKG" "$HA_PACKAGES_DIR/$PKG"
curl -fsS -X POST \
  -H "Authorization: Bearer $(cat "$TOKEN_FILE")" \
  "$HA_URL/api/services/homeassistant/reload_all" >/dev/null
echo "$(date '+%F %T') deployed + reloaded HA"
