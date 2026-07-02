# Development & Deployment

How this repo maps onto the running Home Assistant instance, and how to get
your edits from GitHub into HA with minimal fuss.

## Architecture

- **Home Assistant** runs as a Docker container (`linuxserver/homeassistant`,
  **no Supervisor / add-ons**) on a Synology NAS, reached at `ha.zilnik.me`
  through a Cloudflare tunnel.
- HA's `/config` is a **root-owned Docker named volume**, so config files are
  written into the container with `sudo docker cp` — you can't just edit them
  as the SSH user.
- The package is wired in via `configuration.yaml`:

  ```yaml
  homeassistant:            # must be lowercase — a capital H silently voids it
    packages:
      hood_vent: !include packages/hood_vent_package.yaml
  ```

- Everything the feature needs (helpers, template sensor, derivative/statistics
  sensors, automations) lives in the single [`hood_vent_package.yaml`](../hood_vent_package.yaml).
- The dashboard is **storage-mode** (UI-managed), not a YAML file HA reads.
  [`lovelace_card.yaml`](../lovelace_card.yaml) is a reference card to paste in,
  not something `deploy.sh` pushes.

## One-time setup on the NAS

HA's `/config` is a bind mount owned by the SSH user, so deploys need **no sudo
and no docker** — just copy the file and hit the reload API. Create a small
config + token the scripts read:

```bash
mkdir -p /volume1/docker/.hood-vent
cat > /volume1/docker/.hood-vent/config <<'EOF'
REPO_DIR="/volume1/docker/ha-hood-vent"
HA_PACKAGES_DIR="/path/to/your/ha/config/packages"   # HA's /config/packages on the host
HA_URL="http://localhost:8123"
EOF
# long-lived token: HA > Profile > Security > Long-lived access tokens
printf '%s' '<TOKEN>' > /volume1/docker/.hood-vent/ha_token
chmod 600 /volume1/docker/.hood-vent/ha_token
git clone https://github.com/azilnik/ha-hood-vent.git /volume1/docker/ha-hood-vent
```

## The edit → GitHub → HA loop

1. Edit `hood_vent_package.yaml` (or docs) locally.
2. Commit → PR → merge to `main`.
3. Deploy — either:
   - From your Mac: `./scripts/deploy.sh` (or `--restart`). Stages the file over
     SSH, copies it into the bind mount, validates, and reloads.
   - Or just let the auto-sync pick it up (below).

### What hot-reloads vs needs a restart

`reload_all` covers `input_number`, `input_boolean`, `template`, `automation`,
and most `sensor` changes — fine for day-to-day tuning and automation edits.
A **restart** (`deploy.sh --restart`) is only needed when you add or remove a
`statistics` / `derivative` sensor *platform* entry, because those legacy
`sensor:` platforms don't hot-reload.

## Hands-off auto-deploy

[`scripts/nas-sync.sh`](../scripts/nas-sync.sh) pulls `main` on the NAS and
deploys the package whenever it changes — no sudo, runs as your normal user.
Schedule it in **DSM → Control Panel → Task Scheduler → Scheduled Task**, run as
your account (not root), every ~5 min:

```
sh /volume1/docker/ha-hood-vent/scripts/nas-sync.sh
```

It's a quiet no-op unless the deployed copy differs from `main`, so it's cheap to
run often. Merge a PR → within ~5 min it's live in HA.

> A GitHub Action could do this on push instead, but it would need network
> access to the NAS (the SSH port isn't internet-exposed), so it'd require a
> self-hosted runner or a tunnel. The NAS task above is simpler for a home LAN.

## Why not HACS?

HACS installs **custom integrations** (Python components), **Lovelace frontend
plugins**, and **themes** from GitHub. It has **no category for a YAML config
package** like this one — helpers, templates, and automations aren't an
integration. So HACS can't deploy this project; the copy-in flow above is the
right mechanism.

HACS *is* relevant in one spot: the fancy version of the dashboard card uses
`custom:mini-graph-card`, a HACS frontend plugin. It is **not currently
installed** on this instance, so use the built-in-card dashboard (what's live
now) — or install mini-graph-card via HACS if you want the graph. Converting
the package into a HACS custom integration would be a full Python rewrite and
isn't worth it for config this simple.

## The one gotcha that bit us

If the package "isn't loading" (helpers/sensors missing but automations present),
check `configuration.yaml` for a capital-H `Homeassistant:` — HA only recognizes
lowercase `homeassistant:`, and silently ignores everything under the wrong-case
key, including `packages:`. `Developer Tools → YAML → Check configuration`
surfaces it as *"Integration 'Homeassistant' not found."*
