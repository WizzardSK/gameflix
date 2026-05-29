#!/bin/bash
set -u

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

echo "Done. Open https://wizzardsk.github.io/ in your browser; ROMs download per-game on launch."
