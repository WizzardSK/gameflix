/* gameflix — Android: launch catalog games in the native RetroArch app.
 *
 * On Android there is no play:// OS handler, so instead we hand the game to the
 * installed RetroArch via an intent:// deep link (a Chrome-for-Android feature,
 * no companion app needed). RetroArch can't download ROMs itself, so the flow is:
 *
 *     tap game  →  download ROM to /storage/emulated/0/Download
 *               →  intent:// opens RetroArch with that file + the matching core
 *
 * The platform→core/src/ext mapping is cores.json, generated 1:1 from the desktop
 * launcher (gen_cores.py < retroarch.sh). Desktop browsers are untouched.
 *
 * The pure helpers are also exported for Node so the URL/intent building can be
 * unit-tested without a device (see test_intent.js).
 */
(function () {
    "use strict";

    // Target RetroArch app. "com.retroarch" = stable RetroArch;
    // "com.retroarch.aarch64" = RetroArch Plus (64-bit). Core dir + component follow it.
    var RETRO_PKG = "com.retroarch";
    var RETRO_ACT = "com.retroarch.browser.retroactivity.RetroActivityFuture";
    var CORE_DIR  = "/data/data/" + RETRO_PKG + "/cores";
    var DL_DIR    = "/storage/emulated/0/Download";   // Chrome's default download dir

    // Mirror of the bash urlenc(): keep /A-Za-z0-9._~-, percent-encode the rest (UTF-8).
    function urlenc(s) {
        return s.replace(/[^/A-Za-z0-9._~-]/g, function (c) {
            return Array.prototype.map.call(new TextEncoder().encode(c), function (b) {
                return "%" + b.toString(16).toUpperCase().padStart(2, "0");
            }).join("");
        });
    }

    // First entry whose pattern is a substring of the dir — same as the bash `case`.
    function lookup(cores, dir) {
        for (var i = 0; i < cores.length; i++) {
            if (dir.indexOf(cores[i].pattern) !== -1) return cores[i];
        }
        return null;
    }

    // Android Intent.parseUri runs Uri.decode on extra values, so encodeURIComponent
    // round-trips safely. package/component are structural and stay literal.
    function buildIntent(romPath, corePath, fallback) {
        var e = encodeURIComponent;
        return "intent://gameflix/launch#Intent;" +
            "action=android.intent.action.MAIN;" +
            "package=" + RETRO_PKG + ";" +
            "component=" + RETRO_PKG + "/" + RETRO_ACT + ";" +
            "S.ROM=" + e(romPath) + ";" +
            "S.LIBRETRO=" + e(corePath) + ";" +
            (fallback ? "S.browser_fallback_url=" + e(fallback) + ";" : "") +
            "end";
    }

    // play://-href → everything needed to download + launch, or { error }.
    function resolve(cores, href, fallback) {
        var path = decodeURIComponent(href.replace(/^play:\/\//, ""));   // /plat/folder/file
        var dir  = path.replace(/\/[^/]*$/, "/");
        var ent  = lookup(cores, dir);
        if (!ent) return { error: "Žiadne mapovanie core pre " + dir };

        var core = ent.core || "";
        if (core.indexOf(" ") !== -1 || core.slice(-9) !== "_libretro") {
            return { error: "Cez intent:// zatiaľ nepodporované:\n" + core +
                            "\n(MAME / standalone potrebujú cmd-file)" };
        }
        if (!ent.src) return { error: "Žiadny zdroj na stiahnutie pre " + dir };

        var segs     = path.split("/").filter(Boolean);
        var inner    = segs.slice(2).join("/");
        var fname    = inner.split("/").pop();
        var corePath = CORE_DIR + "/" + core + "_android.so";
        var romPath  = DL_DIR + "/" + fname;
        return {
            fname:    fname,
            romUrl:   ent.src + urlenc(inner),          // direct download (no CORS for navigations)
            romPath:  romPath,
            corePath: corePath,
            intent:   buildIntent(romPath, corePath, fallback)
        };
    }

    var api = { urlenc: urlenc, lookup: lookup, buildIntent: buildIntent, resolve: resolve,
                RETRO_PKG: RETRO_PKG, CORE_DIR: CORE_DIR, DL_DIR: DL_DIR };

    // ---- Node (unit tests) ------------------------------------------------
    if (typeof module !== "undefined" && module.exports) { module.exports = api; return; }

    // ---- Browser, Android only --------------------------------------------
    if (typeof navigator === "undefined" || !/Android/i.test(navigator.userAgent)) return;

    var coresPromise = fetch("cores.json").then(function (r) { return r.json(); });

    function startDownload(url, fname) {
        var a = document.createElement("a");
        a.href = url; a.download = fname; a.rel = "noreferrer";
        document.body.appendChild(a); a.click(); a.remove();
    }

    document.addEventListener("click", function (ev) {
        var a = ev.target.closest && ev.target.closest('a[href^="play:"]');
        if (!a) return;
        ev.preventDefault();
        coresPromise.then(function (cores) {
            var r = resolve(cores, a.getAttribute("href"), location.href);
            if (r.error) { alert(r.error); return; }
            startDownload(r.romUrl, r.fname);          // 1) get the ROM onto the device
            if (confirm("Sťahujem „" + r.fname + "“ do Downloads.\n\n" +
                        "Po dokončení sťahovania daj OK = spustiť v RetroArch.")) {
                window.location.href = r.intent;        // 2) hand it to native RetroArch
            }
        });
    }, true);
})();
