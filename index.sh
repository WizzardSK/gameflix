#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"          # koreňový adresár
ZIP_NAME="${2:-indexes.zip}"

# Repo a branch z GitHub Actions (alebo fallback)
OWNER_REPO="${GITHUB_REPOSITORY:-}"
BRANCH="${GITHUB_REF_NAME:-master}"
BASE_URL="https://raw.githubusercontent.com/$OWNER_REPO/refs/heads/$BRANCH"

echo "Generujem indexy pre repozitár: $OWNER_REPO ($BRANCH)"
echo "BASE_URL = $BASE_URL"
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
    echo '<title>Index of '"$(html_escape "$rel")"'</title>'
    echo "<h1>Index of $(html_escape "$rel")</h1>"
    echo '<ul>'

    # odkaz na nadriadený priečinok
    [[ "$dir" != "$ROOT" ]] && echo '<li><a href="../index.html">../</a></li>'

    for entry in "$dir"/*; do
      [[ -e "$entry" ]] || continue
      name=$(basename "$entry")
      [[ "$name" == .* ]] && continue
      [[ "$dir/$name" == "$ROOT/.github/workflows" ]] && continue

      if [[ -d "$entry" ]]; then
        # priečinok → relatívny odkaz na jeho index.html
        echo '<li>📁 <a href="'"$(url_safe "$name")/index.html"'">'"$(html_escape "$name")"'/</a></li>'
      elif [[ -f "$entry" ]]; then
        # v koreňovom adresári súbory vynechať
        if [[ "$dir" == "$ROOT" ]]; then
          continue
        fi
        # súbor → raw.githubusercontent link
        fullpath=$(realpath --relative-to="$ROOT" "$entry")
        href="$BASE_URL/$(url_safe "$fullpath")"
        echo '<li>📄 <a href="'"$href"'">'"$(html_escape "$name")"'</a></li>'
      fi
    done

    echo '</ul>'
  } > "$dir/index.html"
}

# --- Generovanie indexov ---
while IFS= read -r -d '' d; do
  dir_name=$(basename "$d")
  [[ "$dir_name" == .* && "$d" != "$ROOT" ]] && continue
  [[ "$d" == "$ROOT/.github/workflows" ]] && continue
  generate_index "$d"
done < <(find "$ROOT" -type d -print0)

# --- ZIP so štruktúrou ---
echo "Vytváram ZIP: $ZIP_NAME"
(cd "$ROOT" && zip -r "$ZIP_NAME" $(find . -name "index.html"))

# --- Vymazať všetky index.html ---
find "$ROOT" -name "index.html" -delete

echo "✅ Hotovo! ZIP uložený v: $ROOT/$ZIP_NAME, indexy zmazané."

rm index.sh
git add .
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
