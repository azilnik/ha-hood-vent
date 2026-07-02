#!/bin/sh
#
# nas-sync.sh — OPTIONAL full-auto GitOps: pull the repo on the NAS and sync
# the package into Home Assistant. Designed to run ON the Synology as root,
# on a schedule (DSM > Control Panel > Task Scheduler > Scheduled Task, user
# root, run every N minutes). See docs/development.md for setup.
#
# It only touches HA when the package file actually changed, so it's cheap to
# run often. Requires:
#   - a git checkout of this repo on the NAS  (REPO_DIR)
#   - the HA long-lived token in TOKEN_FILE   (chmod 600)
#
# This is the hands-off alternative to running scripts/deploy.sh from your Mac.

set -eu

REPO_DIR="${REPO_DIR:-/volume1/docker/ha-smart-hood-vent}"
TOKEN_FILE="${TOKEN_FILE:-/volume1/docker/.hood-vent/ha_token}"
HA_URL="${HA_URL:-http://localhost:8123}"
HA_CONFIG_PACKAGES="${HA_CONFIG_PACKAGES:-/config/packages}"
PACKAGE="hood_vent_package.yaml"

cd "$REPO_DIR"

before=$(git rev-parse HEAD)
git fetch --quiet origin main
git reset --hard --quiet origin/main
after=$(git rev-parse HEAD)

# Only act if the package file changed between before/after (or on first run).
if [ "$before" = "$after" ] && git diff --quiet "$before" "$after" -- "$PACKAGE"; then
  exit 0
fi
if git diff --quiet "$before" "$after" -- "$PACKAGE"; then
  exit 0
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') package changed ($before -> $after), syncing"

CID=$(docker ps --format '{{.ID}} {{.Image}}' | grep -i homeassistant | awk '{print $1}' | head -1)
[ -n "$CID" ] || { echo "no homeassistant container"; exit 1; }

docker cp "$REPO_DIR/$PACKAGE" "$CID:$HA_CONFIG_PACKAGES/$PACKAGE"

TOKEN=$(cat "$TOKEN_FILE")
curl -fsS -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -X POST "$HA_URL/api/services/homeassistant/reload_all" >/dev/null

echo "$(date '+%Y-%m-%d %H:%M:%S') synced $PACKAGE and reloaded HA"
