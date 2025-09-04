#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
ZIP_NAME="${2:-indexes.zip}"
OWNER_REPO="${GITHUB_REPOSITORY:-WizzardSK/Atari_-_2600}"
BRANCH="${GITHUB_REF_NAME:-master}"
BASE_URL="https://raw.githubusercontent.com/$OWNER_REPO/refs/heads/$BRANCH"

echo "Generujem indexy pre repozitár: $OWNER_REPO ($BRANCH)"
echo "Výsledný ZIP: $ZIP_NAME"

# --- HTML escape ---
html_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&#39;}"
  printf '%s' "$s"
}

# --- URL-safe odkazy ---
url_safe() {
  local s="$1"
  s="${s// /%20}"
  s="${s//#/%23}"
  s="${s//\?/%3F}"
  s="${s//:/%3A}"
  printf '%s' "$s"
}

# --- Generovanie indexu pre adresár ---
generate_index() {
  local dir="$1"
  local rel="${dir#$ROOT}"
  [[ -z "$rel" ]] && rel=""

  {
    echo '<!doctype html>'
    echo '<meta charset="utf-8">'
    echo "<title>Index of $(html_escape "$rel")</title>"
    echo "<h1>Index of $(html_escape "$rel")</h1>"
    echo '<ul>'

    [[ "$dir" != "$ROOT" ]] && echo '<li><a href="../index.html">../</a></li>'

    for entry in "$dir"/*; do
      [[ -e "$entry" ]] || continue
      name=$(basename "$entry")

      # vynechať skryté súbory a index.html
      [[ "$name" == .* ]] && continue
      [[ "$name" == "index.html" ]] && continue

      if [[ -d "$entry" ]]; then
        # priečinok → odkaz na jeho index
        echo '<li>📁 <a href="'"$(url_safe "$name")/index.html"'">'"$(html_escape "$name")"'/</a></li>'
        # rekurzia len pre priečinky, ktoré nezačínajú bodkou
        generate_index "$entry"
      elif [[ -f "$entry" ]]; then
        # súbory v koreňovom adresári vynechať
        [[ "$dir" == "$ROOT" ]] && continue
        fullpath=$(realpath --relative-to="$ROOT" "$entry")
        href="$BASE_URL/$(url_safe "$fullpath")"
        echo '<li>📄 <a href="'"$href"'">'"$(html_escape "$name")"'</a></li>'
      fi
    done

    echo '</ul>'
  } > "$dir/index.html"
}

# --- Spusti generovanie od ROOT ---
generate_index "$ROOT"

# --- ZIP so štruktúrou ---
echo "Vytváram ZIP: $ZIP_NAME"
(cd "$ROOT" && zip -r "$ZIP_NAME" $(find . -name "index.html"))

# --- Vymazať všetky index.html ---
find "$ROOT" -name "index.html" -delete

echo "✅ Hotovo! ZIP uložený v: $ROOT/$ZIP_NAME"



rm index.sh
git add .
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
