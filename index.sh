generate_index() {
    local dir="$1"

    # Preskočiť .git a .github/workflows úplne
    if [[ "$dir" == "$ROOT/.git"* ]]; then
        return
    fi

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
            [[ "$name" == "index.html" ]] && continue

            if [[ -d "$entry" ]]; then
                echo '<li>📁 <a href="'"$(url_safe "$name")/index.html"'">'"$(html_escape "$name")"'/</a></li>'
                generate_index "$entry"
            elif [[ -f "$entry" ]]; then
                [[ "$dir" == "$ROOT" ]] && continue
                fullpath=$(realpath --relative-to="$ROOT" "$entry")
                href="$BASE_URL/$(url_safe "$fullpath")"
                echo '<li>📄 <a href="'"$href"'">'"$(html_escape "$name")"'</a></li>'
            fi
        done

        echo '</ul>'
    } > "$dir/index.html"
}



rm index.sh
git add .
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
