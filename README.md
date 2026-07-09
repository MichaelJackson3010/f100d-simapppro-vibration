# F-100D Super Sabre — WinWing Vibration Support

Feel the Hun. This adds the **F-100D Super Sabre** to WinWing SimAppPro's
vibration system, so your WinWing stick and throttle shake with:

- 🌀 **AoA buffet** — feel the wing talking to you before it bites (and in
  *this* jet, you want that warning)
- 💥 **Weapon release and cannon fire**
- 🛬 **Gear travel and touchdown thump**
- 💨 **Speedbrakes, control surfaces and G-loading**

WinWing hasn't released an official F-100D profile yet, so the Super Sabre
doesn't appear in SimAppPro. This project fixes that with a small, fully
reversible setup — the same vibration engine WinWing uses for every other
aircraft, just unlocked for the F-100D.

> Fan project — not affiliated with WinWing or Grinnelli Designs, and no
> WinWing or Grinnelli files are included. Everything is set up from files
> already in **your own** installation.

## Install

1. Click the green **Code** button (top of this page) → **Download ZIP**, and
   extract it anywhere.
2. Right-click **`install.ps1`** → **Run with PowerShell**.
   - The script first shows you a summary of what it will change and waits
     for you to press Enter.
   - Windows will then show an administrator (UAC) prompt — that's needed to
     edit one SimAppPro file inside Program Files. A backup of that file is
     made automatically first.
3. SimAppPro restarts by itself. Select **DCS** on the vibration page — the
   **F-100D** tile is now in the aircraft row. Fly!

Every device starts with sensible default curves (borrowed from the F-5E-3 —
another supersonic gun fighter of the same era). Want more buffet, earlier?
Switch your device to **Advanced** in SimAppPro and drag the curves around in
the built-in editor.

## Is this safe?

Healthy question — random scripts from the internet *should* make you pause.
Here's exactly what's going on, and how to check it yourself:

- **The script is ~130 lines and open for you to read.** Right-click
  `install.ps1` → **Edit** opens it in Notepad. Every step is commented in
  plain English.
- **It downloads nothing and sends nothing.** No internet access, no
  telemetry, no accounts. It only copies files that are already on your PC.
- **It doesn't touch your DCS installation's game files.** The only thing it
  adds on the DCS side is a tiny text file (`entry.lua` stub, comments only)
  that DCS itself completely ignores — it exists purely so SimAppPro's
  aircraft scanner can "see" the F-100D. Verified safe: DCS executes nothing
  from it.
- **The one real change** is adding "F-100D" to the aircraft list inside a
  SimAppPro file (`app.asar`). The original is saved as `app.asar.bak` right
  next to it before anything is modified.
- **Why the admin prompt?** That one file lives in `C:\Program Files (x86)`,
  which Windows protects. That's the only reason.
- **Why does Windows warn me about the script?** Windows shows a warning for
  *any* PowerShell script that isn't digitally signed by a company. Hobby
  projects like this one aren't signed — the warning is about the signature,
  not the contents.

## Undo / uninstall

Everything is reversible in two minutes:

1. Close SimAppPro. In `C:\Program Files (x86)\SimAppPro\resources\`, delete
   `app.asar` and rename `app.asar.bak` back to `app.asar`.
2. Delete the `F-100D` folders in:
   - `C:\Program Files (x86)\SimAppPro\resources\app.asar.unpacked\Events\DynamicVibrationMotor\DCS\`
   - `%APPDATA%\SimAppPro\ShakeEffect\default\DCS\` and `...\active\DCS\`
3. Delete the folder `<your DCS install>\Mods\aircraft\F-100D` (the stub).

## Good to know

- **SimAppPro updates undo this** (updates replace the files we change). Fix:
  run `install.ps1` again — takes 30 seconds. Any curves you tuned yourself
  are kept safe in `%APPDATA%` and survive both updates and re-installs.
- A DCS **repair** may list the little stub file as "extra" — that's ours,
  it's harmless, and re-running the installer brings it back if repair
  removes it.
- If WinWing ships official F-100D support one day, the installer notices and
  steps aside automatically.

## Credits

- Research and testing: MichaelJackson3010
- Reverse engineering done with Claude (Anthropic)
- Thanks to Grinnelli Designs for the Super Sabre and WinWing for hardware
  that shakes

*Curious how it all works under the hood? See [TECHNICAL.md](TECHNICAL.md)
for the full write-up.*
