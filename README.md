# Smart Hood Vent Automation for Home Assistant

Automatically control your range hood based on stove activity using rate-of-change detection—no hardwired stove integration required.

## The Problem

Traditional temperature-threshold automations are sluggish for hood vents. Temperature is a lagging indicator: by the time your kitchen hits 25°C, you've been cooking for a while. And when you stop cooking, residual heat keeps the sensor warm long after the stove is off.

## The Solution

This package detects **rate of change** instead of absolute temperature. When the stove is actively heating, temperature rises quickly. When it's off, the rate plateaus or goes negative—even if the kitchen is still warm.

**Result:** Hood turns on within 30–60 seconds of starting to cook, and turns off within 2–3 minutes of stopping (instead of 10–15 minutes with threshold-based approaches).

## Hardware Requirements

| Component | Purpose | Approx. Price |
|-----------|---------|---------------|
| [Third Reality Zigbee Temperature & Humidity Sensor](https://www.amazon.com/THIRDREALITY-Zigbee-Temperature-Humidity-Sensor/dp/B0BN32XX24?tag=YOUR_TAG) | Detects cooking activity via temp/humidity changes | ~$20 |
| [SwitchBot Bot](https://www.amazon.com/SwitchBot-switch-button-controlled-compatible/dp/B07B7NXV4R?tag=YOUR_TAG) + [SwitchBot Hub](https://www.amazon.com/SwitchBot-Thermometer-Hygrometer-Bluetooth-Temperature/dp/B07TTH451R?tag=YOUR_TAG) | Physically presses your existing hood vent button | ~$30 + ~$40 |
| [SMLIGHT SLZB-06](https://www.amazon.com/SMLIGHT-SLZB-06-Coordinator-Zigbee2MQTT-Assistant/dp/B0BL6DQSB3?tag=YOUR_TAG) | Zigbee coordinator (Ethernet/USB/WiFi with PoE) | ~$45 |

**Total:** ~$135 (one-time, no subscription)

### Alternative Hardware

**Zigbee Coordinators:**
- [SONOFF Zigbee 3.0 USB Dongle Plus](https://www.amazon.com/SONOFF-Zigbee-Gateway-Universal-Assistant/dp/B09KXTCMSC) — Budget option (~$25)
- [SMLIGHT SLZB-06M](https://www.amazon.com/SMLIGHT-SLZB-06M-Ethernet-Zigbee2MQTT-Assistant/dp/B0CLCGV1RZ) — EFR32 chip variant

**Temperature Sensors:**
- [Third Reality Temp/Humidity Sensor Lite](https://www.amazon.com/THIRDREALITY-Temperature-Humidity-Sensor-Lite/dp/B0F6CKHHDV) — No LCD, same accuracy (~$15)
- [SONOFF SNZB-02](https://www.amazon.com/SONOFF-SNZB-02-Temperature-Humidity-Sensor/dp/B08BCHRH1P) — Compact alternative (~$12)

**Hood Control:**
- Any Zigbee smart switch if your hood is hardwired
- Shelly relay if you want to wire directly into the hood

## Installation

### 1. Set Up Packages Directory

If you don't have a packages folder, create one:

```bash
mkdir -p /config/packages
```

Add to your `configuration.yaml`:

```yaml
homeassistant:
  packages:
    hood_vent: !include packages/hood_vent_package.yaml
```

### 2. Configure Entity IDs

Copy `hood_vent_package.yaml` to your packages directory and update these entity IDs to match your setup:

```yaml
# Find these in Developer Tools → States
sensor.stovetop_temperature      # Your Zigbee temp sensor
sensor.stovetop_humidity         # Your Zigbee humidity sensor
switch.range_hood_vent           # Your SwitchBot/switch entity
```

### 3. Restart Home Assistant

Go to **Settings → System → Restart** to load the new package.

### 4. Add Dashboard Card

Copy the contents of `lovelace_card.yaml` into your dashboard:

1. Go to your dashboard → Edit → Add Card
2. Select "Manual" or "Custom: Manual YAML"
3. Paste the card configuration

## Sensor Placement

For best results, mount the temperature sensor:

- **6–12 inches above the stovetop** on a cabinet or wall
- **Not directly above a burner** (too hot, readings will spike unrealistically)
- **Not near the hood exhaust** (airflow disrupts readings)
- **Away from windows/vents** (drafts cause false triggers)

The sensor needs to detect the thermal plume from cooking, not direct burner heat.

## Tuning

The package includes adjustable thresholds via the UI:

| Threshold | Default | What It Does |
|-----------|---------|--------------|
| Temp Rise Threshold | 0.5°/min | Rate of temp increase to trigger ON |
| Humidity Rise Threshold | 1.0%/min | Rate of humidity increase to trigger ON |
| Temp Fall Threshold | 0.1°/min | Rate below this = cooling detected |
| Off Delay | 2 min | How long cooling must persist before OFF |

### Tuning Process

1. Cook something with automation disabled
2. Watch the rate-of-change values in the dashboard
3. Note peak values during active cooking (typically 0.3–1.0°/min)
4. Set ON threshold just below your observed peak
5. Note when rate drops after stopping (usually goes near-zero or negative)
6. Adjust OFF threshold and delay accordingly

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   Temperature    ┌──────────────┐    Rate of Change             │
│   Sensor    ───▶ │  Derivative  │ ───▶  > 0.5°/min?  ───▶ ON    │
│                  │   Sensor     │                                │
│   Humidity       │  (2 min      │       < 0.1°/min              │
│   Sensor    ───▶ │   window)    │ ───▶  for 2 min?   ───▶ OFF   │
│                  └──────────────┘                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

The derivative sensor calculates how fast temperature is changing over a 2-minute rolling window. This smooths out sensor noise while remaining responsive to actual cooking activity.

## Features

- **Rate-of-change detection** — Responds to cooking activity, not absolute temperature
- **Dual triggers** — Uses both temperature and humidity for reliability
- **Adjustable thresholds** — Tune via UI sliders without editing YAML
- **Manual override detection** — Pauses automation for 30 min if you manually toggle the hood
- **Safety shutoff** — Auto-off after 2 hours maximum runtime
- **Dashboard card** — Monitor derivative values for tuning

## Files

| File | Purpose |
|------|---------|
| `hood_vent_package.yaml` | Main configuration (sensors, automations, inputs) |
| `lovelace_card.yaml` | Dashboard card for monitoring and tuning |

## Troubleshooting

### Hood doesn't turn on
- Check that your temperature sensor is reporting (not "unavailable")
- Lower the `hood_temp_rise_threshold` value
- Verify `input_boolean.hood_automation_enabled` is ON

### Hood turns on too easily
- Raise the `hood_temp_rise_threshold` value
- Check sensor placement—may be too close to stove or in a draft

### Hood stays on too long
- Lower the `hood_off_delay_minutes` value
- Check that your hood switch entity is correctly configured

### Sensor shows "unavailable"
- Check battery (AAA or CR2450 depending on model)
- Re-pair the device in ZHA: **Settings → Devices & Services → ZHA → Configure → Add Device**
- Ensure Zigbee mesh has repeaters (smart plugs work well) between coordinator and sensor

## Contributing

Issues and PRs welcome. If you adapt this for different hardware or improve the detection algorithm, please share!

## License

MIT License — use freely, attribution appreciated.

---

**Note on Affiliate Links:** Links to Amazon products include affiliate tags. If you'd prefer not to use them, simply remove the `?tag=YOUR_TAG` portion of each URL. The products work the same either way.
