#!/bin/bash
set -u
mountpoint -q ~/iso 2>/dev/null && fusermount -u -z ~/iso

echo "=== Removing legacy local files ==="
rm -rf ~/share/zip ~/share/zips ~/share/roms-mount ~/gameflix
rmdir ~/mount/*/ 2>/dev/null
rmdir ~/mount 2>/dev/null

echo "=== Installing play:// handler ==="
mkdir -p ~/share/roms ~/.config/rclone
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

cat > ~/retroarch.sh <<'EOF'
#!/bin/bash
set -e
exec bash <(curl -fsSL https://wizzardsk.github.io/retroarch.sh) "$@"
EOF
chmod +x ~/retroarch.sh

mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/retroarch.sh.desktop <<EOF
[Desktop Entry]
Type=Application
Name=retroarch.sh
Comment=gameflix launcher
Exec=$HOME/retroarch.sh %u
NoDisplay=true
MimeType=x-scheme-handler/play;
EOF
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
xdg-mime default retroarch.sh.desktop x-scheme-handler/play
