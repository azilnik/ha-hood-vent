#!/usr/bin/env bash
#
# deploy.sh — push the local hood-vent package to the running Home Assistant
# instance and reload it, in one command.
#
# HA here runs as a Docker container (linuxserver/homeassistant, no Supervisor)
# on a Synology NAS. Its /config is a root-owned named volume, so the package
# file is copied in with `sudo docker cp` over SSH (you'll be prompted for the
# NAS sudo password once), then HA is told to reload via its REST API.
#
# Usage:
#   ./scripts/deploy.sh              # copy package + reload_all (no restart)
#   ./scripts/deploy.sh --restart    # copy package + full HA restart
#                                    # (needed when you ADD/REMOVE a statistics
#                                    #  or derivative sensor platform — those
#                                    #  don't hot-reload)
#
# Config lives in deploy.env (gitignored). Copy deploy.env.example to start.

set -euo pipefail

cd "$(dirname "$0")/.."   # repo root

# ---- load config -----------------------------------------------------------
if [[ ! -f deploy.env ]]; then
  echo "error: deploy.env not found. Copy deploy.env.example to deploy.env and fill it in." >&2
  exit 1
fi
# shellcheck disable=SC1091
source deploy.env

: "${NAS_SSH_HOST:?set NAS_SSH_HOST in deploy.env}"
: "${NAS_STAGING:?set NAS_STAGING in deploy.env}"
: "${HA_CONFIG_PACKAGES:?set HA_CONFIG_PACKAGES in deploy.env}"
: "${HA_URL:?set HA_URL in deploy.env}"
: "${HA_TOKEN:?set HA_TOKEN in deploy.env}"

PACKAGE="hood_vent_package.yaml"
RESTART=false
[[ "${1:-}" == "--restart" ]] && RESTART=true

# ---- warn on uncommitted changes ------------------------------------------
if ! git diff --quiet -- "$PACKAGE" 2>/dev/null; then
  echo "note: $PACKAGE has uncommitted changes — deploying the working-tree version."
fi

# ---- 1. stage to NAS -------------------------------------------------------
echo "==> staging $PACKAGE to $NAS_SSH_HOST:$NAS_STAGING"
scp -O "$PACKAGE" "$NAS_SSH_HOST:$NAS_STAGING/$PACKAGE"

# ---- 2. copy into the container (resolves container by image, needs sudo) --
echo "==> copying into the Home Assistant container (sudo on the NAS)"
ssh -t "$NAS_SSH_HOST" "sudo sh -c '
  CID=\$(docker ps --format \"{{.ID}} {{.Image}}\" | grep -i homeassistant | awk \"{print \\\$1}\" | head -1)
  if [ -z \"\$CID\" ]; then echo \"no running homeassistant container found\" >&2; exit 1; fi
  echo \"   container: \$CID\"
  docker cp \"$NAS_STAGING/$PACKAGE\" \"\$CID:$HA_CONFIG_PACKAGES/$PACKAGE\"
  echo \"   copied to \$CID:$HA_CONFIG_PACKAGES/$PACKAGE\"
'"

# ---- 3. reload or restart HA via the API ----------------------------------
auth=(-H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json")

# validate config first
echo "==> checking configuration"
check=$(curl -fsS "${auth[@]}" -X POST "$HA_URL/api/config/core/check_config")
result=$(printf '%s' "$check" | sed -n 's/.*"result": *"\([^"]*\)".*/\1/p')
if [[ "$result" != "valid" ]]; then
  echo "error: config check did not return valid:" >&2
  echo "$check" >&2
  exit 1
fi
echo "   config valid"

if $RESTART; then
  echo "==> restarting Home Assistant"
  curl -fsS "${auth[@]}" -X POST "$HA_URL/api/services/homeassistant/restart" >/dev/null
  echo "   restart requested"
else
  echo "==> reloading all YAML (no restart)"
  curl -fsS "${auth[@]}" -X POST "$HA_URL/api/services/homeassistant/reload_all" >/dev/null
  echo "   reload_all done"
fi

echo "✅ deployed."
