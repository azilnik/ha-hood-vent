# How It Works

Most automations watch for a **temperature threshold** (e.g., "turn on when kitchen hits 26 °C"). This is slow because temperature lags behind actual cooking activity.

This package watches the **rate of change** — how many degrees the temperature changes per minute. It uses Home Assistant's built-in [derivative sensor](https://www.home-assistant.io/integrations/derivative/) to calculate this over a 2-minute rolling window.

```mermaid
flowchart LR
    subgraph Sensors
        T["Temperature\nSensor"]
        H["Humidity\nSensor"]
    end

    subgraph HA["Home Assistant — Derivative Calculation"]
        D["Derivative Sensor\n(2-min rolling window)"]
    end

    subgraph Logic["Rate-of-Change Logic"]
        ON{"Rate > 0.5°/min?\nor humidity rising?"}
        OFF{"Rate < 0.1°/min\nfor 2+ minutes?"}
    end

    subgraph Action
        HON["Hood ON"]
        HOFF["Hood OFF"]
    end

    T --> D
    H --> D
    D --> ON
    D --> OFF
    ON -- Yes --> HON
    OFF -- Yes --> HOFF

    style T fill:#ff6b6b,color:#fff
    style H fill:#4ecdc4,color:#fff
    style HON fill:#2ecc71,color:#fff
    style HOFF fill:#e74c3c,color:#fff
```

## Why Rate of Change Works Better

| Scenario | Threshold-based | Rate-of-change (this project) |
|----------|----------------|-------------------------------|
| Start cooking | Waits until kitchen heats up (5–10 min) | Detects rising temp within 30–60 sec |
| Stop cooking | Waits for kitchen to cool down (10–15 min) | Detects rate dropping within 2–3 min |
| Hot day, kitchen already warm | May trigger falsely | Ignores — temp isn't *changing* fast |
| Open oven to check food | May trigger from heat blast | Brief spike smoothed by 2-min window |

## Key Integrations Used

- [Derivative sensor](https://www.home-assistant.io/integrations/derivative/) — calculates rate of change from raw temperature readings
- [Template sensor](https://www.home-assistant.io/integrations/template/) — combines temperature and humidity rate signals
- [Automation](https://www.home-assistant.io/docs/automation/) — triggers the hood on/off based on rate thresholds
