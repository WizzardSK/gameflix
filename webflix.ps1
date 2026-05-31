#requires -version 5.1
# gameflix Windows installer — counterpart of webflix.sh.
# Registers the play:// URL scheme handler for the current user (no admin needed),
# writes rclone.conf, and installs a 3-line bootstrap that always fetches the
# latest launcher from https://wizzardsk.github.io/retroarch.ps1
$ErrorActionPreference = 'Stop'

Write-Host '=== Installing play:// handler ==='

$gameflix = Join-Path $env:USERPROFILE 'gameflix'
$romsDir  = Join-Path $env:USERPROFILE 'share\roms'
$rcloneCf = Join-Path $env:APPDATA 'rclone\rclone.conf'
New-Item -ItemType Directory -Force -Path $gameflix, $romsDir, (Split-Path -Parent $rcloneCf) | Out-Null

# rclone.conf (Internet Archive S3 session for restricted items)
Invoke-WebRequest -UseBasicParsing `
  -Uri 'https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf' `
  -OutFile $rcloneCf

# Bootstrap: download the current launcher and run it with the play:// argument.
$boot = Join-Path $gameflix 'gameflix-boot.ps1'
@'
$ErrorActionPreference = "Stop"
$dst = Join-Path $env:TEMP "gameflix-retroarch.ps1"
Invoke-WebRequest -UseBasicParsing -Uri "https://wizzardsk.github.io/retroarch.ps1" -OutFile $dst
& $dst @args
'@ | Set-Content -LiteralPath $boot -Encoding UTF8

# Register the play:// scheme under HKCU (per-user, no elevation).
$root = 'HKCU:\Software\Classes\play'
New-Item -Path $root -Force | Out-Null
Set-ItemProperty -Path $root -Name '(default)'    -Value 'URL:play Protocol'
Set-ItemProperty -Path $root -Name 'URL Protocol' -Value ''
$cmdKey = Join-Path $root 'shell\open\command'
New-Item -Path $cmdKey -Force | Out-Null
$command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$boot`" `"%1`""
Set-ItemProperty -Path $cmdKey -Name '(default)' -Value $command

Write-Host 'Done. Open https://wizzardsk.github.io/ in your browser; ROMs download per-game on launch.'
Write-Host 'Make sure retroarch.exe (and mame.exe for arcade/computer systems) are on your PATH.'
