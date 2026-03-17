# Troubleshooting

<details>
<summary><strong>Hood doesn't turn on when I cook</strong></summary>

1. **Check the sensor is reporting.** Go to **Developer Tools → States**, find your temperature sensor entity, and confirm it shows a number (not "unavailable" or "unknown"). If it's unavailable, see the sensor section below.
2. **Check the automation is enabled.** Search for `input_boolean.hood_automation_enabled` in Developer Tools → States. It should be `on`.
3. **Check the rate value.** Search for `sensor.kitchen_temp_rate_of_change` — is it rising while you cook? If it stays near zero, the sensor may be too far from the stove.
4. **Lower the threshold.** Try setting `hood_temp_rise_threshold` to `0.3` or even `0.2` and cook again.
5. **Check the automation trace.** Go to **Settings → Automations**, find "Hood Vent: Auto On", and click the three-dot menu → **Traces**. This shows you exactly why the automation did or didn't fire. [Learn about traces](https://www.home-assistant.io/docs/automation/troubleshooting/).
</details>

<details>
<summary><strong>Hood turns on too easily (false triggers)</strong></summary>

1. **Raise the threshold.** Increase `hood_temp_rise_threshold` to `0.7` or `1.0`.
2. **Check sensor placement.** Is it near a window, HVAC vent, or in direct sunlight? These cause temperature fluctuations that look like cooking.
3. **Check the 30-second confirmation.** The automation waits 30 seconds of sustained rising before triggering. If you're still getting false triggers, the rate is genuinely above threshold for that long — raise it further.
</details>

<details>
<summary><strong>Hood stays on too long after cooking</strong></summary>

1. **Lower the off delay.** Reduce `hood_off_delay_minutes` to `1`.
2. **Check the fall threshold.** If `hood_temp_fall_threshold` is too low (e.g., `0.0`), the rate needs to literally stop changing before the hood turns off. Try `0.15`.
3. **Check the hood switch entity.** Make sure HA can actually turn the hood off. Test manually: go to Developer Tools → Services, call `switch.turn_off` on your hood entity.
</details>

<details>
<summary><strong>Sensor shows "unavailable"</strong></summary>

1. **Check the battery.** Third Reality sensors use CR2450 coin cells; SONOFF sensors use CR2032. Low battery is the most common cause.
2. **Check Zigbee connectivity.** Go to **Settings → Devices & Services → ZHA** (or Zigbee2MQTT). Click your sensor and check "Last Seen." If it's been a while, re-pair: **ZHA → Configure → Add Device**. [ZHA troubleshooting guide](https://www.home-assistant.io/integrations/zha/#troubleshooting).
3. **Improve mesh coverage.** Zigbee uses a mesh network — each mains-powered Zigbee device (like a smart plug) acts as a repeater. If your sensor is far from the coordinator, add a Zigbee smart plug between them. [Understanding Zigbee mesh](https://www.home-assistant.io/integrations/zha/#best-practices-to-avoid-pairing-difficulties).
</details>

<details>
<summary><strong>I don't see the derivative sensors after restart</strong></summary>

1. **Check for YAML errors.** Go to **Developer Tools → YAML** and click "Check Configuration." Fix any errors before restarting.
2. **Verify the package include.** Make sure your `configuration.yaml` has the `packages:` section under `homeassistant:` and the path matches where you put the file.
3. **Check your secrets.yaml.** If an entity ID is misspelled in `secrets.yaml`, the derivative sensor will appear but show "unavailable." Double-check the spelling of all three values.
</details>

## Useful Resources

- [Home Assistant documentation](https://www.home-assistant.io/docs/) — the official reference
- [HA Community forums](https://community.home-assistant.io/) — ask questions, share projects
- [HA subreddit](https://www.reddit.com/r/homeassistant/) — r/homeassistant
- [Everything Smart Home (YouTube)](https://www.youtube.com/@EverythingSmartHome) — beginner-friendly HA tutorials
- [Smart Home Junkie (YouTube)](https://www.youtube.com/@SmartHomeJunkie) — step-by-step HA guides
- [Derivative sensor docs](https://www.home-assistant.io/integrations/derivative/) — the HA integration this project is built on
- [Template sensor docs](https://www.home-assistant.io/integrations/template/) — how the rate-of-change sensors work
- [Automation docs](https://www.home-assistant.io/docs/automation/) — understanding HA automations
