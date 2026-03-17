# Tuning the Sensitivity

Every kitchen is different — sensor distance from the stove, ventilation, stove type (gas vs. electric vs. induction) all affect the readings. The [dashboard card](dashboard.md) includes sliders to adjust thresholds without editing YAML.

## Default Thresholds

| Setting | Default | What it controls |
|---------|---------|-----------------|
| Temp Rise Threshold | 0.5 °/min | How fast temp must rise to trigger the hood ON |
| Humidity Rise Threshold | 1.0 %/min | How fast humidity must rise to trigger ON |
| Temp Fall Threshold | 0.1 °/min | Rate below this means cooking has stopped |
| Off Delay | 2 min | How long the rate must stay low before the hood turns OFF |

## How to Tune

1. **Turn off the automation** — toggle `input_boolean.hood_automation_enabled` to OFF
2. **Cook something** — boil water, pan-fry, whatever you normally make
3. **Watch the dashboard** — observe the "Temp Rate" and "Humidity Rate" values
4. **Note the peaks** — during active cooking, temp rate is typically 0.3–1.0 °/min
5. **Set the ON threshold** just below your observed peaks (e.g., if you see 0.6 °/min, set to 0.4)
6. **Turn off the stove** and watch the rate drop — it usually falls near zero within a minute or two
7. **Adjust the OFF threshold and delay** based on how quickly the rate drops
8. **Re-enable the automation** and test with real cooking

> **Too sensitive?** Raise the temp rise threshold. **Not sensitive enough?** Lower it. Start conservative (higher threshold) and work down.
