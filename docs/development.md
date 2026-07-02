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

## The edit → GitHub → HA loop

1. Edit `hood_vent_package.yaml` (or docs) locally.
2. Commit and push to `main`.
3. Deploy:

   ```bash
   cp deploy.env.example deploy.env   # first time only, then fill in the token
   ./scripts/deploy.sh                # copy package in + reload_all (no restart)
   ./scripts/deploy.sh --restart      # use when you ADD/REMOVE a statistics or
                                      # derivative sensor (those don't hot-reload)
   ```

   `deploy.sh` stages the file to the NAS, `sudo docker cp`s it into the
   container (one sudo prompt), validates the config via the API, then reloads.

`deploy.env` holds a **long-lived HA token** (Profile → Security) and is
gitignored — never commit it.

### What hot-reloads vs needs a restart

`reload_all` covers `input_number`, `input_boolean`, `template`, `automation`,
and most `sensor` changes — fine for day-to-day tuning and automation edits.
A **restart** is only needed when you add or remove a `statistics` / `derivative`
sensor *platform* entry, because those legacy `sensor:` platforms don't
hot-reload.

## Optional: hands-off auto-deploy

If you'd rather not run a command each time, [`scripts/nas-sync.sh`](../scripts/nas-sync.sh)
polls this repo on the NAS and syncs on change. Set it up once:

1. Clone the repo on the NAS: `git clone … /volume1/docker/ha-hood-vent`
2. Save the token: `mkdir -p /volume1/docker/.hood-vent && echo '<token>' > /volume1/docker/.hood-vent/ha_token && chmod 600 /volume1/docker/.hood-vent/ha_token`
3. DSM → Control Panel → **Task Scheduler** → Scheduled Task → run as **root**,
   every ~5 min: `sh /volume1/docker/ha-hood-vent/scripts/nas-sync.sh`

Running as root avoids the sudo prompt; the script only touches HA when the
package file actually changed.

> A GitHub Action could do this on push instead, but it would need network
> access to the NAS (the SSH port isn't internet-exposed), so it'd require a
> self-hosted runner or a tunnel. The NAS cron above is simpler for a home LAN.

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
