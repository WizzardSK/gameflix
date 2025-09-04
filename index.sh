#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"   # koreňový adresár, ak nezadáš, použije sa aktuálny
echo "Generujem indexy pre všetky adresáre v: $ROOT"

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

# --- URL-safe pre odkazy ---
url_safe() {
  local s="$1"
  s="${s//%/%25}"
  s="${s// /%20}"
  s="${s//#/%23}"
  s="${s//?/%3F}"
  s="${s//&/%26}"
  printf '%s' "$s"
}

# --- Funkcia generuje index.html pre jeden adresár ---
generate_index() {
  local dir="$1"
  local rel="${dir#$ROOT}"
  [[ -z "$rel" ]] && rel="/"

  {
    echo '<!doctype html>'
    echo '<meta charset="utf-8">'
    echo '<title>Index of '"$(html_escape "$rel")"'</title>'
    echo "<h1>Index of $(html_escape "$rel")</h1>"
    echo '<ul>'

    # Odkaz na nadradený adresár (ak nie sme v root)
    [[ "$dir" != "$ROOT" ]] && echo '<li><a href="../">../</a></li>'

    # Pre každý súbor a priečinok
    for entry in "$dir"/*; do
      [[ -e "$entry" ]] || continue
      name=$(basename "$entry")
      href=$(url_safe "$name")
      if [[ -d "$entry" ]]; then
        echo '<li>📁 <a href="'"$href"'/">'"$(html_escape "$name")"'/</a></li>'
      elif [[ -f "$entry" ]]; then
        echo '<li>📄 <a href="'"$href"'">'"$(html_escape "$name")"'</a></li>'
      fi
    done

    echo '</ul>'
  } > "$dir/index.html"
}

# --- Pre každý adresár vrátane ROOT ---
while IFS= read -r -d '' d; do
  generate_index "$d"
done < <(find "$ROOT" -type d -print0)

echo "Hotovo. Vygenerované index.html vo všetkých adresároch."

rm index.sh
git add .
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
