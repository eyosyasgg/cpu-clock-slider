# CPU Clock Speed (Omarchy Plugin)

A native bar widget and popup panel for Omarchy Quattro that allows toggling CPU clock speed tiers: **50%** (1.0 GHz), **70%** (1.4 GHz), and **100%** (2.0 GHz).

Matches the Windows "Maximum processor state" functionality on Linux using the kernel `intel_pstate` driver and `cpufreq` scaling ceilings.

---

## Features

- **Bar Widget**: Displays a clean hardware microchip CPU icon (``). Fits alongside native system icons.
- **3 Simple Tiers**:
  - `50%` (1.0 GHz) — Eco / Maximum battery savings and low temperatures.
  - `70%` (1.4 GHz) — Balanced daily performance.
  - `100%` (2.0 GHz) — Full unrestricted performance.
- **Scroll Wheel Support**: Scroll your mouse wheel directly over the CPU icon to step between 50%, 70%, and 100%.
- **Keyboard Navigation**: Press <kbd>Left</kbd> / <kbd>Right</kbd> to step down / up, and <kbd>Esc</kbd> to dismiss the panel.
- **Theme-Integrated**: Uses Omarchy Quattro styling tokens (`Style`, `Color`, `qs.Ui`).

---

## File Structure

```text
cpu-clock-slider/
├── manifest.json       # Plugin manifest declaring bar-widget contract
├── BarWidget.qml       # Bar button entry point with CPU icon & wheel controls
├── Panel.qml           # Keyboard-anchored dropdown panel with 3 toggles
├── bin/
│   └── cpu-limit-ctl   # Optional CLI control script
├── LICENSE
└── README.md
```

---

## Testing & Validation

```bash
# Validate manifest structure and entry points
omarchy plugin validate .

# Lint QML files against Omarchy shell imports
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml
```