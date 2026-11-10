/* gameflix — "nothing started?": install instructions for the play:// launcher.
 *
 * A click on a game hands play:///<platform>/<list>/<rom> to the operating
 * system, which starts the launcher that webflix.sh / webflix.ps1 registered.
 * Without it the browser does nothing at all (Chrome) or shows its own "no
 * application" message, and there is no API that says which. So: when the
 * page keeps the focus and stays visible for a while after the click - the
 * launcher's RetroArch window, or the browser's "open this app?" prompt,
 * takes it when there is one - the launcher is most likely missing, and this
 * shows how to install it. After one launch that did take the focus it stays
 * quiet for good (localStorage), and its "installed" button does the same for
 * browsers that ask before they open the app.
 *
 * Desktop only: Android launches through intent.js.
 */
(function () {
    "use strict";
    if (typeof navigator === "undefined" || /Android/i.test(navigator.userAgent)) return;

    var KEY = "gfLauncherOk";
    var WAIT_MS = 2500;
    var REPO = "https://raw.githubusercontent.com/WizzardSK/gameflix/main/";
    var LINUX_CMD = "bash <(curl -Ls " + REPO + "webflix.sh)";
    var WINDOWS_CMD = "irm " + REPO + "webflix.ps1 | iex";

    function known() {
        try { return localStorage.getItem(KEY) === "1"; } catch (e) { return false; }
    }
    function remember() {
        try { localStorage.setItem(KEY, "1"); } catch (e) { /* private mode: asks again */ }
    }

    function esc(s) {
        return s.replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; });
    }

    function command(label, cmd, note) {
        return '<div class="gfh-os"><b>' + label + '</b>' + (note ? '<div class="gfh-note">' + note + '</div>' : '') +
            '<div class="gfh-cmd"><code>' + esc(cmd) + '</code><button type="button" data-copy="' + esc(cmd) + '">Copy</button></div></div>';
    }

    function show() {
        if (document.getElementById("gfHelp")) return;
        var linux = command("Linux", LINUX_CMD,
            'Needs <a href="https://www.retroarch.com/" target="_blank" rel="noreferrer">RetroArch</a>, ' +
            '<a href="https://rclone.org/downloads/" target="_blank" rel="noreferrer">rclone</a>, curl and unzip. Run in a terminal:');
        var windows = command("Windows", WINDOWS_CMD,
            'Install <a href="https://www.retroarch.com/" target="_blank" rel="noreferrer">RetroArch</a> first, then run in PowerShell ' +
            '(or download and run <a href="' + REPO + 'mount.bat" target="_blank" rel="noreferrer">mount.bat</a>):');
        var isWindows = /Win/i.test(navigator.platform || navigator.userAgent);
        var box = document.createElement("div");
        box.id = "gfHelp";
        box.innerHTML =
            '<div class="gfh-box" role="dialog" aria-labelledby="gfhTitle">' +
            '<h3 id="gfhTitle">Nothing started?</h3>' +
            '<p>Games start through the gameflix launcher, which opens <code>play://</code> links in RetroArch. ' +
            'It does not seem to be installed on this computer. Install it once, then click the game again:</p>' +
            (isWindows ? windows + linux : linux + windows) +
            '<p class="gfh-note">More in the <a href="https://github.com/WizzardSK/gameflix#quick-start" target="_blank" rel="noreferrer">README</a>. ' +
            'On Android, tapping a game downloads it and opens it in the RetroArch app.</p>' +
            '<div class="gfh-buttons"><button type="button" data-act="ok">It\'s installed, don\'t show again</button>' +
            '<button type="button" data-act="close">Close</button></div></div>';
        box.addEventListener("click", function (ev) {
            var b = ev.target.closest("button");
            if (ev.target === box || (b && b.dataset.act === "close")) { box.remove(); return; }
            if (!b) return;
            if (b.dataset.act === "ok") { remember(); box.remove(); return; }
            if (b.dataset.copy && navigator.clipboard) {
                navigator.clipboard.writeText(b.dataset.copy).then(function () {
                    b.textContent = "Copied";
                    setTimeout(function () { b.textContent = "Copy"; }, 1500);
                });
            }
        });
        document.addEventListener("keydown", function esc(ev) {
            if (ev.key === "Escape") { box.remove(); document.removeEventListener("keydown", esc); }
        });
        document.body.appendChild(box);
    }

    document.addEventListener("click", function (ev) {
        var a = ev.target.closest && ev.target.closest('a[href^="play:"]');
        if (!a || known()) return;
        var left = false;
        function gone() { left = true; }
        function hidden() { if (document.hidden) left = true; }
        window.addEventListener("blur", gone);
        window.addEventListener("pagehide", gone);
        document.addEventListener("visibilitychange", hidden);
        setTimeout(function () {
            window.removeEventListener("blur", gone);
            window.removeEventListener("pagehide", gone);
            document.removeEventListener("visibilitychange", hidden);
            if (left || !document.hasFocus()) remember();
            else show();
        }, WAIT_MS);
    });
})();
