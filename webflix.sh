#!/bin/bash
# gameflix runtime setup — tears down the legacy bulk-romset mount tree and
# installs the on-demand web interface. Games are now fetched per-game from
# archive.org at launch time (see retroarch.sh), so no rclone/ratarmount
# mounts and no cached zips are needed.
set -u

echo "=== Unmounting legacy FUSE mounts ==="
# Aggregate ratarmount over the symlink tree
if [[ -d ~/share/roms-mount ]] && mountpoint -q ~/share/roms-mount 2>/dev/null; then
  fusermount -u -z ~/share/roms-mount && echo "Unmounted ~/share/roms-mount"
fi
# Per-IA-item rclone mounts
if [[ -d ~/mount ]]; then
  for d in ~/mount/*/; do
    [[ -d "$d" ]] || continue
    if mountpoint -q "$d" 2>/dev/null; then
      fusermount -u -z "$d" && echo "Unmounted $d"
    fi
  done
fi
# Any stale mount-zip / ratarmount left on the inner-game iso slot
mountpoint -q ~/iso 2>/dev/null && fusermount -u -z ~/iso

echo "=== Deleting cached romset zips ==="
rm -rf ~/share/zip ~/share/zips ~/share/roms-mount
rmdir ~/mount/*/ 2>/dev/null
rmdir ~/mount 2>/dev/null

echo "=== Installing web interface ==="
mkdir -p ~/gameflix ~/share/roms ~/.config/rclone
# rclone.conf still required at runtime: restricted IA items (NoIntro / MAME-SL
# / TOSEC) refuse plain HTTPS (401/403); retroarch.sh's on-demand fetcher routes
# every download through rclone so the IA S3 session credentials get used.
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
wget -nv -O /tmp/gameflix.zip https://github.com/WizzardSK/gameflix/raw/refs/heads/main/gameflix.zip
unzip -o -q /tmp/gameflix.zip -d ~/gameflix/
rm -f /tmp/gameflix.zip
# Replace the bundled full retroarch.sh with a thin bootstrap that fetches the
# latest version from wizzardsk.github.io on every launch — URL/core mapping
# updates deploy without re-running webflix.sh.
cat > ~/gameflix/retroarch.sh <<'EOF'
#!/bin/bash
set -e
exec bash -c "$(curl -fsSL https://wizzardsk.github.io/retroarch.sh)" _ "$@"
EOF
chmod +x ~/gameflix/retroarch.sh
echo "Done. Open ~/gameflix/index.html in your browser; ROMs download per-game on launch."
