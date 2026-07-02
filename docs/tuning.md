# Tuning the Sensitivity

Every kitchen is different — sensor distance from the stove, ventilation, stove type (gas vs. electric vs. induction) all affect the readings. The [dashboard card](dashboard.md) includes sliders to adjust thresholds without editing YAML.

## Default Thresholds

| Setting | Default | What it controls |
|---------|---------|-----------------|
| Temp Rise Threshold | 0.5 °/min | How fast temp must rise to trigger the hood ON |
| Humidity Rise Threshold | 1.0 %/min | How fast humidity must rise to trigger ON |
| Temp Fall Threshold | 0.1 °/min | Rate below this means cooking has stopped |
| Off Delay | 2 min | How long the rate must stay low before the hood turns OFF |
| On Confirmation | 60 s | How long activity must be sustained before the hood turns ON |
| Warm Ambient Baseline | 24 °C | Kitchen temp above which summer desensitization kicks in |
| Warm Ambient Boost | 0 ×/°C (off) | How much to stiffen the ON thresholds per °C above the baseline. **Opt-in — off by default.** |

## Rejecting Warm-Weather False Triggers

In summer the kitchen sits warmer and more humid, and there's more background
noise — AC cycling, open windows, hot humid air drifting in, even someone
breathing near the sensor. Any of that can briefly look like cooking. Three
mechanisms keep it from switching the hood:

1. **Smoothing** — the rate of change is averaged over a 3-minute window, so a
   single breath or a brief gust barely moves the needle.
2. **Confirmation** — activity has to stay above threshold for the full **On
   Confirmation** time (60 s by default) before the hood turns on. Transients
   don't last that long; real cooking does.
3. **Warm-ambient boost** *(opt-in — off by default)* — the automation watches
   the kitchen's *smoothed ambient temperature* (`sensor.kitchen_temp_average`).
   For every degree it sits above the **Warm Ambient Baseline**, the ON
   thresholds are multiplied up by the **Warm Ambient Boost**. Effective
   threshold = base × (1 + degrees‑above‑baseline × boost).

   > ⚠️ **Only enable this if your temperature sensor reads true room ambient**
   > (a wall/room sensor). If it's mounted on or near the stovetop — the common
   > setup — its 30-minute mean is polluted by the cooking heat itself, so a
   > positive boost *desensitizes detection while you're cooking*, which is
   > backwards. On a stovetop-mounted sensor, leave Warm Ambient Boost at **0**
   > and rely on smoothing + confirmation above.

   | Kitchen ambient | Season (Toronto) | Effective temp threshold | Effective humidity threshold |
   |-----------------|------------------|--------------------------|------------------------------|
   | 20 °C | Winter | 0.50 °/min (unchanged) | 1.00 %/min (unchanged) |
   | 24 °C | Spring/Fall | 0.50 °/min | 1.00 %/min |
   | 28 °C | Summer | 0.62 °/min | 1.24 %/min |
   | 32 °C | Heat wave | 0.74 °/min | 1.48 %/min |

   The table above shows the effect *when enabled*. With a room-ambient sensor,
   the boost is zero until the kitchen is genuinely warm, so **winter
   sensitivity is untouched** — you're only trading a little summer twitchiness
   for a stiffer trigger on hot days.

**Enabling it (room-ambient sensors only):** raise **Warm Ambient Boost** to
~0.06 and set **Warm Ambient Baseline** to your normal spring/fall room temp.
Then, still getting summer false triggers? Raise the boost (e.g. 0.10) or lower
the baseline. Summer cooking not detected? Lower the boost or raise the baseline.

## How to Tune

1. **Turn off the automation** — toggle `input_boolean.hood_automation_enabled` to OFF
2. **Cook something** — boil water, pan-fry, whatever you normally make
3. **Watch the dashboard** — observe the "Temp Rate" and "Humidity Rate" values

   Here's what a typical cooking session looks like — the rate-of-change graph (middle) is what you're tuning against:

   ![Dashboard during a cooking session](images/dashboard-cooking-session.png)

4. **Note the peaks** — during active cooking, temp rate is typically 0.3–1.0 °/min
5. **Set the ON threshold** just below your observed peaks (e.g., if you see 0.6 °/min, set to 0.4)
6. **Turn off the stove** and watch the rate drop — it usually falls near zero within a minute or two
7. **Adjust the OFF threshold and delay** based on how quickly the rate drops
8. **Re-enable the automation** and test with real cooking

> **Too sensitive?** Raise the temp rise threshold. **Not sensitive enough?** Lower it. Start conservative (higher threshold) and work down.
