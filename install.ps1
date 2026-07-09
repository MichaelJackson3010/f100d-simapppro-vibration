# F-100D Super Sabre vibration support installer for WinWing SimAppPro
# https://github.com/MichaelJackson3010/f100d-simapppro-vibration
#
# What it does (see README.md for details):
#   1. Patches SimAppPro's aircraft list (app.asar) so the F-100D tile appears.
#      A backup is kept as app.asar.bak next to the original.
#   2. Creates F-100D vibration profile folders (copied from the F-5E-3 donor
#      profile already shipped with YOUR SimAppPro installation).
#   3. Creates a harmless detection stub in Mods\aircraft so SimAppPro's module
#      scan finds the F-100D (the module itself installs under CoreMods, where
#      SimAppPro does not look). DCS executes nothing from the stub.
#
# Run:  Right-click -> "Run with PowerShell", or from a terminal:
#       powershell -ExecutionPolicy Bypass -File .\install.ps1

$ErrorActionPreference = 'Stop'

# ---- tell the user what is about to happen, and ask first --------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "F-100D Super Sabre - WinWing SimAppPro vibration setup" -ForegroundColor Cyan
    Write-Host "======================================================="
    Write-Host "This script will:"
    Write-Host "  1. Close SimAppPro."
    Write-Host "  2. Add 'F-100D' to SimAppPro's aircraft list (one file in Program"
    Write-Host "     Files - a backup named app.asar.bak is created first)."
    Write-Host "  3. Create F-100D vibration curves by copying the F-5E-3 profile"
    Write-Host "     already in your SimAppPro installation."
    Write-Host "  4. Add a tiny comments-only text stub in DCS's Mods\aircraft folder"
    Write-Host "     so SimAppPro's aircraft scan can see the F-100D. DCS ignores it."
    Write-Host "  5. Restart SimAppPro."
    Write-Host ""
    Write-Host "It downloads nothing, sends nothing, and everything is reversible"
    Write-Host "(see README.md). Feel free to read this script before continuing."
    Write-Host ""
    Read-Host "Press Enter to continue (or close this window to cancel)"
    # app.asar lives in Program Files, so re-launch ourselves elevated
    Write-Host "Requesting administrator rights (needed for step 2)..."
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`""
    exit
}

$sap = 'C:\Program Files (x86)\SimAppPro'
if (-not (Test-Path "$sap\SimAppPro.exe")) {
    $sap = Read-Host "SimAppPro not found in the default location. Enter its install folder"
    if (-not (Test-Path "$sap\SimAppPro.exe")) { throw "SimAppPro.exe not found in '$sap'" }
}
$asar     = "$sap\resources\app.asar"
$events   = "$sap\resources\app.asar.unpacked\Events\DynamicVibrationMotor\DCS"
$shake    = "$env:APPDATA\SimAppPro\ShakeEffect"
$donor    = 'F-5E-3'   # era-appropriate donor for the default curves

Write-Host "Closing SimAppPro..."
Stop-Process -Name SimAppPro, SimLogic, WWTMap -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 4
Stop-Process -Name SimAppPro, SimLogic, WWTMap -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# ---- 1. patch the aircraft list inside app.asar -----------------------------
# The replacement is byte-length identical, so the asar file index stays valid.
$oldStr = '"Flaming Cliffs":["F-15C","A-10A","MiG-29A","MiG-29G","MiG-29S","Su-25","Su-27","Su-33","J-11A"]'
$newStr = '"Flaming Cliffs":["F-15C","A-10A","MiG-29A","Su-25","Su-27","Su-33","J-11A"],"F-100D":["F-100D"]'
if ($oldStr.Length -ne $newStr.Length) { throw "internal error: patch strings differ in length" }

$enc   = [Text.Encoding]::GetEncoding(28591)  # Latin-1: 1 char == 1 byte
$bytes = [IO.File]::ReadAllBytes($asar)
$text  = $enc.GetString($bytes)

if ($text.Contains('"F-100D":["F-100D"]')) {
    Write-Host "app.asar already lists the F-100D - skipping patch."
} elseif (-not $text.Contains($oldStr)) {
    Write-Warning "Aircraft map not found in app.asar (SimAppPro update changed it?). Skipping patch - the F-100D tile may not appear, but in-game vibration will still work."
} else {
    if (-not (Test-Path "$asar.bak")) {
        Write-Host "Backing up app.asar -> app.asar.bak (this can take a moment)..."
        Copy-Item $asar "$asar.bak"
    }
    $newBytes = $enc.GetBytes($newStr)
    $count = 0
    $idx = $text.IndexOf($oldStr, [StringComparison]::Ordinal)
    while ($idx -ge 0) {
        [Array]::Copy($newBytes, 0, $bytes, $idx, $newBytes.Length)
        $count++
        $idx = $text.IndexOf($oldStr, $idx + 1, [StringComparison]::Ordinal)
    }
    [IO.File]::WriteAllBytes($asar, $bytes)
    Write-Host "Patched app.asar ($count occurrence(s)). Backup: app.asar.bak"
}
$bytes = $null; $text = $null

# ---- 2. default vibration curves (copied from your own installation) --------
if (-not (Test-Path "$events\F-100D")) {
    Copy-Item "$events\$donor" "$events\F-100D" -Recurse
    Write-Host "Created default profile: Events\...\DCS\F-100D (from $donor)"
}
if ((Test-Path "$shake\default\DCS") -and -not (Test-Path "$shake\default\DCS\F-100D")) {
    Copy-Item "$shake\default\DCS\$donor" "$shake\default\DCS\F-100D" -Recurse -ErrorAction SilentlyContinue
}

# ---- 3. detection stub -------------------------------------------------------
# SimAppPro's module scan only reads <DCS>\Mods\aircraft, but the F-100D module
# installs under <DCS>\CoreMods\aircraft, so a tiny stub is needed for the
# aircraft tile to appear. DCS executes nothing from it (comments only).
$cfgPath = "$env:APPDATA\SimAppPro\config.json"
if (Test-Path $cfgPath) {
    $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
    foreach ($key in @('ED_DCS', 'ED_DCSOpenbeta', 'steamDCS')) {
        $entry = $cfg.DCS_ALL_Path.$key
        if ($null -eq $entry -or [string]::IsNullOrEmpty($entry.EXEPath)) { continue }
        $modDir = Join-Path $entry.EXEPath 'Mods\aircraft\F-100D'
        if (Test-Path "$modDir\entry.lua") { continue }  # already present - nothing to do
        New-Item -ItemType Directory -Force "$modDir\Theme" | Out-Null
        Copy-Item (Join-Path $PSScriptRoot 'stub\entry.lua') "$modDir\entry.lua"
        # icon for the aircraft tile, taken from your own copy of the module
        $iconCandidates = @((Join-Path $entry.EXEPath 'CoreMods\aircraft\F-100D\Theme\icon.png'))
        if (-not [string]::IsNullOrEmpty($entry.SavePath)) {
            $iconCandidates += (Join-Path $entry.SavePath 'Mods\aircraft\F-100D\Theme\icon.png')
        }
        foreach ($icon in $iconCandidates) {
            if (Test-Path $icon) { Copy-Item $icon "$modDir\Theme\icon.png"; break }
        }
        Write-Host "Created detection stub: $modDir"
    }
}

Write-Host "Starting SimAppPro..."
Start-Process "$sap\SimAppPro.exe"
Write-Host ""
Write-Host "Done! Select DCS on the vibration page - the F-100D tile should now be there." -ForegroundColor Green
Write-Host "To undo the app.asar patch: restore resources\app.asar.bak over app.asar."
