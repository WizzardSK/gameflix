#requires -version 5.1
# gameflix Windows launcher — counterpart of retroarch.sh / retroarch.end
# Invoked as:  retroarch.ps1 "play:///<platform>/<folder>/<rom>"
# Resolves the play:// URL to a local ROM under %USERPROFILE%\share\roms, downloads
# it on demand from Internet Archive, optionally mounts/extracts CD images, and
# launches it via the matching RetroArch core, MAME, or a standalone emulator.
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$PlayArgs)

$ErrorActionPreference = 'Stop'

# ---- Configuration (override via environment variables) ---------------------
# Emulator executables are expected on PATH (PATH + conventions).
$RomsDir   = if ($env:GAMEFLIX_ROMS)  { $env:GAMEFLIX_ROMS }  else { Join-Path $env:USERPROFILE 'share\roms' }
$BiosDir   = if ($env:GAMEFLIX_BIOS)  { $env:GAMEFLIX_BIOS }  else { Join-Path $env:USERPROFILE 'share\bios' }
$CoresDir  = if ($env:GAMEFLIX_CORES) { $env:GAMEFLIX_CORES } else { Join-Path $env:APPDATA 'RetroArch\cores' }
$MountDir  = if ($env:GAMEFLIX_MOUNT) { $env:GAMEFLIX_MOUNT } else { Join-Path $env:TEMP 'gameflix-iso' }
$RetroArch = if ($env:GAMEFLIX_RETROARCH) { $env:GAMEFLIX_RETROARCH } else { 'retroarch.exe' }
$Mame      = if ($env:GAMEFLIX_MAME)      { $env:GAMEFLIX_MAME }      else { 'mame.exe' }
$TsvUrl    = if ($env:GAMEFLIX_TSV)       { $env:GAMEFLIX_TSV }       else { 'https://wizzardsk.github.io/launch.tsv' }
$CacheDir  = Join-Path $env:LOCALAPPDATA 'gameflix'
$MameHash  = if ($env:GAMEFLIX_MAMEHASH)  { $env:GAMEFLIX_MAMEHASH }  else { '' }  # optional MAME hash dir

# ---- Helpers ----------------------------------------------------------------

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
  if ($curl) {
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

if ($ext) {
  $root = Mount-Archive
  if (-not $root) { $root = Expand-Archive7z }
  if (-not $root) { Write-Error 'Need Pismo File Mount (pfm), 7-Zip (7z.exe), or ratarmount to open CD images.'; exit 1 }
  $found = Get-ChildItem -Path $root -Recurse -File -Filter "*.$ext" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($found) { $rom = $found.FullName }
} elseif ($local -match '\.rar$') {
  $root = Mount-Archive
  if (-not $root) { $root = Expand-Archive7z }
  if (-not $root) { Write-Error 'Need Pismo File Mount (pfm), 7-Zip (7z.exe), or ratarmount to open .rar archives.'; exit 1 }
  $rom = $root
}

# ---- 5. Launch --------------------------------------------------------------
try {
  $coreTokens = Split-Command $core
  $coreName   = if ($coreTokens.Count -gt 0) { $coreTokens[0] } else { '' }

  if ($coreName -eq 'mame_libretro') {
    # MAME via the libretro core: hand it a .cmd file holding the full command line.
    $rompath = ''
    if (-not $ext) {
      $rompath = (Split-Path -Parent $local) + ';' + $BiosDir
      $rom = [IO.Path]::GetFileNameWithoutExtension($local)
    }
    if ($local -match '\\model2\\' -or $local -match '\\model3\\') {
      $rompath = (Join-Path $RomsDir 'mame\MAME') + ';' + $BiosDir
    }
    # Substitute "-hardN slot:disk" -> CHD path under BIOS dir.
    $core = [regex]::Replace($core, '(-hard\d+) ([a-z0-9_]+):([a-z0-9_]+)', {
      param($m) "$($m.Groups[1].Value) " + (Join-Path $BiosDir ("$($m.Groups[2].Value)\$($m.Groups[3].Value)\$($m.Groups[3].Value).chd")) })
    $mameArgs = ($core -replace '^mame_libretro\s*', '')
    $base = [IO.Path]::GetFileNameWithoutExtension($rom)
    $line = ''
    if ($mameArgs) { $line += "$mameArgs " }
    $line += "$rom"
    if ($rompath) { $line += " -rompath `"$rompath`"" }
    if ($MameHash) { $line += " -hashpath $MameHash" }
    $line += " -skip_gameinfo -snapname `"$base`""
    $cmdFile = [IO.Path]::GetTempFileName() + '.cmd'
    Set-Content -LiteralPath $cmdFile -Value $line -Encoding ASCII
    & $RetroArch -L (Join-Path $CoresDir 'mame_libretro.dll') $cmdFile
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
    $rest = if ($tok.Count -gt 1) { $tok[1..($tok.Count-1)] } else { @() }
    $cmd = @($rest) + @($rom, '-skip_gameinfo', '-snapname', $base)
    if ($rompath) { $cmd += @('-rompath', $rompath) }
    & $exe @cmd
  }
  elseif ($core -like '*libretro*') {
    & $RetroArch -L (Join-Path $CoresDir "$coreName.dll") $rom
  }
  elseif ($core) {
    $rest = if ($coreTokens.Count -gt 1) { $coreTokens[1..($coreTokens.Count-1)] } else { @() }
    & $coreName @rest $rom
  }
  else {
    Write-Error "No emulator core defined for $matchKey"; exit 1
  }
}
finally {
  Dismount-Archive
}
