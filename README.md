# F-100D Super Sabre — WinWing SimAppPro Vibration Support

Adds the **F-100D Super Sabre** (Grinnelli Designs) to WinWing SimAppPro's
vibration system, so your stick and throttle shake with **AoA buffet, weapon
release, cannon fire, gear, speedbrakes and G-loading** — just like the
officially supported modules.

WinWing hasn't shipped a profile for the F-100D yet. It turns out SimAppPro's
vibration engine is completely aircraft-agnostic (it reads generic DCS export
telemetry), so all that's missing is configuration — which this project
provides, plus a small patch so the F-100D tile appears in the SimAppPro UI.

> Not affiliated with WinWing or Grinnelli Designs. No WinWing or Grinnelli
> files are redistributed — the installer copies the required templates from
> your **own** installation.

## What you get

- The **F-100D aircraft tile** in SimAppPro's vibration page (DCS platform).
- **Default vibration curves** for every WinWing vibration-capable device
  (cloned from the F-5E-3 profile — an era-appropriate supersonic gun fighter).
- Full access to SimAppPro's graphical curve editor for the F-100D, so you can
  tune every effect to your own hardware and taste.

## Requirements

- WinWing SimAppPro (tested with the July 2026 build)
- DCS World with the F-100D module
- SimAppPro's DCS export scripts already installed (the usual
  "Sync/Repair Export.lua" step in SimAppPro settings)

## Install

1. Download this repository (green **Code** button → **Download ZIP**) and
   extract it anywhere.
2. Right-click `install.ps1` → **Run with PowerShell**, and accept the
   administrator prompt (needed to patch a file inside Program Files —
   a backup is created automatically).
3. SimAppPro restarts by itself. Select **DCS** on the vibration page —
   the **F-100D** tile is now in the aircraft row.
4. Fly. Pull hard, feel the buffet.

### What the installer actually does

| Step | Change | Where |
|------|--------|-------|
| 1 | Adds `F-100D` to the aircraft list inside `app.asar` (byte-length-identical edit; original kept as `app.asar.bak`) | SimAppPro install folder |
| 2 | Creates F-100D default vibration curves by copying the F-5E-3 profile already on your machine | SimAppPro install + `%APPDATA%\SimAppPro\ShakeEffect` |
| 3 | Creates a comment-only `entry.lua` stub so SimAppPro's module scan finds the F-100D (the module itself installs under `CoreMods`, where SimAppPro doesn't look). DCS executes nothing from it. | DCS install `Mods\aircraft\F-100D` |

Everything is reversible: restore `app.asar.bak`, delete the created `F-100D`
folders, done.

## Using / tuning

- Devices in **default** mode use the F-5E-3-derived curves out of the box —
  every WinWing vibration-capable device is covered.
- Switch a device to **Advanced** in SimAppPro to edit the curves in the
  graphical editor once the F-100D tile is selected — AoA buffet onset,
  gun-fire intensity, touchdown thump, all of it is tunable to your taste.
- Your tuned curves are saved under
  `%APPDATA%\SimAppPro\ShakeEffect\active\DCS\F-100D\` and survive both
  SimAppPro updates and re-runs of the installer.

## Known limitations

- **SimAppPro updates undo the patch** (they replace `app.asar` and the
  default profile folders). Just run `install.ps1` again. Your tuned profiles
  in `%APPDATA%` survive updates.
- A DCS **repair** may list the detection stub as an extra file — that's ours,
  it's harmless, and repair only removes it if you ask it to clean extras
  (re-run the installer to recreate it).
- If WinWing ships official F-100D support, this project becomes obsolete —
  the installer detects the official entry and skips the patch.

## How it works (the long version)

SimAppPro's DCS export script (`Scripts\wwt\wwtExport.lua`) reports the current
aircraft's internal name (`F-100D`) over a local socket. The vibration engine
(`ShakeEffect\effect\DCS\VibrationEffect_V1.5.js`) evaluates generic DCS export
API calls — `LoGetAngleOfAttack()`, `LoGetPayloadInfo()`, `LoGetMechInfo()`,
`LoGetAccelerationUnits()` — and maps them through per-aircraft, per-device
curve files stored as plain JSON. In-game vibration works for *any* module the
moment those folders exist. Only the UI's aircraft tile row is gated: it scans
the DCS install's `Mods\aircraft` folder and filters it through a hardcoded
name map inside `app.asar`. The F-100D fails both checks — its files install
under `CoreMods\aircraft`, which the scan never reads — hence the one-line map
patch and the detection stub.

## Credits

- Research and testing: MichaelJackson3010
- Reverse engineering done with Claude (Anthropic)
- Thanks to Grinnelli Designs for the Super Sabre and WinWing for hardware
  that shakes
