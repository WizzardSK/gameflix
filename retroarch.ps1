#requires -version 5.1
# gameflix Windows launcher — counterpart of retroarch.sh / retroarch.end
# Invoked as:  retroarch.ps1 "play:///<platform>/<folder>/<rom>"
# Resolves the play:// URL to a local ROM under %USERPROFILE%\share\roms, downloads
# it on demand from Internet Archive, optionally mounts/extracts CD images, and
# launches it via the matching RetroArch core, MAME, or a standalone emulator.
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$PlayArgs)

$ErrorActionPreference = 'Stop'

# ---- Configuration (override via environment variables) ---------------------
$RomsDir   = if ($env:GAMEFLIX_ROMS)  { $env:GAMEFLIX_ROMS }  else { Join-Path $env:USERPROFILE 'share\roms' }
$BiosDir   = if ($env:GAMEFLIX_BIOS)  { $env:GAMEFLIX_BIOS }  else { Join-Path $env:USERPROFILE 'share\bios' }
$MountDir  = if ($env:GAMEFLIX_MOUNT) { $env:GAMEFLIX_MOUNT } else { Join-Path $env:TEMP 'gameflix-iso' }
$TsvUrl    = if ($env:GAMEFLIX_TSV)   { $env:GAMEFLIX_TSV }   else { 'https://wizzardsk.github.io/launch.tsv' }
$CacheDir  = Join-Path $env:LOCALAPPDATA 'gameflix'
$MameHash  = if ($env:GAMEFLIX_MAMEHASH) { $env:GAMEFLIX_MAMEHASH } else { '' }  # optional MAME hash dir
# $RetroArch / $Mame / $CoresDir are resolved below (PATH + common install paths).

# ---- Logging + error surfacing (the bootstrap runs us in a hidden window) ----
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
$LogFile = Join-Path $CacheDir 'launch.log'
try { Start-Transcript -Path $LogFile -Append | Out-Null } catch {}
function Show-Error([string]$msg) {
  Write-Host $msg
  try { (New-Object -ComObject WScript.Shell).Popup($msg, 0, 'gameflix', 0x10) | Out-Null } catch {}
}
trap {
  Show-Error ("gameflix could not launch the game:`n`n{0}`n`nFull log: {1}" -f $_, $LogFile)
  try { Stop-Transcript | Out-Null } catch {}
  exit 1
}

# ---- Helpers ----------------------------------------------------------------

# PATH as the registry has it. We are started by the play:// handler, i.e. by
# explorer.exe, whose environment is a snapshot taken at logon: a directory the
# user adds to PATH afterwards stays invisible to us (though a fresh cmd sees
# it) until the next logon. Reading the registry closes that gap.
function Get-RegistryPath {
  $dirs = @()
  foreach ($k in @('HKCU:\Environment',
                   'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment')) {
    try { $v = (Get-ItemProperty -LiteralPath $k -Name Path -ErrorAction Stop).Path } catch { continue }
    if ($v) { $dirs += ([Environment]::ExpandEnvironmentVariables($v) -split ';') }
  }
  return @($dirs | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_ })
}

# Expand relative install paths against every attached drive, so an emulator on
# D:\ (or a portable one on a USB stick) is found just like one on C:\.
function Get-DriveCandidates([string[]]$relative) {
  $out = @()
  foreach ($d in [IO.DriveInfo]::GetDrives()) {
    if (-not $d.IsReady) { continue }
    if ($d.DriveType -ne [IO.DriveType]::Fixed -and $d.DriveType -ne [IO.DriveType]::Removable) { continue }
    foreach ($r in $relative) { $out += (Join-Path $d.RootDirectory.FullName $r) }
  }
  return $out
}

# Find an executable: honour an explicit override, then PATH, then candidate paths.
function Find-Exe([string]$override, [string]$onPath, [string[]]$candidates) {
  if ($override) { return $override }
  $c = Get-Command $onPath -ErrorAction SilentlyContinue
  if ($c) { return $c.Source }
  foreach ($d in (Get-RegistryPath)) {
    try { $p = Join-Path $d $onPath } catch { continue }   # skip malformed PATH entries
    try { if (Test-Path -LiteralPath $p) { return $p } } catch { continue }
  }
  foreach ($p in $candidates) { if ($p -and (Test-Path $p)) { return $p } }
  return $null
}

# Split a bash-style command string into argv, honouring single quotes (used for
# MAME -autoboot_command 'LOAD\n' etc.). Single quotes are stripped like in bash.
function Split-Command([string]$cmd) {
  $out = @(); $cur = ''; $inq = $false; $has = $false
  for ($i = 0; $i -lt $cmd.Length; $i++) {
    $c = $cmd[$i]
    if ($c -eq "'") { $inq = -not $inq; $has = $true; continue }
    if (-not $inq -and $c -eq ' ') { if ($has) { $out += $cur; $cur = ''; $has = $false }; continue }
    $cur += $c; $has = $true
  }
  if ($has) { $out += $cur }
  return ,$out
}

# URL-encode like the bash urlenc(): keep / a-z A-Z 0-9 . _ ~ -
function Url-Enc([string]$s) {
  $sb = [System.Text.StringBuilder]::new()
  foreach ($b in [System.Text.Encoding]::UTF8.GetBytes($s)) {
    $c = [char]$b
    if ($c -match '[/a-zA-Z0-9._~-]') { [void]$sb.Append($c) }
    else { [void]$sb.AppendFormat('%{0:X2}', $b) }
  }
  $sb.ToString()
}

# Read Internet Archive S3 credentials from rclone.conf, if present.
function Get-IaAuth {
  $candidates = @(
    (Join-Path $env:APPDATA 'rclone\rclone.conf'),
    (Join-Path $env:USERPROFILE '.config\rclone\rclone.conf')
  )
  foreach ($conf in $candidates) {
    if (-not (Test-Path $conf)) { continue }
    $in = $false; $key = ''; $sec = ''
    foreach ($line in Get-Content $conf) {
      if ($line -match '^\[archive\]') { $in = $true; continue }
      if ($line -match '^\[')          { $in = $false; continue }
      if ($in -and $line -match '^\s*access_key_id\s*=\s*(.+?)\s*$')     { $key = $Matches[1] }
      if ($in -and $line -match '^\s*secret_access_key\s*=\s*(.+?)\s*$') { $sec = $Matches[1] }
    }
    if ($key -and $sec) { return "LOW ${key}:${sec}" }
  }
  return ''
}

# Fetch the platform->core/ext/src table, with a local cache fallback for offline use.
function Get-LaunchTable {
  New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
  $cache = Join-Path $CacheDir 'launch.tsv'
  try {
    Invoke-WebRequest -UseBasicParsing -Uri $TsvUrl -OutFile $cache -TimeoutSec 20
  } catch {
    if (-not (Test-Path $cache)) { throw "Cannot fetch $TsvUrl and no cached copy: $_" }
  }
  $rows = @()
  foreach ($line in Get-Content -LiteralPath $cache) {
    if (-not $line) { continue }
    $f = $line -split "`t", 4
    if ($f.Count -lt 1 -or -not $f[0]) { continue }
    $rows += [pscustomobject]@{
      Key  = $f[0]
      Core = if ($f.Count -gt 1) { $f[1] } else { '' }
      Ext  = if ($f.Count -gt 2) { $f[2] } else { '' }
      Src  = if ($f.Count -gt 3) { $f[3] } else { '' }
    }
  }
  return $rows
}

# ---- 1. Resolve the play:// argument to a local path ------------------------
$arg = if ($PlayArgs) { $PlayArgs[0] } else { '' }
if (-not $arg) { Write-Error 'No play:// URL supplied.'; exit 1 }
if ($arg -match '^play://') { $arg = $arg -replace '^play://', '' }
$arg = [uri]::UnescapeDataString($arg)          # %XX -> chars

# arg is now like /platform/folder/rom (forward slashes). Build matching key and local path.
$relUrl   = $arg.TrimStart('/')                 # platform/folder/rom
$matchKey = '/' + $relUrl                        # /platform/folder/rom  (substring-matched against keys)
$local    = Join-Path $RomsDir ($relUrl -replace '/', '\')

# ---- 2. Look up core/ext/src ------------------------------------------------
$table = Get-LaunchTable
$entry = $null
foreach ($row in $table) { if ($matchKey.Contains($row.Key)) { $entry = $row; break } }
if (-not $entry) { Write-Error "No launch mapping found for $matchKey"; exit 1 }
$core = $entry.Core
$ext  = $entry.Ext
$src  = $entry.Src

# ---- 3. Download the ROM on demand ------------------------------------------
if ($src -and -not (Test-Path -LiteralPath $local)) {
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $local) | Out-Null
  # inner = relUrl minus the first two segments (platform/folder)
  $parts = $relUrl.Split('/')
  $inner = if ($parts.Count -gt 2) { ($parts[2..($parts.Count-1)] -join '/') } else { $parts[-1] }
  $url   = $src + (Url-Enc $inner)
  Write-Host "Fetching $(Split-Path -Leaf $local) ..."
  $auth = Get-IaAuth
  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  $ok = $false
  $leaf = Split-Path -Leaf $local
  if ($leaf -notmatch '\.' -and $src -match 'mame-software-list-chds') {
    # A CHD software-list entry is a folder holding the disc or disk images
    # (cd32/abreed3d/alien breed 3d (europe).chd); MAME finds them in
    # <rompath>\<entry>\, so the folder is mirrored.
    New-Item -ItemType Directory -Force -Path $local | Out-Null
    $headers = @{}; if ($auth) { $headers['Authorization'] = $auth }
    try { $listing = (Invoke-WebRequest -UseBasicParsing -Uri "$url/" -Headers $headers -TimeoutSec 60).Content } catch { $listing = '' }
    foreach ($href in ([regex]::Matches($listing, 'href="([^"/?]*\.chd)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)) {
      $chd = Join-Path $local ([uri]::UnescapeDataString($href))
      Write-Host "Fetching $leaf\$(Split-Path -Leaf $chd) ..."
      if ($curl) {
        $cargs = @('-sfL', '--location-trusted', '-o', $chd, "$url/$href")
        if ($auth) { $cargs = @('-H', "Authorization: $auth") + $cargs }
        & $curl.Source @cargs
        if ($LASTEXITCODE -eq 0) { $ok = $true } else { Remove-Item -LiteralPath $chd -Force -ErrorAction SilentlyContinue }
      } else {
        try { Invoke-WebRequest -UseBasicParsing -Uri "$url/$href" -Headers $headers -OutFile $chd; $ok = $true } catch { }
      }
    }
    if (-not $ok) { Remove-Item -LiteralPath $local -Recurse -Force -ErrorAction SilentlyContinue; Write-Error "Download failed: $url/"; exit 1 }
  } elseif ($curl) {
    $cargs = @('-sfL', '--location-trusted', '-o', $local, $url)
    if ($auth) { $cargs = @('-H', "Authorization: $auth") + $cargs }
    & $curl.Source @cargs
    $ok = ($LASTEXITCODE -eq 0)
  } else {
    try {
      $headers = @{}; if ($auth) { $headers['Authorization'] = $auth }
      Invoke-WebRequest -UseBasicParsing -Uri $url -Headers $headers -OutFile $local
      $ok = $true
    } catch { $ok = $false }
  }
  if (-not $ok) {
    if (Test-Path -LiteralPath $local) { Remove-Item -LiteralPath $local -Force }
    Write-Error "Download failed: $url"; exit 1
  }
}

# ---- 4. Mount / extract CD images -------------------------------------------
# A .cue/.gdi image references separate track files, so the emulator needs the
# whole archive visible. Preferred backends on Windows, in order:
#   1. Pismo File Mount (pfm.exe) - native, lightweight, mounts zip+iso in place
#   2. 7-Zip (7z.exe)             - extracts the whole archive to %TEMP% (uses disk)
#   3. ratarmount                 - optional; mainly a Linux tool, needs WinFsp here
$rom = $local
$script:MountBackend = ''   # 'pfm' | 'ratarmount' | ''
$script:MountTarget  = ''

function Get-Tool($names) {
  foreach ($n in $names) { $c = Get-Command $n -ErrorAction SilentlyContinue; if ($c) { return $c } }
  return $null
}

# Mount $local's contents as a browsable folder; return the root dir, or $null.
function Mount-Archive {
  $pfm = Get-Tool @('pfm.exe', 'pfm')
  if ($pfm) {
    & $pfm.Source mount $local | Out-Null
    $script:MountBackend = 'pfm'; $script:MountTarget = $local
    return $local                       # Pismo overlays the file path as a folder
  }
  $ratar = Get-Command ratarmount -ErrorAction SilentlyContinue
  if ($ratar) {
    & ratarmount -u $MountDir 2>$null
    New-Item -ItemType Directory -Force -Path $MountDir | Out-Null
    & ratarmount $local $MountDir
    $script:MountBackend = 'ratarmount'; $script:MountTarget = $MountDir
    return $MountDir
  }
  return $null
}

function Dismount-Archive {
  switch ($script:MountBackend) {
    'pfm'        { $t = Get-Tool @('pfm.exe', 'pfm'); if ($t) { & $t.Source unmount $script:MountTarget 2>$null } }
    'ratarmount' { & ratarmount -u $script:MountTarget 2>$null }
  }
  $script:MountBackend = ''
}

# 7-Zip fallback: extract the whole archive to a cached folder; return it or $null.
function Expand-Archive7z {
  $sevenzip = Get-Tool @('7z.exe', '7za.exe')
  if (-not $sevenzip) { return $null }
  $dir  = Join-Path $MountDir ([IO.Path]::GetFileNameWithoutExtension($local))
  $done = Join-Path $dir '.gameflix-done'
  if (-not (Test-Path $done)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    & $sevenzip.Source x -y "-o$dir" $local | Out-Null
    New-Item -ItemType File -Force -Path $done | Out-Null
  }
  return $dir
}

# The disc image to start out of an opened archive: the list's own type first,
# then the usual ones in order of preference, then the largest file. No-Intro
# and NonRedump lists mix them (a Mega CD beta is a bare .bin, a PSX one an
# .iso), so a list's single type does not always match.
function Find-Image([string]$root, [string]$want) {
  $files = @(Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue)
  foreach ($e in @($want, 'cue', 'gdi', 'm3u', 'ccd', 'chd', 'cdi', 'iso', 'bin', 'img')) {
    if (-not $e) { continue }
    $f = $files | Where-Object { $_.Extension -eq ".$e" } | Sort-Object FullName | Select-Object -First 1
    if ($f) { return $f.FullName }
  }
  $f = $files | Sort-Object Length -Descending | Select-Object -First 1
  if ($f) { return $f.FullName }
  return $null
}

if ($ext -and $local -notmatch '\.(zip|rar|7z)$') {
  $rom = $local   # not an archive after all (3DS .cci); the core takes it as it is
} elseif ($ext) {
  $root = Mount-Archive
  if (-not $root) { $root = Expand-Archive7z }
  if (-not $root) { Write-Error 'Need Pismo File Mount (pfm), 7-Zip (7z.exe), or ratarmount to open CD images.'; exit 1 }
  $found = Find-Image $root $ext
  if ($found) { $rom = $found }
} elseif ($local -match '\.(rar|7z)$') {
  $root = Mount-Archive
  if (-not $root) { $root = Expand-Archive7z }
  if (-not $root) { Write-Error 'Need Pismo File Mount (pfm), 7-Zip (7z.exe), or ratarmount to open .rar and .7z archives.'; exit 1 }
  # A title of many files (Wii U NUS) is started from its folder; a single
  # image (a No-Intro DS .7z) is handed over itself.
  $rom = $root
  $files = @(Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue)
  if ($files.Count -eq 1) { $rom = $files[0].FullName }
}

# ---- Resolve emulator executables (PATH + common Windows install locations) -
function J($a, $b) { if ($a) { Join-Path $a $b } else { $null } }
$pf = ${env:ProgramFiles}; $pfx8 = ${env:ProgramFiles(x86)}
$RetroArch = Find-Exe $env:GAMEFLIX_RETROARCH 'retroarch.exe' (@(
  (J $env:LOCALAPPDATA 'Programs\RetroArch\retroarch.exe'),
  (J $pf   'RetroArch\retroarch.exe'),
  (J $pfx8 'RetroArch\retroarch.exe'),
  (J $pfx8 'Steam\steamapps\common\RetroArch\retroarch.exe')
) + (Get-DriveCandidates @(
  'RetroArch-Win64\retroarch.exe',
  'RetroArch\retroarch.exe',
  'Games\RetroArch\retroarch.exe',
  'Emulators\RetroArch\retroarch.exe',
  'SteamLibrary\steamapps\common\RetroArch\retroarch.exe'
)))
$Mame = Find-Exe $env:GAMEFLIX_MAME 'mame.exe' (@((J $pf 'mame\mame.exe')) +
  (Get-DriveCandidates @('mame\mame.exe', 'Games\mame\mame.exe', 'Emulators\mame\mame.exe')))
$CoresDir = if ($env:GAMEFLIX_CORES) { $env:GAMEFLIX_CORES }
            elseif ($RetroArch)      { Join-Path (Split-Path -Parent $RetroArch) 'cores' }
            else                     { Join-Path $env:APPDATA 'RetroArch\cores' }

# Resolve the core .dll for a libretro core: fetch it from the libretro
# buildbot if missing, and as a last resort fall back to an installed core
# with the same name stem (e.g. stella -> stella2014), mirroring retroarch.end.
function Resolve-LibretroCore([string]$name) {
  if (-not $RetroArch) { throw "retroarch.exe not found. Install RetroArch, add it to PATH, or set the GAMEFLIX_RETROARCH environment variable." }
  $dll = Join-Path $CoresDir "$name.dll"
  if (Test-Path $dll) { return $dll }
  # The buildbot only ships x86 and x86_64 Windows cores; on ARM64 RetroArch
  # itself runs x86_64 under emulation, so the x86_64 core is the right one.
  $barch = if ($env:PROCESSOR_ARCHITECTURE -eq 'x86') { 'x86' } else { 'x86_64' }
  Write-Host "Fetching core $name ($barch) from the libretro buildbot ..."
  $zip = Join-Path $env:TEMP "$name.dll.zip"
  try {
    New-Item -ItemType Directory -Force -Path $CoresDir | Out-Null
    Invoke-WebRequest -UseBasicParsing -Uri "https://buildbot.libretro.com/nightly/windows/$barch/latest/$name.dll.zip" -OutFile $zip -TimeoutSec 600
    Expand-Archive -LiteralPath $zip -DestinationPath $CoresDir -Force
  } catch {
    Write-Host "Buildbot download failed: $_"
  } finally {
    Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
  }
  if (Test-Path $dll) { return $dll }
  $stem = $name -replace '_libretro$', ''
  $alt = Get-ChildItem -Path $CoresDir -Filter "$stem*_libretro.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($alt) { Write-Host "Core $name unavailable; using $($alt.BaseName) instead"; return $alt.FullName }
  throw "Core '$name' is not installed and the buildbot download failed; in RetroArch open Online Updater > Core Downloader and install '$name', or set GAMEFLIX_CORES to your cores folder."
}

# RetroArch's system directory: where the mame_libretro core keeps its support
# data (mame\hash, mame\bios, mame\roms). Portable installs put it next to
# retroarch.exe, installed ones under %APPDATA%; retroarch.cfg has the truth,
# where a leading ":" means "the RetroArch directory".
function Get-RetroArchSystemDir {
  $raDir = if ($RetroArch) { Split-Path -Parent $RetroArch } else { $null }
  foreach ($cfg in @((J $raDir 'retroarch.cfg'), (J $env:APPDATA 'RetroArch\retroarch.cfg'))) {
    if (-not $cfg -or -not (Test-Path -LiteralPath $cfg)) { continue }
    $m = Select-String -LiteralPath $cfg -Pattern '^\s*system_directory\s*=\s*"?([^"]*?)"?\s*$' | Select-Object -First 1
    if (-not $m) { continue }
    $v = $m.Matches[0].Groups[1].Value
    if (-not $v -or $v -eq 'default') { continue }
    if ($v -match '^:[\\/]?(.*)$' -and $raDir) { $v = Join-Path $raDir $Matches[1] }
    if (Test-Path -LiteralPath $v) { return $v }
  }
  foreach ($d in @((J $raDir 'system'), (J $env:APPDATA 'RetroArch\system'))) {
    if ($d -and (Test-Path -LiteralPath $d)) { return $d }
  }
  return (J $raDir 'system')
}

# Download $url to $out, with the Internet Archive session when rclone has one.
function Get-IaFile([string]$url, [string]$out) {
  $auth = Get-IaAuth
  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if ($curl) {
    $cargs = @('-sfL', '--location-trusted', '-o', $out, $url)
    if ($auth) { $cargs = @('-H', "Authorization: $auth") + $cargs }
    & $curl.Source @cargs
    if ($LASTEXITCODE -eq 0) { return $true }
  } else {
    try {
      $headers = @{}; if ($auth) { $headers['Authorization'] = $auth }
      Invoke-WebRequest -UseBasicParsing -Uri $url -Headers $headers -OutFile $out
      return $true
    } catch { }
  }
  Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
  return $false
}

# mame_deps.tsv (made by gen_mame_deps.py): per MAME driver, the zips of the
# merged set it needs - its own (the parent's, for a clone), the BIOS chain and
# the ROM devices of its default configuration - and its software lists. With
# the driver's own zip alone most machines stop with "Required files are
# missing". Column 2 is the zips, column 3 the lists.
function Get-MameDeps([string]$driver, [int]$col) {
  New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
  $deps = Join-Path $CacheDir 'mame_deps.tsv'
  if (-not (Test-Path -LiteralPath $deps) -or (Get-Item -LiteralPath $deps).LastWriteTime -lt (Get-Date).AddDays(-30)) {
    try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 60 -OutFile $deps -Uri 'https://wizzardsk.github.io/mame_deps.tsv' } catch { }
  }
  if (Test-Path -LiteralPath $deps) {
    foreach ($line in Get-Content -LiteralPath $deps) {
      $f = $line -split "`t"
      if ($f[0] -eq $driver) { if ($f.Count -ge $col) { return @($f[$col - 1] -split ' ' | Where-Object { $_ }) } else { return @() } }
    }
  }
  if ($col -eq 2) { return @($driver) } else { return @() }
}

# Fetch the MAME system ROM sets a driver needs into $BiosDir, from the merged
# set on the Internet Archive; sets RetroArch's system dirs already hold are
# left alone.
function Install-MameBios([string]$driver) {
  if (-not $driver -or $driver -match '^-') { return }
  New-Item -ItemType Directory -Force -Path $BiosDir | Out-Null
  $sysDir = Get-RetroArchSystemDir
  foreach ($set in (Get-MameDeps $driver 2)) {
    $dirs = @($BiosDir)
    if ($sysDir) { $dirs += @((Join-Path $sysDir 'mame\bios'), (Join-Path $sysDir 'mame\roms')) }
    if ($dirs | Where-Object { Test-Path -LiteralPath (Join-Path $_ "$set.zip") }) { continue }
    Write-Host "Fetching MAME system ROMs $set.zip ..."
    if (-not (Get-IaFile "https://archive.org/download/mame-merged/mame-merged/$set.zip" (Join-Path $BiosDir "$set.zip"))) {
      Write-Host "No MAME system ROMs $set.zip in the merged set; continuing"
    }
  }
}

# Software named in the core arguments rather than picked on the page: Family
# BASIC for the Famicom tape games ("famicom famibs30 -cass"), a BASIC
# cartridge ("m5 -cart1 m5_cart:basici", "to7 -cart basic"), a FreeDOS hard
# disk ("ibm5150 -hard1 ibm5150_hdd:freedos13_8086"). It comes from the MAME
# software-list sets - a zip, or for a CHD list the entry's folder - into
# $BiosDir\<list>\<entry>, where MAME finds it through the rompath. A bare
# name has no list, so the driver's lists are tried in turn. Returns the CHD
# folders fetched, as "list/entry".
function Install-MameSoftware([string[]]$words) {
  $chdDirs = @()
  $prev = ''
  for ($i = 1; $i -lt $words.Count; $i++) {
    $w = $words[$i]; $list = ''; $item = ''
    if ($w -match '^([a-z0-9_]+):([a-z0-9_]+)$') { $list = $Matches[1]; $item = $Matches[2] }
    elseif ($w -match '^[a-z0-9_]+$' -and ($i -eq 1 -or $prev -match '^-(cart|cass|flop|hard|cdrm|cdrom|rom|memc|utap|quik)\d*$')) { $item = $w }
    $prev = $w
    if (-not $item) { continue }
    $lists = if ($list) { @($list) } else { @(Get-MameDeps $words[0] 3) }
    $got = $false
    foreach ($l in $lists) {
      $dest = Join-Path $BiosDir $l
      if (Test-Path -LiteralPath (Join-Path $dest "$item.zip")) { $got = $true; break }
      if (Test-Path -LiteralPath (Join-Path $dest $item)) { $got = $true; $chdDirs += "$l/$item"; break }
      New-Item -ItemType Directory -Force -Path $dest | Out-Null
      if (Get-IaFile "https://archive.org/download/mame-sl/mame-sl/$l.zip/$l/$item.zip" (Join-Path $dest "$item.zip")) {
        Write-Host "Fetched MAME software ${l}:$item"; $got = $true; break
      }
      $headers = @{}; $auth = Get-IaAuth; if ($auth) { $headers['Authorization'] = $auth }
      try { $listing = (Invoke-WebRequest -UseBasicParsing -Uri "https://archive.org/download/mame-software-list-chds-2/$l/$item/" -Headers $headers -TimeoutSec 60).Content } catch { continue }
      foreach ($href in ([regex]::Matches($listing, 'href="([^"/?]*\.chd)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)) {
        New-Item -ItemType Directory -Force -Path (Join-Path $dest $item) | Out-Null
        $chd = Join-Path (Join-Path $dest $item) ([uri]::UnescapeDataString($href))
        Write-Host "Fetching MAME software ${l}:$item ($(Split-Path -Leaf $chd)) ..."
        if (Get-IaFile "https://archive.org/download/mame-software-list-chds-2/$l/$item/$href" $chd) { $got = $true }
      }
      if ($got) { $chdDirs += "$l/$item"; break }
    }
    if (-not $got) { Write-Host "MAME software $w not found in the software-list sets; continuing" }
  }
  return ,$chdDirs
}

# The CHD sets on the Internet Archive are older than the core, and some discs
# have been renamed since ("towns hyakunin isshu.chd" is now "hyakunin isshu
# (japan).chd"). MAME looks a disk up by the name in the list XML, so when an
# entry folder holds one CHD under another name, it gets that name too.
function Repair-ChdName([string]$dir, [string]$list, [string]$item, [string]$hashDir) {
  if (-not $hashDir -or -not (Test-Path -LiteralPath $dir)) { return }
  $xml = Join-Path $hashDir "$list.xml"
  if (-not (Test-Path -LiteralPath $xml)) { return }
  $text = Get-Content -LiteralPath $xml -Raw
  $m = [regex]::Match($text, '<software name="' + [regex]::Escape($item) + '"[\s\S]*?</software>')
  if (-not $m.Success) { return }
  $want = @([regex]::Matches($m.Value, '<disk name="([^"]*)"') | ForEach-Object { $_.Groups[1].Value })
  if ($want.Count -ne 1) { return }
  $target = Join-Path $dir "$($want[0]).chd"
  if (Test-Path -LiteralPath $target) { return }
  $have = @(Get-ChildItem -LiteralPath $dir -Filter '*.chd' -File)
  if ($have.Count -ne 1) { return }
  # a hard link costs no space; a copy where the file system has none
  try { New-Item -ItemType HardLink -Path $target -Target $have[0].FullName -ErrorAction Stop | Out-Null }
  catch { Copy-Item -LiteralPath $have[0].FullName -Destination $target }
}

# MAME-SL sources are named after the MAME software list they hold:
# .../mame-sl/mame-sl/neogeo.zip/neogeo/ -> the "neogeo" list.
function Get-SoftlistName([string]$src) {
  if ($src -match '/mame-sl/([^/]+)\.zip/') { return [uri]::UnescapeDataString($Matches[1]) }
  return ''
}

# A software-list launch ("aes -cart mslug") only resolves if MAME can read the
# list XML. mame_libretro looks for it in <system>\mame\hash and ships none, so
# without it the core dies before drawing a frame -- no error, just a black
# screen (gameflix#12). Fetch the single list this game needs.
function Install-MameHash([string]$list) {
  if (-not $list) { return '' }
  $hashDir = $MameHash
  if (-not $hashDir) {
    $sys = Get-RetroArchSystemDir
    if (-not $sys) { return '' }
    $hashDir = Join-Path $sys 'mame\hash'
  }
  $xml = Join-Path $hashDir "$list.xml"
  if (Test-Path -LiteralPath $xml) { return $hashDir }
  try {
    New-Item -ItemType Directory -Force -Path $hashDir | Out-Null
    Write-Host "Fetching MAME software list $list.xml ..."
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 120 -OutFile $xml `
      -Uri "https://raw.githubusercontent.com/libretro/mame/master/hash/$list.xml"
  } catch {
    Write-Host "Could not fetch the $list software list: $_"
    Remove-Item -LiteralPath $xml -Force -ErrorAction SilentlyContinue
  }
  if (Test-Path -LiteralPath $xml) { return $hashDir }
  return ''
}

Write-Host "core=$core ext=$ext rom=$rom"
Write-Host "retroarch=$RetroArch cores=$CoresDir"

# ---- 5. Launch --------------------------------------------------------------
try {
  $coreTokens = Split-Command $core
  $coreName   = if ($coreTokens.Count -gt 0) { $coreTokens[0] } else { '' }

  if ($coreName -eq 'mame_libretro') {
    # MAME via the libretro core: hand it a .cmd file holding the full command line.
    $rompath = ''
    if (-not $ext) {
      $rompath = (Split-Path -Parent $local) + ';' + $BiosDir
      if ($src -match 'tosec|ni-roms|redump|memorex') {
        # A plain image (TOSEC, No-Intro, Redump), not a MAME set: MAME needs
        # its path, and it cannot open an image inside a zip.
        $rom = $local
        if ($local -match '\.zip$') {
          $dir = $local -replace '\.zip$', ''
          Expand-Archive -LiteralPath $local -DestinationPath $dir -Force
          $rom = (Get-ChildItem -LiteralPath $dir -Recurse -File | Sort-Object Length -Descending | Select-Object -First 1).FullName
        }
      } else {
        $rom = [IO.Path]::GetFileNameWithoutExtension($local)   # a set MAME finds by its short name
      }
    } else {
      # The image comes out of the mounted archive; system ROMs stay in $BiosDir.
      $rompath = $BiosDir
    }
    if ($local -match '\\model2\\' -or $local -match '\\model3\\') {
      $rompath = (Split-Path -Parent $local) + ';' + (Join-Path $RomsDir 'mame\MAME') + ';' + $BiosDir
    }
    $mameArgs = ($core -replace '^mame_libretro\s*', '')
    $words = Split-Command $mameArgs
    $driver = if ($words.Count -gt 0) { $words[0] } else { '' }
    Install-MameBios $driver
    $chdDirs = Install-MameSoftware $words
    # Software-list games need the list XML in the core's hash dir. The lists
    # come from libretro/mame, matching the core, for every list of the driver
    # and the one the ROM came from.
    $lists = @(Get-MameDeps $driver 3)
    $list = Get-SoftlistName $src
    if ($list) { $lists += $list }
    foreach ($l in ($lists | Select-Object -Unique)) { $h = Install-MameHash $l; if ($h) { $MameHash = $h } }
    if ((Test-Path -LiteralPath $local -PathType Container) -and $src -match '/mame-software-list-chds[^/]*/([^/]+)/') {
      Repair-ChdName $local $Matches[1] (Split-Path -Leaf $local) $MameHash
    }
    foreach ($d in $chdDirs) { Repair-ChdName (Join-Path $BiosDir $d) ($d -split '/')[0] ($d -split '/')[1] $MameHash }
    $base = [IO.Path]::GetFileNameWithoutExtension($rom)
    # The table quotes arguments for a shell ("-autoboot_command 'LOAD ""\n'"),
    # but the core's cmd parser knows only double quotes and keeps single ones
    # as text, so every autoboot command was typed with an apostrophe on each
    # side. The arguments are written back double-quoted where needed; a "
    # inside becomes \x22, which the Lua string MAME posts the keys from turns
    # back into a quote.
    $line = ''
    foreach ($w in $words) {
      if ($w -match '[\s"]') { $w = '"' + ($w -replace '"', '\x22') + '"' }
      $line += "$w "
    }
    $line += "`"$rom`""
    # -rompath, not -rp: current cores (0.28x) no longer merge a "-rp" path into
    # their own rompath, so the system ROMs were never found. A -rompath
    # replaces the core's own path, so RetroArch's system\mame\bios and
    # system\mame\roms are added back by hand.
    if ($rompath) {
      $sysDir = Get-RetroArchSystemDir
      if ($sysDir) { $rompath += ';' + (Join-Path $sysDir 'mame\bios') + ';' + (Join-Path $sysDir 'mame\roms') }
      $line += " -rompath `"$rompath`""
    }
    if ($MameHash) { $line += " -hashpath `"$MameHash`"" }
    $line += " -skip_gameinfo -snapname `"$base`""
    $dll = Resolve-LibretroCore 'mame_libretro'
    $cmdFile = [IO.Path]::GetTempFileName() + '.cmd'
    Set-Content -LiteralPath $cmdFile -Value $line -Encoding ASCII
    # Launch from RetroArch's own directory so the mame_libretro core finds its
    # support data (hash/, artwork, plugins) -- relative to cwd, they are missing
    # when the launcher's working directory is used, so games fail to open. Quote
    # the DLL and .cmd paths explicitly (spaces in "Program Files"/user names) and
    # -Wait so the temp .cmd is only removed after RetroArch has read it.
    # (Fix reported by @kevinmadson026, gameflix#10.)
    $RetroArchDir = Split-Path -Parent $RetroArch
    Start-Process -FilePath $RetroArch -ArgumentList "-L `"$dll`" `"$cmdFile`"" -WorkingDirectory $RetroArchDir -Wait
    Remove-Item -LiteralPath $cmdFile -Force -ErrorAction SilentlyContinue
  }
  elseif ($coreName -eq 'mame') {
    # Standalone MAME.
    $rompath = ''
    if (-not $ext) {
      $rompath = (Split-Path -Parent $local) + ';' + $BiosDir
      $rom = [IO.Path]::GetFileNameWithoutExtension($local)
    }
    $core = [regex]::Replace($core, '(-hard\d+) ([a-z0-9_]+):([a-z0-9_]+)', {
      param($m) "$($m.Groups[1].Value) " + (Join-Path $BiosDir ("$($m.Groups[2].Value)\$($m.Groups[3].Value)\$($m.Groups[3].Value).chd")) })
    $base = [IO.Path]::GetFileNameWithoutExtension($rom)
    $tok = Split-Command $core
    $exe = if ($tok[0] -eq 'mame') { $Mame } else { $tok[0] }
    if (-not $exe) { throw "mame.exe not found. Add it to PATH or set the GAMEFLIX_MAME environment variable." }
    $rest = if ($tok.Count -gt 1) { $tok[1..($tok.Count-1)] } else { @() }
    $cmd = @($rest) + @($rom, '-skip_gameinfo', '-snapname', $base)
    if ($rompath) { $cmd += @('-rompath', $rompath) }
    & $exe @cmd
  }
  elseif ($core -like '*libretro*') {
    $dll = Resolve-LibretroCore $coreName
    & $RetroArch -L $dll $rom
  }
  elseif ($core) {
    $rest = if ($coreTokens.Count -gt 1) { $coreTokens[1..($coreTokens.Count-1)] } else { @() }
    if (-not (Get-Command $coreName -ErrorAction SilentlyContinue) -and -not (Test-Path $coreName)) {
      throw "Emulator '$coreName' not found on PATH. Install it or add it to PATH."
    }
    & $coreName @rest $rom
  }
  else {
    Write-Error "No emulator core defined for $matchKey"; exit 1
  }
}
finally {
  Dismount-Archive
}
try { Stop-Transcript | Out-Null } catch {}
