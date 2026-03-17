# Dashboard Card

The dashboard card gives you a control panel with current readings, rate-of-change graphs, and tuning sliders.

## Step 1: (Optional) Install mini-graph-card

The full dashboard card uses [mini-graph-card](https://github.com/kalkih/mini-graph-card) from [HACS](https://hacs.xyz/) for rate-of-change visualization. This is optional — a simpler alternative card that works without HACS is included in the file.

If you want the enhanced graphs:
1. [Install HACS](https://hacs.xyz/docs/use/) if you don't have it
2. In HACS, search for "Mini Graph Card" and install it
3. Restart Home Assistant

## Step 2: Add the Card

1. Open [`lovelace_card.yaml`](../lovelace_card.yaml) from this repo
2. **Find-and-replace** the 3 placeholder entity IDs with the same values you put in `secrets.yaml` (`!secret` doesn't work in the dashboard UI editor, so this is the one place you do a manual replacement)
3. In your HA dashboard, click **Edit** (pencil icon top-right) → **Add Card** → scroll down to **Manual**
4. Paste the updated YAML
5. Save

> **New to dashboards?** See [HA's dashboard guide](https://www.home-assistant.io/dashboards/) for the basics.
