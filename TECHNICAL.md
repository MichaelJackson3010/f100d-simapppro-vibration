# SimAppPro vibration internals — technical reference

Audience: module developers and anyone integrating an aircraft with WinWing
SimAppPro's vibration ("ShakeEffect") system. Everything below comes from
black-box inspection of the July 2026 SimAppPro build on Windows; paths assume
a default install.

## 1. Architecture / data flow

```
DCS mission runtime
  └─ Saved Games\DCS\Scripts\wwt\wwtExport.lua        (installed by SimAppPro)
       │  generic Export.lua hook, aircraft-agnostic
       │  JSON messages over a local socket (wwtNetwork.lua)
       ▼
SimAppPro main process  (app.asar: mainsrc/DCSShakeEffect.js)
       │  loads per-aircraft, per-device curve files (plain JSON on disk)
       │  evaluates effect engine (user-editable JS, see §2)
       ▼
WWTHID → vibration motors in the grips/handles
```

The **only aircraft identifier** the vibration engine ever uses is
`LoGetSelfData().Name`, sent by the export script as
`{"func":"mod","msg":"<name>"}` whenever it changes. For the F-100D this is
`F-100D` (from the module's `make_flyable("F-100D", ...)`).

## 2. The effect engine is aircraft-agnostic

`%APPDATA%\SimAppPro\ShakeEffect\effect\DCS\VibrationEffect_V1.5.js` defines
every effect in terms of **generic DCS export API calls** — no per-aircraft
code:

| Data source (`directParam`) | DCS export call |
|---|---|
| gearValue / gear rods | `LoGetMechInfo().gear.*` |
| cannonShellsCount | `LoGetPayloadInfo().Cannon.shells` |
| payloadStations | `LoGetPayloadInfo().Stations` |
| accelerationX/Y/Z | `LoGetAccelerationUnits().*` |
| trueAirSpeed | `LoGetTrueAirSpeed()` |
| speedbrakesValue | `LoGetMechInfo().speedbrakes.value` |
| angleOfAttack | `LoGetAngleOfAttack()` |
| control surfaces | `LoGetMechInfo().controlsurfaces.*` |
| verticalVelocity | `LoGetVerticalVelocity()` |

Derived (`indirectParam`) values — gear-touch, cannon-fire detection, payload
present/absent, AoA rate — are computed from the above. The effect tree
(`treeLeaf`) wires these into the effects users see: gear in flight / touch
down, cannon fire, payload release, speedbrakes, control surfaces, 3-axis
G-loading (with/without payload), AoA and AoA-rate buffet (with/without
payload), true airspeed, engine thrust, vertical velocity.

**Consequence: any module that implements the standard DCS export API gets
full vibration support the moment configuration files exist for it.** The
F-100D needs nothing added on the module side.

## 3. Per-aircraft configuration folders

| Location | Role |
|---|---|
| `<SimAppPro>\resources\app.asar.unpacked\Events\DynamicVibrationMotor\DCS\<Aircraft>\` | shipped defaults (master; synced to the folder below at app start) |
| `%APPDATA%\SimAppPro\ShakeEffect\default\DCS\<Aircraft>\` | working copy of defaults |
| `%APPDATA%\SimAppPro\ShakeEffect\active\DCS\<Aircraft>\` | user-tuned curves (devices in "Advanced" mode) |

- `<Aircraft>` must equal `LoGetSelfData().Name` (after the alias table in
  `DCSShakeEffect.js` — e.g. `CH-47Fbl1`→`CH-47F`, `Su-25`→`Su-25A`).
- Each file inside is named `<DEVICE NAME>{<GUID>}`. Matching is done by the
  name **before** `{` only (`fileName.slice(0, fileName.indexOf('{')) ==
  part.name`); the GUID is ignored, so files are portable between machines.
- Per device, SimAppPro reads `active\...` when the device is in Advanced
  mode, `default\...` in Default mode.

### Curve file format

Plain JSON; one key per effect (`Leaf_<effectName>` matching the engine's
`treeLeaf` keys):

```json
{
  "Leaf_angleOfAttackWithNoPayload": {
    "enable": true,
    "xAxis": "Direct_angleOfAttack",     // X input (Direct_/Indirect_ prefix)
    "cCondition": "Direct_trueAirSpeed", // optional condition dimension
    "xMin": -10, "xMax": 50,             // X range
    "vMin": 0,   "vMax": 100,            // output (motor strength) range
    "cMin": 5,   "cMax": 70,             // condition range
    "points": {
      "x":  [0, 10, 20, ...],            // X samples
      "cv": [ { "c": "5",  "v": [0, 0, ...] },
              { "c": "70", "v": [0, 12, ...] } ]  // one curve per condition value
    }
  }
}
```

## 4. Why the aircraft doesn't appear in the UI (the actual blocker)

In-game vibration only needs §3's folders. The **aircraft tile row** in the
SimAppPro UI is gated separately by `getDcsAircraft()` in the renderer:

1. It scans **only** `<DCS install>\Mods\aircraft\` — never `CoreMods\aircraft`
   and never the user's `Saved Games` mods. The F-100D installs its files
   under `CoreMods\aircraft\F-100D` (confirmed from the DCS updater log), so
   the scan cannot see it. This affects every CoreMods-packaged module.
2. Each found folder name is filtered through a **hardcoded JSON map** baked
   into `app.asar` (`{"<modFolderName>": ["<unitName>", ...]}` — two copies,
   one for the key-binding page, one for the vibration page). No `F-100D` key
   exists yet.
3. The tile icon comes from the module's `entry.lua`, parsed **as text** with
   a regex to extract the `Skins { dir = ... }` folder, then
   `<mod>\<skinsDir>\icon.png`.

## 5. What this project does about it

- **Curves**: copies the F-5E-3 default profile to `F-100D` folders (donor
  chosen for era/performance similarity; users tune from there).
- **Map**: patches both map copies inside `app.asar` with a
  **byte-length-identical** string replacement, so the asar's internal file
  offset table stays valid and no repacking is needed. (Two redundant entries
  are dropped from the `"Flaming Cliffs"` list to pay for the added
  `"F-100D":["F-100D"]` — exactly 97 characters both ways. Original archived
  as `app.asar.bak`.)
- **Scan**: places a comment-only `entry.lua` stub in `Mods\aircraft\F-100D`.
  The `Skins` declaration sits inside a `--[[ ]]` block: SimAppPro's regex
  still matches it (text scan), while DCS executes nothing. The tile icon is
  copied from the user's own `CoreMods\aircraft\F-100D\Theme\icon.png`.

## 6. Path to official support

**WinWing side (all three are data changes, no engine work):**

1. Add `"F-100D": ["F-100D"]` to both aircraft maps in `app.asar`.
2. Ship `Events\DynamicVibrationMotor\DCS\F-100D\<device files>` (start from
   any existing profile; §3 format).
3. Ideally: extend `getDcsAircraft()` to also scan `CoreMods\aircraft` — this
   fixes the whole class of CoreMods-packaged modules at once.

**Module side (Grinnelli): nothing required.** The module already exposes
everything the engine consumes (standard export API). The only useful
handoff to WinWing is: internal name `F-100D`, files under
`CoreMods\aircraft\F-100D`, skins dir `Theme`, icon at `Theme\icon.png`.

## 7. Debugging tips

- `Saved Games\DCS\Logs\dcs.log` — the export script logs under the `WWT`
  tag (`Export start!`, the detected aircraft name, `Export stop!`). If the
  aircraft name line says something other than `F-100D`, the folder names in
  §3 must match *that* string.
- `%APPDATA%\SimAppPro\log.log` — SimAppPro main-process log; shows
  `mod:<name>` on aircraft detection and socket state.
- The effect engine JS (§2) is read from `%APPDATA%` and is user-editable —
  new data sources and effects can be prototyped there without touching the
  app.
