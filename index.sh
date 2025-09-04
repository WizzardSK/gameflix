#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-.}"   # cieľový adresár
OUT="$DIR/index.html"

html_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&#39;}"
  printf '%s' "$s"
}

url_safe() {
  local s="$1"
  s="${s//%/%25}"
  s="${s// /%20}"
  s="${s//#/%23}"
  s="${s//?/%3F}"
  s="${s//&/%26}"
  printf '%s' "$s"
}

{
  echo '<!doctype html>'
  echo '<meta charset="utf-8">'
  echo '<title>Index of '"$(html_escape "$DIR")"'</title>'
  echo '<h1>Index of '"$(html_escape "$DIR")"'</h1>'
  echo '<ul>'

  [[ "$DIR" != "." ]] && echo '<li><a href="../">../</a></li>'

  for entry in "$DIR"/*; do
    name=$(basename "$entry")
    href=$(url_safe "$name")
    if [[ -d "$entry" ]]; then
      echo '<li>📁 <a href="'"$href"'/">'"$(html_escape "$name")"'/</a></li>'
    elif [[ -f "$entry" ]]; then
      echo '<li>📄 <a href="'"$href"'">'"$(html_escape "$name")"'</a></li>'
    fi
  done

  echo '</ul>'
} > "$OUT"

echo "Hotovo. Vygenerovaný index: $OUT"

rm index.sh
git add .
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
