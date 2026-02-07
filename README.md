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
| [rclone](https://rclone.org/downloads/) (v1.60+) | Mounting remote ROM libraries | Yes |
| [mount-zip](https://github.com/niclas-ahden/mount-zip) | Mounting zipped ISO files (PSP, PS2, PC Engine CD, etc.) | Yes |
| [ratarmount](https://github.com/mxmlnkn/ratarmount) | Mounting fantasy console archives | For fantasy consoles |
| [bindfs](https://bindfs.org/) | Permission mapping for mounted archives | For fantasy consoles |
| curl / wget | Downloading scripts and assets | Yes |
| unzip / zip | Archive management | Yes |
| [RetroArch](https://www.retroarch.com/) | Main emulation frontend | Yes |
| [MAME](https://www.mamedev.org/) | Arcade and computer emulation | For arcade/computer systems |

## Quick start

Mount the library and download the web interface in one step:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/WizzardSK/gameflix/main/webflix.sh)
```

Then run [upd.sh](upd.sh) to download the pre-generated web interface:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/WizzardSK/gameflix/main/upd.sh)
```

Open `~/gameflix/index.html` in your browser (Firefox recommended) and click a game thumbnail to launch it.

## Web version

### Rclone setup

The [rclone.conf](rclone.conf) file must be placed in `~/.config/rclone/`. It contains preconfigured remotes for Myrient, Internet Archive, and other sources.

If your rclone version is not up to date, grab it from https://rclone.org/downloads/

### Mounting the library

Run [webflix.sh](webflix.sh) to mount the remote library:

```bash
bash webflix.sh
```

This mounts the Myrient ROM library to `~/myrient` via rclone with aggressive caching. It also downloads and mounts fantasy console archives (LowresNX, WASM-4) using ratarmount and bindfs.

Alternatively, [mount.sh](mount.sh) downloads and executes `webflix.sh` remotely.

### Generating the web interface

[generate.sh](generate.sh) is the main script that builds the entire web interface. It:

- Reads platform definitions from [platforms.csv](platforms.csv) and system names from [systems.csv](systems.csv)
- Generates HTML pages for each platform with game thumbnails
- Creates `retroarch.sh` launcher script with correct core mappings for each system
- Generates `gamelist.xml` files for EmulationStation compatibility
- Filters out unwanted ROM versions (BIOS, prototypes, demos, betas, alternate versions) by default
- Creates the output in `~/gameflix/`

Generation takes around 30 minutes on slower machines (e.g. ARM Chromebook). You don't need to run it every time — use [upd.sh](upd.sh) to download the pre-built version instead.

### Launching games

Games are launched by clicking thumbnails in the web interface. ROM files need to be associated with the `retroarch.sh` script (generated into `~/`), which automatically selects the correct RetroArch core or standalone emulator based on the ROM's directory.

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
├── generate.sh          # Main web interface generator
├── webflix.sh            # Mounts remote ROM library
├── mount.sh             # Remote wrapper for webflix.sh
├── upd.sh               # Remote wrapper for update.sh
├── update.sh            # Downloads pre-built web interface
├── gamelist.sh           # GitHub Actions CI/CD script
├── retroarch.sh          # ROM launcher (start, completed by generate.sh)
├── retroarch.end         # ROM launcher (execution logic)
├── platforms.csv         # Master database of ROM collections (760+ entries)
├── systems.csv           # System short names → display names (145 entries)
├── fbneo.dat             # FinalBurn Neo ROM name database
├── mame.dat              # MAME ROM name database
├── neogeo.dat            # Neo Geo ROM name database
├── switch.txt            # Nintendo Switch game name database
├── rclone.conf           # Rclone remote configuration
├── platform.html         # Template for platform pages
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
