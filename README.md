# Gameflix

![obrázok](https://github.com/user-attachments/assets/c90a7c26-1828-481c-a236-f56d0b19f936)

**Demo: https://wizzardsk.github.io/**

Stream retro games directly from public online sources on Linux machines — no massive local storage needed. Like Netflix, but for retro games.

The library covers **145+ systems** with **760+ ROM collections** from sources like Myrient, Internet Archive, TOSEC, and others. Thumbnails are fetched from GitHub repositories.

I made this project for my own personal needs, to have the same setup on all my machines.

### Why streaming over local storage?

You get access to your entire game library without needing huge storage. PSX, PS2, GameCube, or Dreamcast games can be very large — with Gameflix you can run them even on a Chromebook with limited storage (if it can run the emulators). The trade-off is that you need a fast internet connection, and loading larger games may be slow.

## Dependencies

| Tool | Purpose | Required |
|------|---------|----------|
| [rclone](https://rclone.org/downloads/) (v1.60+) | On-demand ROM download from Internet Archive | Yes |
| [mount-zip](https://github.com/niclas-ahden/mount-zip) | Mounting zipped ISO files (PSP, PS2, PC Engine CD, etc.) | For CD-based systems |
| curl / wget | Bootstrap fetch and asset downloads | Yes |
| unzip / zip | Archive extraction at launch | Yes |
| [RetroArch](https://www.retroarch.com/) | Main emulation frontend | Yes |
| [MAME](https://www.mamedev.org/) | Arcade and computer emulation | For arcade/computer systems |

## Quick start

On **Linux**, register the `play://` URL scheme handler in one step:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/WizzardSK/gameflix/main/webflix.sh)
```

On **Windows**, see [Windows setup](#windows) for the PowerShell installer.

Open <https://wizzardsk.github.io/> in your browser and click a game thumbnail to launch it. ROMs download per-game on click; no local install of the web interface is needed.

## How it works

`webflix.sh` registers the `play://` URL scheme handler with the OS. Clicking a thumbnail on <https://wizzardsk.github.io/> then triggers:

1. Browser hands `play://<platform>/<source>/<rom>` to the OS
2. OS launches `~/retroarch.sh` (3-line bootstrap)
3. Bootstrap fetches the full launcher from <https://wizzardsk.github.io/retroarch.sh>
4. Launcher downloads the ROM into `~/share/roms/` via rclone (Internet Archive S3 session is required for restricted items like NoIntro / MAME-SL / TOSEC)
5. ROM launches via the matching RetroArch core or standalone emulator

### Windows

Windows uses [retroarch.ps1](retroarch.ps1) (launcher) and [webflix.ps1](webflix.ps1) (installer) — PowerShell counterparts of the Bash pair. Setup is per-user and needs **no administrator rights**.

#### 1. Install an emulator

- [RetroArch](https://www.retroarch.com/) — required. After installing, open **Online Updater → Core Downloader** and grab the cores for the systems you want to play (e.g. `Nestopia` for NES, `Snes9x` for SNES). The launcher finds `retroarch.exe` automatically if it's on your `PATH` or in a common location (portable `C:\RetroArch-Win64`, Program Files, Steam, `%LOCALAPPDATA%\Programs\RetroArch`).
- [MAME](https://www.mamedev.org/) — only for arcade/computer systems. Put `mame.exe` on your `PATH`.

#### 2. Register the `play://` handler

Open **PowerShell** (Start → type "PowerShell" → Enter) and run:

```powershell
irm https://raw.githubusercontent.com/WizzardSK/gameflix/main/webflix.ps1 | iex
```

Prefer a double-click? Download [mount.bat](mount.bat) and run it — same result, no terminal.

This writes `rclone.conf` to `%APPDATA%\rclone\`, installs a small bootstrap, and registers `play://` under `HKCU`. (No execution-policy change is needed — the one-liner runs the script as text.)

#### 3. Play

Open <https://wizzardsk.github.io/> and click a game. The ROM downloads into `%USERPROFILE%\share\roms\` and launches in the matching core. Single-file ROMs (NES, SNES, GB, …) load straight from the `.zip` — nothing extra needed.

#### 4. CD images (PSP, PS2, Dreamcast, …)

Multi-file disc images (`.cue`/`.bin`, `.gdi`) need the whole archive visible. The launcher tries, in order:

1. [Pismo File Mount](https://pismotec.com/pfm/) (`pfm.exe`) — **recommended**: tiny, free, no Python; mounts zip/iso in place as a folder, no extraction
2. [7-Zip](https://www.7-zip.org/) (`7z.exe`) — extracts the whole archive to `%TEMP%\gameflix-iso\` (cached for reuse); uses disk space
3. [ratarmount](https://github.com/mxmlnkn/ratarmount) + [WinFsp](https://winfsp.dev/) — optional, mainly a Linux tool; kept for parity

Install **one** of these only if you play CD-based systems. For cartridge consoles you can skip this step.

#### Troubleshooting

The launcher runs in a hidden window, so on failure it shows a **pop-up dialog** with the cause and writes a full transcript to `%LOCALAPPDATA%\gameflix\launch.log`. Common fixes:

- *"retroarch.exe not found"* → add it to `PATH`, or set `GAMEFLIX_RETROARCH` to its full path
- *"Core '…' not found"* → install that core via RetroArch's Online Updater, or set `GAMEFLIX_CORES` to your cores folder
- Other paths/executables are overridable via environment variables read at the top of `retroarch.ps1`: `GAMEFLIX_ROMS`, `GAMEFLIX_BIOS`, `GAMEFLIX_CORES`, `GAMEFLIX_RETROARCH`, `GAMEFLIX_MAME`, `GAMEFLIX_MOUNT`

The launcher reads its platform→core mapping from `launch.tsv` (generated by `generate.sh` from `platforms.csv`, served alongside the web interface).

### Rclone configuration

`webflix.sh` writes [rclone.conf](rclone.conf) to `~/.config/rclone/` with preconfigured remotes. If your rclone is older than v1.60, update from <https://rclone.org/downloads/>.

### Generating the web interface

[generate.sh](generate.sh) is the developer script that builds the interface served at <https://wizzardsk.github.io/>. It:

- Reads platform definitions from [platforms.csv](platforms.csv) and system names from [systems.csv](systems.csv)
- Generates HTML pages for each platform with game thumbnails
- Builds the full `retroarch.sh` launcher with correct core mappings for each system
- Generates `gamelist.xml` files for EmulationStation compatibility
- Filters out unwanted ROM versions (BIOS, prototypes, demos, betas, alternate versions) by default

Generation takes around 30 minutes on slower machines (e.g. ARM Chromebook). End users don't run this — the pre-built version is hosted on GitHub Pages and the bootstrap fetches it on every launch.

## Web interface features

- **Search** — text filter with instant results
- **Thumbnail types** — switch between Snaps, Titles, Boxarts, and Logos
- **Thumbnail sizes** — 80px / 120px / 160px / 240px / 320px
- **ROM filtering** — hide/show Prototypes, Betas, Demos, Alternate versions, Pirated, Aftermarket, and more
- **Platform backgrounds** — each system page has a themed background
- **Lazy loading** — thumbnails load on demand with fade-in effect

## Fantasy consoles

Gameflix includes special support for fantasy console platforms. These games are played directly in the browser via their official web players:

| Platform | Source | Player |
|----------|--------|--------|
| [TIC-80](https://tic80.com) | TIC-80 API | tic80.com/play |
| [PICO-8](https://www.lexaloffle.com/pico-8.php) | Lexaloffle BBS | lexaloffle.com |
| [Voxatron](https://www.lexaloffle.com/voxatron.php) | Lexaloffle BBS | lexaloffle.com |
| [WASM-4](https://wasm4.org) | wasm4.org | wasm4.org/play |
| [LowresNX](https://lowresnx.inutilis.com) | LowresNX community | lowresnx.inutilis.com |

Game data for fantasy consoles is scraped by scripts in the [fantasy/](fantasy/) directory and updated via GitHub Actions.

## Batocera Linux

For [Batocera](https://batocera.org/), copy [custom.sh](batocera/share/system/custom.sh) to your system folder (`/userdata/system/`) in the shared drive. It runs automatically at boot and:

1. Waits for network connectivity
2. Downloads and installs required tools (httpdirfs, fuse-zip, mount-zip, ratarmount)
3. Mounts the Myrient ROM library and bind-mounts platform folders to `/userdata/roms/`
4. Downloads pre-built gamelists and fantasy console archives
5. Updates EmulationStation configuration and reloads it

Thumbnails are downloaded on-demand when a game is selected in EmulationStation (handled by [game.sh](batocera/game.sh)).

AMD64 version also supports zipped libraries for fantasy platforms.

## Recalbox (unmaintained)

For Recalbox, copy [custom.sh](recalbox/share/system/custom.sh) to your system folder in the shared drive. It runs automatically at boot. Supports armv7l, aarch64, x86_64, and i386 architectures.

Recalbox version is no longer maintained as I no longer use it.

## Project structure

```
gameflix/
├── generate.sh          # Main web interface generator (developer-only)
├── webflix.sh            # Installs play:// scheme handler bootstrap
├── mount.sh             # Remote one-liner wrapper for webflix.sh
├── gamelist.sh           # GitHub Actions CI/CD script
├── retroarch.sh          # ROM launcher prefix (start of assembled script)
├── retroarch.end         # ROM launcher execution logic (end of assembled script)
├── retroarch.ps1         # Windows ROM launcher (reads launch.tsv)
├── webflix.ps1           # Windows play:// handler installer
├── mount.bat             # Double-click Windows installer (wraps webflix.ps1)
├── launch.tsv            # Generated platform→core/ext/src table (Windows launcher)
├── platforms.csv         # Master database of ROM collections (760+ entries)
├── systems.csv           # System short names → display names (145 entries)
├── rclone.conf           # Rclone remote configuration
├── platform.js           # Platform page generator (JS)
├── script.js             # Filtering and UI logic
├── script2.js            # Lazy loading for thumbnails
├── style.css             # Dark theme styling
├── fantasy/              # Fantasy console scrapers and data
│   ├── fantasy.sh        # Master update script
│   ├── tic80.sh          # TIC-80 scraper
│   ├── pico8.sh          # PICO-8 scraper
│   ├── voxatron.sh       # Voxatron scraper
│   ├── wasm4.sh          # WASM-4 scraper
│   └── lowresnx.sh       # LowresNX scraper
├── batocera/             # Batocera-specific files
│   ├── custom.sh         # Boot script
│   ├── game.sh           # On-demand thumbnail downloader
│   ├── messSystems.csv   # MAME MESS system configs
│   └── ...               # Pre-compiled binaries and ES configs
└── recalbox/             # Recalbox-specific files (unmaintained)
    ├── custom.sh         # Boot script
    └── ...               # Binaries and configs
```

## Resources

- ARM64 libretro cores: https://github.com/christianhaitian/retroarch-cores
- BIOS files: https://github.com/PIBSAS
- Rclone: https://rclone.org/downloads/
